// The single screen of v1.
// Layout:
//   AppBar (symbol + reset)
//   Demo balance bar
//   FII/DII flow strip
//   Candle chart (with overlays)
//   Open positions section (only shown if positions exist)
//   Opportunities list (scrollable)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/candle%20chart/candle_chart.dart';
import 'package:tradexa/data/mock_data.dart';
import 'package:tradexa/detector/detector.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/oppertunity%20card/oppertunity_card.dart';
import 'package:tradexa/portfolio/portfolio.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late final List<Candle> _candles;
  late final List<FlowData> _flow;
  late final List<Opportunity> _opportunities;
  int? _selectedIdx;

  /// Risk budget per trade. Caps qty by the 1% rule: never lose more than this
  /// if the stop is hit. 1% of starting balance = ₹5,000.
  double get _riskBudget => Portfolio.startingBalance * 0.01;

  /// Max capital deployable per trade. Caps qty so a single high-priced stock
  /// (like RELIANCE at ₹2900) can't consume the whole demo balance. 25% of
  /// starting balance = ₹1,25,000 → allows up to 4 concurrent positions.
  double get _maxCapitalPerTrade => Portfolio.startingBalance * 0.25;

  @override
  void initState() {
    super.initState();
    _candles = getCandles(mockSymbol);
    _flow = getFlowHistory();
    _opportunities = Detector().detectAll(_candles)
      // Sort by anchor index descending (most recent setups first)
      ..sort((a, b) => b.anchorIndex.compareTo(a.anchorIndex));
  }

  double get _lastClose => _candles.last.close;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _DemoBalanceBar(currentPrice: _lastClose),
          _FlowStrip(flow: _flow),
          const _ChartHeader(),
          CandleChart(
            candles: _candles,
            opportunities: _opportunities,
            selectedOpportunityIndex: _selectedIdx,
            onOpportunityTap: (idx) {
              setState(() {
                _selectedIdx = (idx == _selectedIdx) ? null : idx;
              });
            },
          ),
          _OpenPositionsPanel(currentPrice: _lastClose),
          Expanded(
            child: _buildOpportunityList(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0E1116),
      elevation: 0,
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: const Color(0xFFFFB300).withOpacity(0.6), width: 0.8),
            ),
            child: const Text(
              'RELIANCE · NSE',
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '₹${_lastClose.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Builder(builder: (context) {
            final prev = _candles[_candles.length - 2].close;
            final delta = _lastClose - prev;
            final pct = (delta / prev) * 100;
            final color =
                delta >= 0 ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
            return Text(
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)} '
              '(${delta >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Reset demo balance',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            context.read<Portfolio>().reset();
            setState(() => _selectedIdx = null);
          },
        ),
      ],
    );
  }

  Widget _buildOpportunityList() {
    if (_opportunities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No institutional setups detected in current window.',
            style: TextStyle(color: Color(0xFF8B95A1)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.auto_graph, size: 16, color: Color(0xFFFFB300)),
              const SizedBox(width: 6),
              const Text(
                'OPPORTUNITIES',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2630),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_opportunities.length} found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Risk ₹${_riskBudget.toStringAsFixed(0)} · Capital ₹${_maxCapitalPerTrade.toStringAsFixed(0)} / trade',
                style: const TextStyle(
                  color: Color(0xFF8B95A1),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: _opportunities.length,
            itemBuilder: (context, idx) {
              final op = _opportunities[idx];
              // Cap per-trade capital by remaining demo cash too
              final p = context.watch<Portfolio>();
              final perTradeCap =
                  p.cash < _maxCapitalPerTrade ? p.cash : _maxCapitalPerTrade;
              return OpportunityCard(
                opp: op,
                isSelected: idx == _selectedIdx,
                riskBudget: _riskBudget,
                maxCapital: perTradeCap,
                onTap: () {
                  setState(() {
                    _selectedIdx = (idx == _selectedIdx) ? null : idx;
                  });
                },
                onTakeTrade: (qty) {
                  final err = context.read<Portfolio>().takeTrade(
                        opp: op,
                        qty: qty,
                        symbol: mockSymbol,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err ??
                        'Trade taken · ${op.direction.label} $qty @ ₹${op.entry.toStringAsFixed(2)}'),
                    backgroundColor: err == null
                        ? const Color(0xFF26A69A)
                        : const Color(0xFFEF5350),
                    duration: const Duration(seconds: 2),
                  ));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Demo balance bar
// -----------------------------------------------------------------------------

class _DemoBalanceBar extends StatelessWidget {
  final double currentPrice;
  const _DemoBalanceBar({required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Consumer<Portfolio>(
      builder: (context, p, _) {
        final equity = p.equity(currentPrice);
        final unrealized = p.unrealizedPnL(currentPrice);
        final returnVsStart =
            ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) *
                100;
        final color = returnVsStart >= 0
            ? const Color(0xFF26A69A)
            : const Color(0xFFEF5350);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2F38), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 16, color: Color(0xFF8B95A1)),
              const SizedBox(width: 6),
              const Text(
                'DEMO',
                style: TextStyle(
                  color: Color(0xFF8B95A1),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Equity',
                      style:
                          TextStyle(color: Color(0xFF8B95A1), fontSize: 9.5)),
                  Text(
                    fmt.format(equity),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cash',
                      style:
                          TextStyle(color: Color(0xFF8B95A1), fontSize: 9.5)),
                  Text(
                    fmt.format(p.cash),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${returnVsStart >= 0 ? '+' : ''}${returnVsStart.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    unrealized.abs() < 0.5
                        ? 'flat'
                        : 'unrealized ${unrealized >= 0 ? '+' : ''}${fmt.format(unrealized)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// FII/DII flow strip
// -----------------------------------------------------------------------------

class _FlowStrip extends StatelessWidget {
  final List<FlowData> flow;
  const _FlowStrip({required this.flow});

  @override
  Widget build(BuildContext context) {
    final last = flow.last;
    final regime = last.regime;
    Color regimeColor;
    switch (regime) {
      case 'risk-on':
        regimeColor = const Color(0xFF26A69A);
        break;
      case 'risk-off':
        regimeColor = const Color(0xFFEF5350);
        break;
      case 'churn':
        regimeColor = const Color(0xFFFFB300);
        break;
      default:
        regimeColor = const Color(0xFF8B95A1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1116),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F38), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: regimeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: regimeColor.withOpacity(0.6)),
            ),
            child: Text(
              regime.toUpperCase(),
              style: TextStyle(
                color: regimeColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'FII ${_fmtCr(last.fiiCash)}',
            style: TextStyle(
              color: last.fiiCash >= 0
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFEF5350),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DII ${_fmtCr(last.diiCash)}',
            style: TextStyle(
              color: last.diiCash >= 0
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFEF5350),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'FII F&O ${_fmtCr(last.fiiFnoIndexNetLong)}',
            style: TextStyle(
              color: last.fiiFnoIndexNetLong >= 0
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFEF5350),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // mini sparkline of fiiCash over last 10 sessions
          SizedBox(
            width: 80,
            height: 20,
            child: CustomPaint(
              painter: _Sparkline(
                  values: flow.map((f) => f.fiiCash).toList(),
                  color: regimeColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCr(double v) {
    final sign = v >= 0 ? '+' : '−';
    return '$sign₹${v.abs().toStringAsFixed(0)}cr';
  }
}

class _Sparkline extends CustomPainter {
  final List<double> values;
  final Color color;
  _Sparkline({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    double lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo == 0 ? 1 : hi - lo;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - (values[i] - lo) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _Sparkline old) => old.values != values;
}

// -----------------------------------------------------------------------------
// Chart header (subtitle row)
// -----------------------------------------------------------------------------

class _ChartHeader extends StatelessWidget {
  const _ChartHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          const Text(
            '15m  ·  Mock',
            style: TextStyle(
              color: Color(0xFF8B95A1),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          _LegendDot(color: const Color(0xFF26A69A), label: 'Bull OB'),
          const SizedBox(width: 8),
          _LegendDot(color: const Color(0xFFEF5350), label: 'Bear OB'),
          const SizedBox(width: 8),
          _LegendDot(
              color: const Color(0xFF66BB6A), label: 'FVG', dashed: true),
          const SizedBox(width: 8),
          _LegendDot(
              color: const Color(0xFFFFB300), label: 'Sweep', dashed: true),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(dashed ? 0.0 : 0.4),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFAFB7C2), fontSize: 10),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Open positions panel
// -----------------------------------------------------------------------------

class _OpenPositionsPanel extends StatelessWidget {
  final double currentPrice;
  const _OpenPositionsPanel({required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    return Consumer<Portfolio>(
      builder: (context, p, _) {
        if (p.openPositions.isEmpty) return const SizedBox.shrink();
        final fmt = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        );
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          decoration: const BoxDecoration(
            color: Color(0xFF11161D),
            border: Border(
              top: BorderSide(color: Color(0xFF2A2F38), width: 0.5),
              bottom: BorderSide(color: Color(0xFF2A2F38), width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Color(0xFF26A69A)),
                    const SizedBox(width: 4),
                    Text(
                      'OPEN POSITIONS (${p.openPositions.length})',
                      style: const TextStyle(
                        color: Color(0xFF26A69A),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              ...p.openPositions.map((pos) {
                final pnl = pos.currentPnL(currentPrice);
                final color = pnl >= 0
                    ? const Color(0xFF26A69A)
                    : const Color(0xFFEF5350);
                final status = pos.status(currentPrice);
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: status == 'targetHit'
                          ? const Color(0xFF66BB6A).withOpacity(0.5)
                          : status == 'stoppedOut'
                              ? const Color(0xFFEF5350).withOpacity(0.5)
                              : const Color(0xFF2A2F38),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: color.withOpacity(0.55)),
                        ),
                        child: Text(
                          pos.direction.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pos.qty} @ ₹${pos.entry.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pos.setupType.shortLabel,
                        style: const TextStyle(
                          color: Color(0xFF8B95A1),
                          fontSize: 9.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${pnl >= 0 ? '+' : ''}${fmt.format(pnl)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          context
                              .read<Portfolio>()
                              .closePosition(pos, currentPrice);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2630),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
