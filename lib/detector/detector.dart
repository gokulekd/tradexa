// Institutional setup detector.
//
// All functions are pure: List<Candle> in, List<Opportunity> out. No Flutter
// imports. This is the layer that encodes the FII/DII playbook as algorithms.
//
// Setups implemented:
//   1. Order Blocks (bullish + bearish): the last opposite-colored candle
//      before a strong impulsive move. Institutions are presumed to defend
//      these zones on revisit.
//   2. Fair Value Gaps (FVGs): 3-candle imbalance patterns where price left
//      an inefficiency that often gets retraced.
//   3. Liquidity Sweeps: candles that wick beyond a recent swing high/low
//      then close back inside — classic stop-hunt + reversal setup.

import 'dart:math' as math;

import 'package:tradexa/model/candle.dart';

class DetectorConfig {
  final int impulseLookahead; // candles after OB candidate to validate impulse
  final double impulseMinPct; // min cumulative move to qualify as impulse (%)
  final int swingWindow; // candles each side to qualify a swing high/low
  final double rrTargetMultiple; // R:R for default target if none structural
  final double zoneBufferPct; // SL placed this % beyond the zone

  const DetectorConfig({
    this.impulseLookahead = 5,
    this.impulseMinPct = 0.9,
    this.swingWindow = 4,
    this.rrTargetMultiple = 2.0,
    this.zoneBufferPct = 0.15,
  });
}

class Detector {
  final DetectorConfig config;
  Detector({this.config = const DetectorConfig()});

  List<Opportunity> detectAll(List<Candle> candles) {
    return [
      ...detectOrderBlocks(candles),
      ...detectFVGs(candles),
      ...detectLiquiditySweeps(candles),
    ];
  }

  // ---------------------------------------------------------------------------
  // ORDER BLOCKS
  // ---------------------------------------------------------------------------

  List<Opportunity> detectOrderBlocks(List<Candle> candles) {
    final results = <Opportunity>[];
    final n = candles.length;
    final lookahead = config.impulseLookahead;

    for (int i = 1; i < n - lookahead; i++) {
      final c = candles[i];
      final startPrice = c.close;
      final endPrice = candles[i + lookahead].close;
      final movePct = ((endPrice - startPrice) / startPrice) * 100;

      // Bullish OB: bearish candle, then strong rally
      if (!c.isBullish && movePct >= config.impulseMinPct) {
        // Verify the impulse is monotone enough (most candles bullish)
        final bullishCount = _countBullish(candles, i + 1, i + lookahead);
        if (bullishCount < (lookahead * 0.6).floor()) continue;

        final zoneTop = c.open; // body top of bearish candle
        final zoneBottom =
            c.close; // body bottom (which is the close for bearish)
        final entry = zoneTop;
        final buffer = (zoneTop - zoneBottom) * config.zoneBufferPct;
        final stopLoss = c.low - buffer;
        final priorSwingHigh = _priorSwingHigh(candles, i);
        final target = priorSwingHigh != null && priorSwingHigh > entry
            ? priorSwingHigh
            : entry + (entry - stopLoss) * config.rrTargetMultiple;

        results.add(Opportunity(
          type: SetupType.bullishOB,
          direction: Direction.long,
          anchorIndex: i,
          zoneTop: zoneTop,
          zoneBottom: zoneBottom,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: _scoreOB(c, movePct, bullishCount, lookahead),
          reasoning:
              'Last bearish candle before a ${movePct.toStringAsFixed(1)}% impulse rally '
              '($bullishCount/$lookahead bullish closes). Institutions often defend this zone on retrace.',
        ));
      }

      // Bearish OB: bullish candle, then strong drop
      if (c.isBullish && -movePct >= config.impulseMinPct) {
        final bearishCount =
            lookahead - _countBullish(candles, i + 1, i + lookahead);
        if (bearishCount < (lookahead * 0.6).floor()) continue;

        final zoneTop = c.close; // body top of bullish candle
        final zoneBottom = c.open;
        final entry = zoneBottom;
        final buffer = (zoneTop - zoneBottom) * config.zoneBufferPct;
        final stopLoss = c.high + buffer;
        final priorSwingLow = _priorSwingLow(candles, i);
        final target = priorSwingLow != null && priorSwingLow < entry
            ? priorSwingLow
            : entry - (stopLoss - entry) * config.rrTargetMultiple;

        results.add(Opportunity(
          type: SetupType.bearishOB,
          direction: Direction.short,
          anchorIndex: i,
          zoneTop: zoneTop,
          zoneBottom: zoneBottom,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: _scoreOB(c, -movePct, bearishCount, lookahead),
          reasoning:
              'Last bullish candle before a ${(-movePct).toStringAsFixed(1)}% impulse drop '
              '($bearishCount/$lookahead bearish closes). Distribution zone.',
        ));
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // FAIR VALUE GAPS (FVG / Imbalance)
  // ---------------------------------------------------------------------------

  List<Opportunity> detectFVGs(List<Candle> candles) {
    final results = <Opportunity>[];
    final n = candles.length;

    for (int i = 1; i < n - 1; i++) {
      final prev = candles[i - 1];
      final mid = candles[i];
      final next = candles[i + 1];

      // Bullish FVG: prev.high < next.low (a price range never traded down through)
      if (prev.high < next.low) {
        final gapSize = next.low - prev.high;
        // Require the middle candle to be a strong bullish impulse
        if (!mid.isBullish || mid.bodyHeight < gapSize * 0.6) continue;

        final zoneTop = next.low;
        final zoneBottom = prev.high;
        final entry = (zoneTop + zoneBottom) / 2; // 50% fill
        final stopLoss = zoneBottom - gapSize * 0.5;
        final target = entry + (entry - stopLoss) * config.rrTargetMultiple;

        results.add(Opportunity(
          type: SetupType.bullishFVG,
          direction: Direction.long,
          anchorIndex: i,
          zoneTop: zoneTop,
          zoneBottom: zoneBottom,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: _scoreFVG(gapSize, mid),
          reasoning:
              'Bullish imbalance of ₹${gapSize.toStringAsFixed(2)}. Retrace to the 50% fill '
              'historically attracts continuation buyers.',
        ));
      }

      // Bearish FVG: prev.low > next.high
      if (prev.low > next.high) {
        final gapSize = prev.low - next.high;
        if (mid.isBullish || mid.bodyHeight < gapSize * 0.6) continue;

        final zoneTop = prev.low;
        final zoneBottom = next.high;
        final entry = (zoneTop + zoneBottom) / 2;
        final stopLoss = zoneTop + gapSize * 0.5;
        final target = entry - (stopLoss - entry) * config.rrTargetMultiple;

        results.add(Opportunity(
          type: SetupType.bearishFVG,
          direction: Direction.short,
          anchorIndex: i,
          zoneTop: zoneTop,
          zoneBottom: zoneBottom,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: _scoreFVG(gapSize, mid),
          reasoning:
              'Bearish imbalance of ₹${gapSize.toStringAsFixed(2)}. 50% retrace common before continuation lower.',
        ));
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // LIQUIDITY SWEEPS
  // ---------------------------------------------------------------------------

  List<Opportunity> detectLiquiditySweeps(List<Candle> candles) {
    final results = <Opportunity>[];
    final n = candles.length;
    final w = config.swingWindow;

    for (int i = w + 1; i < n - 1; i++) {
      final c = candles[i];

      // Find recent swing high in the last 15 candles before i
      final lookbackStart = math.max(0, i - 15);
      double swingHigh = 0;
      int swingHighIdx = -1;
      for (int j = lookbackStart; j < i; j++) {
        if (_isSwingHigh(candles, j, w)) {
          if (candles[j].high > swingHigh) {
            swingHigh = candles[j].high;
            swingHighIdx = j;
          }
        }
      }
      // Sell-side sweep: wicked above swingHigh, closed back below
      if (swingHighIdx >= 0 &&
          c.high > swingHigh &&
          c.close < swingHigh &&
          (c.high - c.close) > c.bodyHeight) {
        final entry = c.close;
        final stopLoss = c.high + (c.high - c.close) * 0.1;
        final priorSwingLow = _priorSwingLow(candles, i);
        final target = priorSwingLow != null && priorSwingLow < entry
            ? priorSwingLow
            : entry - (stopLoss - entry) * config.rrTargetMultiple;
        results.add(Opportunity(
          type: SetupType.liquiditySweepHigh,
          direction: Direction.short,
          anchorIndex: i,
          zoneTop: c.high,
          zoneBottom: swingHigh,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: 0.72,
          reasoning:
              'Wicked ₹${(c.high - swingHigh).toStringAsFixed(2)} above the prior swing high at '
              '₹${swingHigh.toStringAsFixed(2)} and closed back below — classic stop-hunt reversal.',
        ));
      }

      // Same logic for buy-side sweep (swing low broken then reclaimed)
      double swingLow = double.infinity;
      int swingLowIdx = -1;
      for (int j = lookbackStart; j < i; j++) {
        if (_isSwingLow(candles, j, w)) {
          if (candles[j].low < swingLow) {
            swingLow = candles[j].low;
            swingLowIdx = j;
          }
        }
      }
      if (swingLowIdx >= 0 &&
          c.low < swingLow &&
          c.close > swingLow &&
          (c.close - c.low) > c.bodyHeight) {
        final entry = c.close;
        final stopLoss = c.low - (c.close - c.low) * 0.1;
        final priorSwingHigh = _priorSwingHigh(candles, i);
        final target = priorSwingHigh != null && priorSwingHigh > entry
            ? priorSwingHigh
            : entry + (entry - stopLoss) * config.rrTargetMultiple;
        results.add(Opportunity(
          type: SetupType.liquiditySweepLow,
          direction: Direction.long,
          anchorIndex: i,
          zoneTop: swingLow,
          zoneBottom: c.low,
          entry: entry,
          stopLoss: stopLoss,
          target: target,
          confidence: 0.72,
          reasoning:
              'Wicked ₹${(swingLow - c.low).toStringAsFixed(2)} below the prior swing low at '
              '₹${swingLow.toStringAsFixed(2)} and closed back above — buy-side liquidity grab.',
        ));
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  int _countBullish(List<Candle> cs, int from, int to) {
    int count = 0;
    for (int k = from; k <= to && k < cs.length; k++) {
      if (cs[k].isBullish) count++;
    }
    return count;
  }

  double? _priorSwingHigh(List<Candle> cs, int beforeIdx) {
    double? hi;
    final from = math.max(0, beforeIdx - 25);
    for (int k = from; k < beforeIdx - config.swingWindow; k++) {
      if (_isSwingHigh(cs, k, config.swingWindow)) {
        if (hi == null || cs[k].high > hi) hi = cs[k].high;
      }
    }
    return hi;
  }

  double? _priorSwingLow(List<Candle> cs, int beforeIdx) {
    double? lo;
    final from = math.max(0, beforeIdx - 25);
    for (int k = from; k < beforeIdx - config.swingWindow; k++) {
      if (_isSwingLow(cs, k, config.swingWindow)) {
        if (lo == null || cs[k].low < lo) lo = cs[k].low;
      }
    }
    return lo;
  }

  bool _isSwingHigh(List<Candle> cs, int idx, int w) {
    if (idx - w < 0 || idx + w >= cs.length) return false;
    final h = cs[idx].high;
    for (int k = idx - w; k <= idx + w; k++) {
      if (k == idx) continue;
      if (cs[k].high >= h) return false;
    }
    return true;
  }

  bool _isSwingLow(List<Candle> cs, int idx, int w) {
    if (idx - w < 0 || idx + w >= cs.length) return false;
    final l = cs[idx].low;
    for (int k = idx - w; k <= idx + w; k++) {
      if (k == idx) continue;
      if (cs[k].low <= l) return false;
    }
    return true;
  }

  double _scoreOB(Candle c, double movePct, int aligned, int lookahead) {
    // Higher score for: stronger impulse, more aligned candles, smaller OB body
    // (smaller bodies = cleaner re-entry zones)
    final impulseScore = math.min(movePct / 3.0, 1.0);
    final alignScore = aligned / lookahead;
    final bodyScore = 1.0 - math.min(c.bodyHeight / c.range, 1.0);
    return clampDouble(
        (impulseScore * 0.5 + alignScore * 0.3 + bodyScore * 0.2), 0, 1);
  }

  double _scoreFVG(double gapSize, Candle mid) {
    // Bigger gap + bigger impulse body = higher confidence
    final s = math.min(gapSize / 8.0, 1.0) * 0.6 +
        math.min(mid.bodyHeight / 15.0, 1.0) * 0.4;
    return clampDouble(s, 0, 1);
  }
}
