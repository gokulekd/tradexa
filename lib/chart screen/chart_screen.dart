// TradingView-style chart screen.
// Layout: top bar → timeframe tabs → flow strip → full-screen chart →
//         collapsible bottom panel (positions + opportunities).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/candle%20chart/candle_chart.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/oppertunity%20card/oppertunity_card.dart';
import 'package:tradexa/portfolio/portfolio.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF131722);
const _panelBg = Color(0xFF1E222D);
const _border  = Color(0xFF2A2E39);
const _txtPri  = Color(0xFFD1D4DC);
const _txtSec  = Color(0xFF787B86);
const _bull    = Color(0xFF26A69A);
const _bear    = Color(0xFFEF5350);
const _amber   = Color(0xFFFFB300);

// ─────────────────────────────────────────────────────────────────────────────

class ChartScreen extends StatefulWidget {
  final List<Candle> candles;
  final List<FlowData> flow;
  final List<Opportunity> opportunities;
  final String symbol;
  final bool isLive;

  const ChartScreen({
    super.key,
    required this.candles,
    required this.flow,
    required this.opportunities,
    required this.symbol,
    required this.isLive,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  static const _timeframes = ['1m', '5m', '15m', '1h', '1D', '1W'];
  static const _expandedH  = 320.0;

  late final List<Opportunity> _opps;
  late final Stream<double> _ltpStream;

  int? _selectedIdx;
  Candle? _hoveredCandle;
  bool _panelOpen = false;
  int _tfIdx = 2; // 15m

  double get _riskBudget => Portfolio.startingBalance * 0.01;
  double get _maxCapital => Portfolio.startingBalance * 0.25;

  @override
  void initState() {
    super.initState();
    _opps = List.from(widget.opportunities)
      ..sort((a, b) => b.anchorIndex.compareTo(a.anchorIndex));
    _ltpStream = ltpStream(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _ltpStream,
      initialData:
          widget.candles.isNotEmpty ? widget.candles.last.close : 0.0,
      builder: (context, snap) {
        final price = snap.data ?? 0.0;
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(price),
                _buildTimeframeBar(),
                if (widget.flow.isNotEmpty) _buildFlowStrip(),
                // ── Chart ──────────────────────────────────────────────────
                Expanded(
                  child: Stack(children: [
                    CandleChart(
                      candles: widget.candles,
                      opportunities: _opps,
                      selectedOpportunityIndex: _selectedIdx,
                      onOpportunityTap: (idx) => setState(() =>
                          _selectedIdx = idx == _selectedIdx ? null : idx),
                      onCrosshairChange: (c) =>
                          setState(() => _hoveredCandle = c),
                    ),
                    if (_hoveredCandle != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _OHLCVOverlay(candle: _hoveredCandle!),
                      ),
                    if (widget.isLive)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: _LiveBadge(),
                      ),
                  ]),
                ),
                // ── Panel handle ───────────────────────────────────────────
                _buildPanelHandle(price),
                // ── Expandable panel ───────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: _panelOpen ? _expandedH : 0,
                  color: _panelBg,
                  child: _panelOpen
                      ? _buildBottomPanel(price)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(double price) {
    final hasPrev = widget.candles.length >= 2;
    final prev = hasPrev ? widget.candles[widget.candles.length - 2].close : price;
    final delta = price - prev;
    final pct   = prev != 0 ? (delta / prev) * 100 : 0.0;
    final up    = delta >= 0;
    final chgColor = up ? _bull : _bear;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: _panelBg,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _txtSec),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 18,
        ),
        // Symbol badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _amber.withOpacity(0.45), width: 0.8),
          ),
          child: Text(
            '${widget.symbol} · NSE',
            style: const TextStyle(
              color: _amber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: _txtPri,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        if (hasPrev)
          Flexible(
            child: Text(
              '${up ? '+' : ''}${delta.toStringAsFixed(2)} '
              '(${up ? '+' : ''}${pct.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: chgColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        // Demo balance chip
        Consumer<Portfolio>(builder: (_, p, __) {
          final equity = p.equity(price);
          final ret =
              ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) * 100;
          final c = ret >= 0 ? _bull : _bear;
          return GestureDetector(
            onTap: () {
              context.read<Portfolio>().reset();
              setState(() => _selectedIdx = null);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.withOpacity(0.35)),
              ),
              child: Text(
                '${ret >= 0 ? '+' : ''}${ret.toStringAsFixed(2)}%  DEMO',
                style: TextStyle(
                    color: c, fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
      ]),
    );
  }

  // ── Timeframe bar ─────────────────────────────────────────────────────────

  Widget _buildTimeframeBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _panelBg,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: List.generate(_timeframes.length, (i) {
          final sel = i == _tfIdx;
          return GestureDetector(
            onTap: () => setState(() => _tfIdx = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: sel ? _amber.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: sel
                    ? Border.all(color: _amber.withOpacity(0.5), width: 0.8)
                    : null,
              ),
              child: Text(
                _timeframes[i],
                style: TextStyle(
                  color: sel ? _amber : _txtSec,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── FII / DII flow strip ──────────────────────────────────────────────────

  Widget _buildFlowStrip() {
    final last = widget.flow.last;
    Color regColor;
    switch (last.regime) {
      case 'risk-on':
        regColor = _bull;
        break;
      case 'risk-off':
        regColor = _bear;
        break;
      default:
        regColor = _amber;
    }

    String fmtCr(double v) {
      final s = v >= 0 ? '+' : '−';
      return '$s₹${v.abs().toStringAsFixed(0)}cr';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: regColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: regColor.withOpacity(0.4)),
          ),
          child: Text(
            last.regime.toUpperCase(),
            style: TextStyle(
                color: regColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6),
          ),
        ),
        const SizedBox(width: 10),
        _FlowVal(label: 'FII', value: fmtCr(last.fiiCash),
            color: last.fiiCash >= 0 ? _bull : _bear),
        const SizedBox(width: 10),
        _FlowVal(label: 'DII', value: fmtCr(last.diiCash),
            color: last.diiCash >= 0 ? _bull : _bear),
        const SizedBox(width: 10),
        _FlowVal(label: 'FII F&O', value: fmtCr(last.fiiFnoIndexNetLong),
            color: last.fiiFnoIndexNetLong >= 0 ? _bull : _bear),
        const Spacer(),
        _Sparkline(values: widget.flow.map((f) => f.fiiCash).toList(),
            color: regColor),
      ]),
    );
  }

  // ── Panel handle ──────────────────────────────────────────────────────────

  Widget _buildPanelHandle(double price) {
    return GestureDetector(
      onTap: () => setState(() => _panelOpen = !_panelOpen),
      child: Consumer<Portfolio>(builder: (_, p, __) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: _panelBg,
            border: Border(
              top: BorderSide(color: _border, width: 0.5),
            ),
          ),
          child: Row(children: [
            if (p.openPositions.isNotEmpty) ...[
              const Icon(Icons.bolt, size: 12, color: _bull),
              const SizedBox(width: 4),
              Text(
                '${p.openPositions.length} open',
                style: const TextStyle(
                    color: _bull, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 14),
            ],
            const Icon(Icons.auto_graph, size: 12, color: _amber),
            const SizedBox(width: 4),
            Text(
              '${_opps.length} signals',
              style: const TextStyle(
                  color: _amber, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(
              _panelOpen
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              size: 16,
              color: _txtSec,
            ),
          ]),
        );
      }),
    );
  }

  // ── Bottom panel content ──────────────────────────────────────────────────

  Widget _buildBottomPanel(double price) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Consumer<Portfolio>(builder: (context, p, _) {
      final equity       = p.equity(price);
      final unrealized   = p.unrealizedPnL(price);
      final returnVs     = ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) * 100;
      final retColor     = returnVs >= 0 ? _bull : _bear;

      return Column(children: [
        // Mini balance strip
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border, width: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 14, color: _txtSec),
            const SizedBox(width: 6),
            const Text('DEMO',
                style: TextStyle(
                    color: _txtSec,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
            const SizedBox(width: 12),
            Text(fmt.format(equity),
                style: const TextStyle(
                    color: _txtPri, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(
              '${returnVs >= 0 ? '+' : ''}${returnVs.toStringAsFixed(2)}%',
              style: TextStyle(
                  color: retColor, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              unrealized.abs() < 0.5
                  ? 'no open P&L'
                  : 'unrealized ${unrealized >= 0 ? '+' : ''}${fmt.format(unrealized)}',
              style: TextStyle(color: retColor, fontSize: 10),
            ),
          ]),
        ),
        // Positions (if any)
        if (p.openPositions.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: _border, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: p.openPositions.map((pos) {
                final pnl   = pos.currentPnL(price);
                final pnlC  = pnl >= 0 ? _bull : _bear;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2235),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: pnlC.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: pnlC.withOpacity(0.4)),
                      ),
                      child: Text(pos.direction.label,
                          style: TextStyle(
                              color: pnlC,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pos.qty} @ ₹${pos.entry.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: _txtPri,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(pos.setupType.shortLabel,
                        style:
                            const TextStyle(color: _txtSec, fontSize: 9.5)),
                    const Spacer(),
                    Text(
                      '${pnl >= 0 ? '+' : ''}${fmt.format(pnl)}',
                      style: TextStyle(
                          color: pnlC,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          context.read<Portfolio>().closePosition(pos, price),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Close',
                            style: TextStyle(
                                color: _txtPri,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        // Opportunities header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(children: [
            const Icon(Icons.auto_graph, size: 13, color: _amber),
            const SizedBox(width: 5),
            const Text(
              'SIGNALS',
              style: TextStyle(
                  color: _amber,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('${_opps.length}',
                  style: const TextStyle(
                      color: _txtPri,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text(
              'Risk ₹${_riskBudget.toStringAsFixed(0)} · Cap ₹${_maxCapital.toStringAsFixed(0)}/trade',
              style: const TextStyle(color: _txtSec, fontSize: 9.5),
            ),
          ]),
        ),
        // Opportunities list
        Expanded(
          child: _opps.isEmpty
              ? const Center(
                  child: Text('No setups detected.',
                      style: TextStyle(color: _txtSec, fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: _opps.length,
                  itemBuilder: (context, idx) {
                    final op = _opps[idx];
                    final perTrade =
                        p.cash < _maxCapital ? p.cash : _maxCapital;
                    return OpportunityCard(
                      opp: op,
                      isSelected: idx == _selectedIdx,
                      riskBudget: _riskBudget,
                      maxCapital: perTrade,
                      onTap: () => setState(() =>
                          _selectedIdx =
                              idx == _selectedIdx ? null : idx),
                      onTakeTrade: (qty) {
                        final err = context.read<Portfolio>().takeTrade(
                            opp: op, qty: qty, symbol: widget.symbol);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(err ??
                              'Trade taken · ${op.direction.label} $qty @ ₹${op.entry.toStringAsFixed(2)}'),
                          backgroundColor:
                              err == null ? _bull : _bear,
                          duration: const Duration(seconds: 2),
                        ));
                      },
                    );
                  },
                ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OHLCV overlay (shown when crosshair is active)
// ─────────────────────────────────────────────────────────────────────────────

class _OHLCVOverlay extends StatelessWidget {
  final Candle candle;
  const _OHLCVOverlay({required this.candle});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM  HH:mm');
    final color = candle.isBullish ? _bull : _bear;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _panelBg.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fmt.format(candle.time),
            style:
                const TextStyle(color: _txtSec, fontSize: 9.5),
          ),
          const SizedBox(height: 4),
          _OHLCRow('O', candle.open, color),
          _OHLCRow('H', candle.high, _bull),
          _OHLCRow('L', candle.low, _bear),
          _OHLCRow('C', candle.close, color),
          const SizedBox(height: 2),
          _OHLCRow('V', candle.volume, _txtSec, isVol: true),
        ],
      ),
    );
  }
}

class _OHLCRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isVol;
  const _OHLCRow(this.label, this.value, this.color, {this.isVol = false});

  @override
  Widget build(BuildContext context) {
    final text = isVol
        ? value >= 1e7
            ? '${(value / 1e7).toStringAsFixed(2)}Cr'
            : value >= 1e5
                ? '${(value / 1e5).toStringAsFixed(1)}L'
                : value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 12,
          child: Text(label,
              style: const TextStyle(color: _txtSec, fontSize: 9.5)),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live badge
// ─────────────────────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _bull.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _bull.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                _bull,
                _bull.withOpacity(0.2),
                _ctrl.value,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: _bull,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flow strip helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FlowVal extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FlowVal(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ',
          style: const TextStyle(color: _txtSec, fontSize: 9.5)),
      Text(value,
          style: TextStyle(
              color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 18,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
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
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values;
}
