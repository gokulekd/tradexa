// Live data coordinator.
//
// Drop-in async replacement for mock_data.dart:
//   getCandles(symbol)    → Future<List<Candle>>
//   getFlowHistory()      → Future<List<FlowData>>
//   ltpStream(symbol)     → Stream<double>  (polls every 30 s)
//
// Falls back to mock data when:
//   • No Angel One credentials configured
//   • API call fails (network error, market closed, etc.)

import 'dart:async';
import 'package:tradexa/data/angel_api.dart';
import 'package:tradexa/data/angel_session.dart';
import 'package:tradexa/data/mock_data.dart' as mock;
import 'package:tradexa/data/nse_fii_dii.dart';
import 'package:tradexa/model/candle.dart';

// ---------------------------------------------------------------------------
// Singleton API client — shared across the app lifecycle.
// ---------------------------------------------------------------------------

AngelApi? _api;

Future<AngelApi?> _resolveApi() async {
  if (_api != null) return _api;
  final creds = await loadCredentials();
  if (creds == null || !creds.isComplete) return null;
  _api = AngelApi(creds);
  return _api;
}

// Call this after credentials are saved in settings to pick them up immediately.
void invalidateApiClient() => _api = null;

// ---------------------------------------------------------------------------
// Candles
// ---------------------------------------------------------------------------

Future<List<Candle>> getCandles(String symbol) async {
  final api = await _resolveApi();
  if (api != null) {
    try {
      return await api.getCandles(symbol);
    } catch (_) {
      // Fall through to mock.
    }
  }
  return mock.getCandles(symbol);
}

// ---------------------------------------------------------------------------
// FII/DII flow
// ---------------------------------------------------------------------------

Future<List<FlowData>> getFlowHistory() async {
  final data = await NseFiiDii.fetchFlowHistory();
  if (data.isNotEmpty) return data;
  return mock.getFlowHistory();
}

// ---------------------------------------------------------------------------
// Live price stream (polls every 30 seconds)
// ---------------------------------------------------------------------------

Stream<double> ltpStream(String symbol) async* {
  // Yield current last close from candles immediately so the UI isn't blank.
  final candles = await getCandles(symbol);
  if (candles.isNotEmpty) yield candles.last.close;

  final api = await _resolveApi();
  if (api == null) return; // No credentials — static mock price, no stream.

  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    try {
      final ltp = await api.getLTP(symbol);
      yield ltp;
    } catch (_) {
      // Silently skip this tick.
    }
  }
}

// ---------------------------------------------------------------------------
// State helper — tells the UI whether we are in live or demo mode.
// ---------------------------------------------------------------------------

Future<bool> isLiveMode() async {
  final creds = await loadCredentials();
  return creds != null && creds.isComplete;
}
