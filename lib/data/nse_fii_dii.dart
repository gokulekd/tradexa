// NSE FII/DII daily flow data.
//
// NSE publishes cash-market FII & DII net buy/sell every trading day.
// Endpoint: https://www.nseindia.com/api/fiidiiTradeReact
//
// Requires a two-step fetch: first hit the NSE homepage to get cookies,
// then fetch the data endpoint using those cookies.
// Falls back to cached data (SharedPrefs) if the network call fails.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradexa/model/candle.dart';

const _kCacheKey = 'nse_fii_dii_cache';
const _kCacheDateKey = 'nse_fii_dii_cache_date';

// NSE FII/DII trade react endpoint — returns last 30 trading days.
const _kNseDataUrl = 'https://www.nseindia.com/api/fiidiiTradeReact';
const _kNseHomeUrl = 'https://www.nseindia.com';

class NseFiiDii {
  // -------------------------------------------------------------------------
  // Fetch — use cached data if already fetched today.
  // -------------------------------------------------------------------------

  static Future<List<FlowData>> fetchFlowHistory() async {
    final today = _dateStr(DateTime.now());
    final prefs = await SharedPreferences.getInstance();

    // Return cached data if it's from today.
    final cacheDate = prefs.getString(_kCacheDateKey) ?? '';
    if (cacheDate == today) {
      final raw = prefs.getString(_kCacheKey);
      if (raw != null) {
        final parsed = _parseCache(raw);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    // Attempt live fetch.
    try {
      final data = await _fetchLive();
      if (data.isNotEmpty) {
        await prefs.setString(_kCacheDateKey, today);
        await prefs.setString(_kCacheKey, _encodeCache(data));
        return data;
      }
    } catch (_) {
      // Network failure — fall through to stale cache.
    }

    // Stale cache (previous trading day).
    final stale = prefs.getString(_kCacheKey);
    if (stale != null) {
      final parsed = _parseCache(stale);
      if (parsed.isNotEmpty) return parsed;
    }

    // Nothing available — return empty list (caller falls back to mock data).
    return [];
  }

  // -------------------------------------------------------------------------
  // Live fetch
  // -------------------------------------------------------------------------

  static Future<List<FlowData>> _fetchLive() async {
    // Step 1: hit homepage to capture cookies NSE requires.
    final client = http.Client();
    try {
      final homeResp = await client
          .get(Uri.parse(_kNseHomeUrl), headers: _browserHeaders())
          .timeout(const Duration(seconds: 10));

      final cookies = _extractCookies(homeResp.headers);

      // Step 2: fetch FII/DII data with cookies.
      final dataResp = await client
          .get(
            Uri.parse(_kNseDataUrl),
            headers: {
              ..._browserHeaders(),
              if (cookies.isNotEmpty) 'Cookie': cookies,
              'Referer': _kNseHomeUrl,
              'X-Requested-With': 'XMLHttpRequest',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (dataResp.statusCode != 200) return [];
      return _parseResponse(dataResp.body);
    } finally {
      client.close();
    }
  }

  // -------------------------------------------------------------------------
  // Parsing
  // -------------------------------------------------------------------------

  // NSE response structure:
  // { "data": [
  //   { "date": "14-May-2024", "category": "FII/FPI *",
  //     "buyValue": "12345.67", "sellValue": "11234.56", "netValue": "1111.11" },
  //   { "date": "14-May-2024", "category": "DII",
  //     "buyValue": "9876.54", "sellValue": "10234.56", "netValue": "-358.02" },
  //   ...
  // ]}
  static List<FlowData> _parseResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final rows = (json['data'] as List).cast<Map<String, dynamic>>();

    // Group rows by date; each date has one FII row and one DII row.
    final Map<String, Map<String, double>> byDate = {};

    for (final row in rows) {
      final dateStr = (row['date'] as String? ?? '').trim();
      final category = (row['category'] as String? ?? '').toLowerCase();
      final net = _parseNum(row['netValue']);

      if (dateStr.isEmpty) continue;
      byDate.putIfAbsent(dateStr, () => {});

      if (category.contains('fii') || category.contains('fpi')) {
        byDate[dateStr]!['fii'] = net;
      } else if (category.contains('dii')) {
        byDate[dateStr]!['dii'] = net;
      }
    }

    // Convert to FlowData list, sorted oldest-first.
    final result = <FlowData>[];
    for (final entry in byDate.entries) {
      final dt = _parseNseDate(entry.key);
      if (dt == null) continue;
      result.add(FlowData(
        date: dt,
        fiiCash: entry.value['fii'] ?? 0,
        diiCash: entry.value['dii'] ?? 0,
        fiiFnoIndexNetLong: 0, // NSE trade react only covers cash segment.
      ));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    // Return the most recent 10 sessions (matches mock data window).
    if (result.length > 10) return result.sublist(result.length - 10);
    return result;
  }

  // -------------------------------------------------------------------------
  // Cache encode/decode
  // -------------------------------------------------------------------------

  static String _encodeCache(List<FlowData> data) {
    return jsonEncode(data
        .map((f) => {
              'date': f.date.toIso8601String(),
              'fii': f.fiiCash,
              'dii': f.diiCash,
              'fno': f.fiiFnoIndexNetLong,
            })
        .toList());
  }

  static List<FlowData> _parseCache(String raw) {
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map((m) => FlowData(
                date: DateTime.parse(m['date'] as String),
                fiiCash: (m['fii'] as num).toDouble(),
                diiCash: (m['dii'] as num).toDouble(),
                fiiFnoIndexNetLong: (m['fno'] as num).toDouble(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static Map<String, String> _browserHeaders() => {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-IN,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      };

  static String _extractCookies(Map<String, String> headers) {
    return headers['set-cookie'] ?? '';
  }

  static double _parseNum(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // Parses "14-May-2024" format from NSE.
  static DateTime? _parseNseDate(String s) {
    try {
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final parts = s.split('-');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = months[parts[1].toLowerCase()] ?? 0;
      final year = int.parse(parts[2]);
      if (month == 0) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}
