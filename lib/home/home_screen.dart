import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/chart%20screen/chart_screen.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/detector/detector.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/portfolio/portfolio.dart';
import 'package:tradexa/settings/api_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _symbol = 'RELIANCE';

  List<Candle>? _candles;
  List<FlowData>? _flow;
  List<Opportunity>? _opportunities;
  bool _isLive = false;
  String? _error;

  final _fmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _candles = null;
    });
    try {
      final results = await Future.wait([
        getCandles(_symbol),
        getFlowHistory(),
        isLiveMode(),
      ]);
      final candles = results[0] as List<Candle>;
      final flow = results[1] as List<FlowData>;
      final live = results[2] as bool;
      if (!mounted) return;
      setState(() {
        _candles = candles;
        _flow = flow;
        _isLive = live;
        _opportunities = Detector().detectAll(candles);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  FlowData? get _latestFlow => _flow?.isNotEmpty == true ? _flow!.last : null;
  double get _lastClose => _candles?.isNotEmpty == true ? _candles!.last.close : 0;

  Color get _regimeColor {
    switch (_latestFlow?.regime) {
      case 'risk-on':
        return const Color(0xFF26A69A);
      case 'risk-off':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFFB300);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _candles == null && _error == null
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFFFB300)),
          SizedBox(height: 16),
          Text(
            'Loading market data…',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: const Color(0xFFFFB300),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildDataBanner(),
          const SizedBox(height: 14),
          _buildPortfolioCard(),
          const SizedBox(height: 14),
          _buildRegimeCard(),
          const SizedBox(height: 14),
          _buildFlowCard(),
          const SizedBox(height: 14),
          _buildOpportunitiesCard(),
          const SizedBox(height: 20),
          _buildOpenChartButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFFFFB300).withOpacity(0.5), width: 0.8),
            ),
            child: const Text(
              'KITE INSIGHTS',
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, size: 20, color: Color(0xFF64748B)),
          tooltip: 'API Settings',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ApiSettingsScreen()),
            );
            _load(); // Reload with potentially new credentials.
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
          tooltip: 'Refresh data',
          onPressed: _load,
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined,
              size: 20, color: Color(0xFF64748B)),
          tooltip: 'Reset demo balance',
          onPressed: () => context.read<Portfolio>().reset(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Live / Demo banner
  // ---------------------------------------------------------------------------

  Widget _buildDataBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isLive
            ? const Color(0xFF26A69A).withOpacity(0.08)
            : const Color(0xFFFFB300).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isLive
              ? const Color(0xFF26A69A).withOpacity(0.3)
              : const Color(0xFFFFB300).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isLive ? Icons.circle : Icons.science_outlined,
            size: 10,
            color: _isLive
                ? const Color(0xFF26A69A)
                : const Color(0xFFFFB300),
          ),
          const SizedBox(width: 8),
          Text(
            _isLive
                ? 'LIVE · Angel One SmartAPI'
                : 'DEMO MODE · Mock data (tap ⚙ to connect Angel One)',
            style: TextStyle(
              color: _isLive
                  ? const Color(0xFF26A69A)
                  : const Color(0xFFFFB300),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Portfolio card
  // ---------------------------------------------------------------------------

  Widget _buildPortfolioCard() {
    return Consumer<Portfolio>(
      builder: (context, p, _) {
        final equity = p.equity(_lastClose);
        final returnPct =
            ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) *
                100;
        final isPositive = returnPct >= 0;
        final pnlColor = isPositive
            ? const Color(0xFF26A69A)
            : const Color(0xFFEF5350);

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                icon: Icons.account_balance_wallet_outlined,
                label: 'DEMO PORTFOLIO',
                color: const Color(0xFF64748B),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Equity',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        _fmt.format(equity),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pnlColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: pnlColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatItem(
                    label: 'Cash',
                    value: _fmt.format(p.cash),
                    valueColor: const Color(0xFF1E293B),
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Positions',
                    value: '${p.openPositions.length}',
                    valueColor: p.openPositions.isEmpty
                        ? const Color(0xFF64748B)
                        : const Color(0xFFFFB300),
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Starting',
                    value: _fmt.format(Portfolio.startingBalance),
                    valueColor: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Regime card
  // ---------------------------------------------------------------------------

  Widget _buildRegimeCard() {
    final regime = (_latestFlow?.regime ?? 'mixed').toUpperCase();
    return _Card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _regimeColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _regimeColor.withOpacity(0.35)),
            ),
            child: Center(
              child: Icon(
                _latestFlow?.regime == 'risk-on'
                    ? Icons.trending_up
                    : _latestFlow?.regime == 'risk-off'
                        ? Icons.trending_down
                        : Icons.swap_horiz,
                color: _regimeColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MARKET REGIME',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                regime,
                style: TextStyle(
                  color: _regimeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _symbol,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${_lastClose.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FII / DII flow card
  // ---------------------------------------------------------------------------

  Widget _buildFlowCard() {
    final f = _latestFlow;
    if (f == null) return const SizedBox.shrink();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.bar_chart,
            label: 'FII / DII FLOW (Latest)',
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _FlowItem(label: 'FII Cash', value: f.fiiCash),
              const SizedBox(width: 16),
              _FlowItem(label: 'DII Cash', value: f.diiCash),
              const SizedBox(width: 16),
              _FlowItem(label: 'FII F&O', value: f.fiiFnoIndexNetLong),
            ],
          ),
          if (_isLive) ...[
            const SizedBox(height: 10),
            const Text(
              'Source: NSE India (live)',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Opportunities summary
  // ---------------------------------------------------------------------------

  Widget _buildOpportunitiesCard() {
    final opps = _opportunities ?? [];
    final obCount = opps
        .where((o) =>
            o.type == SetupType.bullishOB || o.type == SetupType.bearishOB)
        .length;
    final fvgCount = opps
        .where((o) =>
            o.type == SetupType.bullishFVG || o.type == SetupType.bearishFVG)
        .length;
    final sweepCount = opps
        .where((o) =>
            o.type == SetupType.liquiditySweepHigh ||
            o.type == SetupType.liquiditySweepLow)
        .length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.auto_graph,
            label: 'DETECTED SETUPS',
            color: const Color(0xFFFFB300),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SetupBadge(
                  label: 'Order Blocks',
                  count: obCount,
                  color: const Color(0xFF26A69A)),
              const SizedBox(width: 10),
              _SetupBadge(
                  label: 'FVGs',
                  count: fvgCount,
                  color: const Color(0xFF66BB6A)),
              const SizedBox(width: 10),
              _SetupBadge(
                  label: 'Sweeps',
                  count: sweepCount,
                  color: const Color(0xFFFFB300)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${opps.length} total opportunities on 15m chart',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Open chart button
  // ---------------------------------------------------------------------------

  Widget _buildOpenChartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB300),
          foregroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: _candles == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChartScreen(
                      candles: _candles!,
                      flow: _flow ?? [],
                      opportunities: _opportunities ?? [],
                      symbol: _symbol,
                      isLive: _isLive,
                    ),
                  ),
                );
              },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.candlestick_chart, size: 20),
            SizedBox(width: 10),
            Text(
              'Open Chart View',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets (same as before)
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatItem(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FlowItem extends StatelessWidget {
  final String label;
  final double value;
  const _FlowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isPos = value >= 0;
    final color =
        isPos ? const Color(0xFF26A69A) : const Color(0xFFEF5350);
    final sign = isPos ? '+' : '−';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              '$sign₹${value.abs().toStringAsFixed(0)}cr',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SetupBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
