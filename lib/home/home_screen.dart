import 'package:flutter/material.dart';
import 'package:tradexa/chart%20screen/chart_screen.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/detector/detector.dart';
import 'package:tradexa/home/models/stock.dart';
import 'package:tradexa/home/widgets/fii_stocks_card.dart';
import 'package:tradexa/home/widgets/home_hero_card.dart';
import 'package:tradexa/home/widgets/trending_strategies_card.dart';
import 'package:tradexa/home/widgets/flow_card.dart';
import 'package:tradexa/home/widgets/home_app_bar.dart';
import 'package:tradexa/home/widgets/home_drawer.dart';
import 'package:tradexa/home/widgets/opportunities_card.dart';
import 'package:tradexa/home/widgets/regime_card.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _primarySymbol = 'RELIANCE';

  List<Candle>? _candles;
  List<FlowData>? _flow;
  List<Opportunity>? _opportunities;
  bool _isLive = false;
  String? _error;
  String? _loadingSymbol;

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
        getCandles(_primarySymbol),
        getFlowHistory(),
        isLiveMode(),
      ]);
      if (!mounted) return;
      final candles = results[0] as List<Candle>;
      setState(() {
        _candles = candles;
        _flow = results[1] as List<FlowData>;
        _isLive = results[2] as bool;
        _opportunities = Detector().detectAll(candles);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openChartFor(String symbol) async {
    if (symbol == _primarySymbol && _candles != null) {
      _pushChart(symbol, _candles!, _flow ?? [], _opportunities ?? []);
      return;
    }
    setState(() => _loadingSymbol = symbol);
    try {
      final candles = await getCandles(symbol);
      final opps = Detector().detectAll(candles);
      if (!mounted) return;
      _pushChart(symbol, candles, _flow ?? [], opps);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSymbol = null);
    }
  }

  void _pushChart(
    String symbol,
    List<Candle> candles,
    List<FlowData> flow,
    List<Opportunity> opps,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChartScreen(
          candles: candles,
          flow: flow,
          opportunities: opps,
          symbol: symbol,
          isLive: _isLive,
        ),
      ),
    );
  }

  FlowData? get _latestFlow =>
      _flow?.isNotEmpty == true ? _flow!.last : null;

  double get _lastClose =>
      _candles?.isNotEmpty == true ? _candles!.last.close : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: HomeAppBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: HomeDrawer(onReload: _load),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_candles == null && _error == null) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Loading market data…',
            style: TextStyle(color: AppColors.inactiveText, fontSize: 13),
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
            const Icon(
              Icons.wifi_off,
              size: 40,
              color: AppColors.inactiveText,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inactiveText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
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

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          HomeHeroCard(isLive: _isLive, lastClose: _lastClose),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TrendingStrategiesCard(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: RegimeCard(
              latestFlow: _latestFlow,
              lastClose: _lastClose,
              symbol: _primarySymbol,
            ),
          ),
          const SizedBox(height: 14),
          if (_latestFlow != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FlowCard(latestFlow: _latestFlow!, isLive: _isLive),
            ),
            const SizedBox(height: 14),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OpportunitiesCard(opportunities: _opportunities ?? []),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FiiStocksCard(
              stocks: Stock.fiiUniverse,
              loadingSymbol: _loadingSymbol,
              candlesLoaded: _candles != null,
              onStockTap: _openChartFor,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
