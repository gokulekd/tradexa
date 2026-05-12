// Deterministic mock data. Engineered to include real institutional setups
// (clear order blocks, FVGs, and a liquidity sweep) so the detector finds
// meaningful opportunities on first run.
//
// Replace this file with a live_data.dart that talks to Kite Connect REST/
// WebSocket APIs when ready. Keep the function signatures identical.

import 'dart:math';

import 'package:tradexa/model/candle.dart';

const String mockSymbol = 'RELIANCE';
const double mockLotSizeOrTick = 0.05;

/// 80 candles of 15-min RELIANCE-shaped data. Engineered "phases":
///   0..14   : mild uptrend (baseline)
///   15..22  : sharp pullback (the last bullish candle here becomes a Bearish OB)
///   23..38  : strong rally (the last bearish candle of the pullback is a Bullish OB;
///             multiple FVGs form in the impulse)
///   39..52  : ranging consolidation (liquidity builds at the highs and lows)
///   53..60  : sweep + reversal — wicks above the consolidation high then closes back
///             (a textbook sell-side liquidity sweep)
///   61..79  : drop, then recovery (creates a fresh bullish OB near the lows)
List<Candle> getCandles(String symbol) {
  final rng = Random(42);
  final candles = <Candle>[];
  double price = 2850.0;
  final start = DateTime(2026, 5, 12, 9, 15);

  double _wick(double scale) => rng.nextDouble() * scale;

  for (int i = 0; i < 80; i++) {
    // Phase-based drift (mean move per candle)
    double drift;
    double wickScale;
    if (i < 15) {
      drift = 0.6;
      wickScale = 3.5;
    } else if (i < 23) {
      drift = -2.4; // pullback
      wickScale = 4.0;
    } else if (i < 39) {
      // Strong impulsive rally — bigger candles, smaller wicks (institutional moves)
      drift = 3.0;
      wickScale = 2.5;
    } else if (i < 53) {
      drift = 0.1; // sideways consolidation around the rally top
      wickScale = 5.0;
    } else if (i < 56) {
      // Build-up before the sweep
      drift = 1.2;
      wickScale = 3.0;
    } else if (i == 56 || i == 57) {
      // Sweep candles: large upper wicks, close lower than open (stop hunt + reversal)
      drift = -1.5;
      wickScale = 12.0; // exaggerated upper wick
    } else if (i < 64) {
      drift = -2.8; // post-sweep drop
      wickScale = 3.5;
    } else if (i < 72) {
      drift = -0.4;
      wickScale = 4.0;
    } else {
      drift = 2.2; // recovery
      wickScale = 3.0;
    }

    final noise = (rng.nextDouble() - 0.5) * 6.0;
    final move = drift + noise;
    final open = price;
    var close = price + move;

    // Inject a small bearish candle right before the rally start at i=22
    // to guarantee a clean bullish order block.
    if (i == 22) {
      close = open - 5.0;
    }
    // Inject a small bullish candle right before the pullback at i=14
    // for a clean bearish order block.
    if (i == 14) {
      close = open + 5.0;
    }

    final hi = max(open, close) + _wick(wickScale);
    final lo = min(open, close) - _wick(wickScale);

    // For sweep candles, force a tall upper wick that pokes above prior highs
    double high = hi;
    double low = lo;
    if (i == 56 || i == 57) {
      final priorHighs = candles
          .sublist(max(0, i - 10), i)
          .map((c) => c.high)
          .fold<double>(0, max);
      high = priorHighs + 8 + rng.nextDouble() * 5;
    }

    final vol = 50000 +
        rng.nextDouble() * 80000 +
        move.abs() * 4500 +
        (i >= 23 && i < 39 ? 30000 : 0); // higher vol on the rally

    candles.add(Candle(
      time: start.add(Duration(minutes: i * 15)),
      open: open,
      high: high,
      low: low,
      close: close,
      volume: vol,
    ));

    price = close;
  }

  return candles;
}

/// Last 10 sessions of FII/DII activity. Engineered to show a mixed-to-risk-on
/// regime with DII as the steady bid (mirrors the structural pattern your
/// FII/DII playbook describes).
List<FlowData> getFlowHistory() {
  final base = DateTime(2026, 5, 12);
  // (fiiCash, diiCash, fiiFnoIndexNetLong) in ₹ crore
  const values = <List<double>>[
    [-2100, 2400, -8500], // risk-off, DII absorbing
    [-1200, 1800, -7200],
    [800, 600, -5000],
    [1600, 400, -3100], // regime flips toward risk-on
    [2400, -200, -800],
    [3100, -600, 1500],
    [1800, 900, 2800],
    [-400, 1500, 2100], // mild churn day
    [-1800, 2200, 300], // brief risk-off
    [2600, -300, 3200], // strong risk-on close-out
  ];
  return List.generate(values.length, (i) {
    return FlowData(
      date: base.subtract(Duration(days: values.length - 1 - i)),
      fiiCash: values[i][0],
      diiCash: values[i][1],
      fiiFnoIndexNetLong: values[i][2],
    );
  });
}
