// Angel One SmartAPI client.
//
// Covers:
//   • login (password + TOTP auto-generated from stored secret)
//   • historical OHLC candles (15-min)
//   • LTP quote (latest traded price) for a symbol — polled every 30s
//
// Docs: https://smartapi.angelone.in/docs

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';
import 'package:tradexa/data/angel_session.dart';
import 'package:tradexa/model/candle.dart';

// ---------------------------------------------------------------------------
// Symbol token map — Angel One uses numeric tokens, not ticker strings.
// ---------------------------------------------------------------------------

const Map<String, String> kSymbolTokens = {
  'RELIANCE': '2885',
  'HDFCBANK': '1333',
  'ICICIBANK': '4963',
  'INFY': '1594',
  'TCS': '11536',
  'AXISBANK': '5900',
  'SBI': '3045',
  'KOTAKBANK': '1922',
  'BHARTIARTL': '10604',
  'ITC': '1660',
  'LT': '11483',
  'BAJFINANCE': '317',
  'BAJAJFINSV': '16675',
  'MARUTI': '10999',
  'SUNPHARMA': '3351',
  'DRREDDY': '881',
  'CIPLA': '694',
  'TATAMOTORS': '3456',
  'MM': '2031',
  'ULTRACEMCO': '11532',
  'ASIANPAINT': '236',
};

// ---------------------------------------------------------------------------
// Angel One SmartAPI client
// ---------------------------------------------------------------------------

class AngelApi {
  static const _base = 'https://apiconnect.angelone.in';

  final AngelCredentials credentials;
  AngelSession? _session;

  AngelApi(this.credentials);

  // -------------------------------------------------------------------------
  // Headers
  // -------------------------------------------------------------------------

  Map<String, String> _baseHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-UserType': 'USER',
        'X-SourceID': 'WEB',
        'X-ClientLocalIP': '192.168.1.1',
        'X-ClientPublicIP': '106.193.147.98',
        'X-MACAddress': 'fe80::216e:6507:4b90:3719',
        'X-PrivateKey': credentials.apiKey,
      };

  Map<String, String> _authHeaders() => {
        ..._baseHeaders(),
        'Authorization': 'Bearer ${_session!.jwtToken}',
      };

  // -------------------------------------------------------------------------
  // TOTP generation (auto-generated from stored secret)
  // -------------------------------------------------------------------------

  String _generateTotp() {
    return OTP.generateTOTPCodeString(
      credentials.totpSecret,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  // -------------------------------------------------------------------------
  // Login — call once at app start; re-call if session is expired.
  // -------------------------------------------------------------------------

  Future<AngelSession> login() async {
    // Try cached session first.
    if (_session != null && !_session!.isExpired) return _session!;

    final cached = await loadSession();
    if (cached != null && !cached.isExpired) {
      _session = cached;
      return cached;
    }

    final totp = _generateTotp();
    final body = jsonEncode({
      'clientcode': credentials.clientId,
      'password': credentials.pin,
      'totp': totp,
    });

    final resp = await http
        .post(
          Uri.parse('$_base/rest/auth/angelbroking/user/v1/loginByPassword'),
          headers: _baseHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || json['status'] != true) {
      throw AngelApiException(
          'Login failed: ${json['message'] ?? resp.statusCode}');
    }

    final data = json['data'] as Map<String, dynamic>;
    final session = AngelSession(
      jwtToken: data['jwtToken'] as String,
      refreshToken: data['refreshToken'] as String,
      feedToken: data['feedToken'] as String,
      loginTime: DateTime.now(),
    );

    _session = session;
    await saveSession(session);
    return session;
  }

  // -------------------------------------------------------------------------
  // Historical candles
  // -------------------------------------------------------------------------

  /// Fetch [limit] 15-minute candles for [symbol] (e.g. "RELIANCE") on NSE.
  /// Returns candles sorted oldest-first, ready to drop into the detector.
  Future<List<Candle>> getCandles(
    String symbol, {
    int limit = 80,
    String interval = 'FIFTEEN_MINUTE',
  }) async {
    await login();
    final token = kSymbolTokens[symbol.toUpperCase()];
    if (token == null) throw AngelApiException('Unknown symbol: $symbol');

    final now = DateTime.now();
    // Go back far enough to get `limit` candles (allow for non-trading days).
    final from = now.subtract(const Duration(days: 10));
    final fmt = _fmtDate;

    final body = jsonEncode({
      'exchange': 'NSE',
      'symboltoken': token,
      'interval': interval,
      'fromdate': fmt(from),
      'todate': fmt(now),
    });

    final resp = await http
        .post(
          Uri.parse(
              '$_base/rest/secure/angelbroking/historical/v1/getCandleData'),
          headers: _authHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || json['status'] != true) {
      throw AngelApiException(
          'Historical fetch failed: ${json['message'] ?? resp.statusCode}');
    }

    final raw = (json['data'] as List).cast<List<dynamic>>();
    // Angel One format: [timestamp, open, high, low, close, volume]
    final candles = raw.map((r) {
      return Candle(
        time: DateTime.parse(r[0] as String).toLocal(),
        open: (r[1] as num).toDouble(),
        high: (r[2] as num).toDouble(),
        low: (r[3] as num).toDouble(),
        close: (r[4] as num).toDouble(),
        volume: (r[5] as num).toDouble(),
      );
    }).toList();

    // Only return the last [limit] candles.
    if (candles.length > limit) {
      return candles.sublist(candles.length - limit);
    }
    return candles;
  }

  // -------------------------------------------------------------------------
  // Latest traded price (LTP) — used for polling live price.
  // -------------------------------------------------------------------------

  Future<double> getLTP(String symbol) async {
    await login();
    final token = kSymbolTokens[symbol.toUpperCase()];
    if (token == null) throw AngelApiException('Unknown symbol: $symbol');

    final body = jsonEncode({
      'mode': 'LTP',
      'exchangeTokens': {
        'NSE': [token],
      },
    });

    final resp = await http
        .post(
          Uri.parse('$_base/rest/secure/angelbroking/market/v1/quote/'),
          headers: _authHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 || json['status'] != true) {
      throw AngelApiException(
          'LTP fetch failed: ${json['message'] ?? resp.statusCode}');
    }

    final fetched =
        ((json['data'] as Map)['fetched'] as List).cast<Map<String, dynamic>>();
    if (fetched.isEmpty) throw AngelApiException('No LTP data for $symbol');
    return (fetched.first['ltp'] as num).toDouble();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class AngelApiException implements Exception {
  final String message;
  AngelApiException(this.message);
  @override
  String toString() => 'AngelApiException: $message';
}
