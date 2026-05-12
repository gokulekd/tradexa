// Data models. Kept pure (no Flutter imports) so they can be unit-tested
// or moved to a shared package later.

import 'dart:math' as math;

class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;
  double get bodyTop => isBullish ? close : open;
  double get bodyBottom => isBullish ? open : close;
  double get bodyHeight => (close - open).abs();
  double get range => high - low;
  double get upperWick => high - bodyTop;
  double get lowerWick => bodyBottom - low;
}

enum SetupType {
  bullishOB,
  bearishOB,
  bullishFVG,
  bearishFVG,
  liquiditySweepHigh,
  liquiditySweepLow,
}

extension SetupTypeX on SetupType {
  String get label {
    switch (this) {
      case SetupType.bullishOB:
        return 'Bullish Order Block';
      case SetupType.bearishOB:
        return 'Bearish Order Block';
      case SetupType.bullishFVG:
        return 'Bullish FVG';
      case SetupType.bearishFVG:
        return 'Bearish FVG';
      case SetupType.liquiditySweepHigh:
        return 'Liquidity Sweep (sell-side)';
      case SetupType.liquiditySweepLow:
        return 'Liquidity Sweep (buy-side)';
    }
  }

  String get shortLabel {
    switch (this) {
      case SetupType.bullishOB:
        return 'BULL OB';
      case SetupType.bearishOB:
        return 'BEAR OB';
      case SetupType.bullishFVG:
        return 'BULL FVG';
      case SetupType.bearishFVG:
        return 'BEAR FVG';
      case SetupType.liquiditySweepHigh:
        return 'SWEEP HI';
      case SetupType.liquiditySweepLow:
        return 'SWEEP LO';
    }
  }
}

enum Direction { long, short }

extension DirectionX on Direction {
  String get label => this == Direction.long ? 'LONG' : 'SHORT';
}

/// A detected institutional setup that can be traded.
class Opportunity {
  final SetupType type;
  final Direction direction;
  final int anchorIndex; // candle index where the setup originated
  final double zoneTop; // upper bound of the order block / FVG / sweep level
  final double zoneBottom; // lower bound
  final double entry;
  final double stopLoss;
  final double target;
  final double confidence; // 0..1
  final String reasoning;

  const Opportunity({
    required this.type,
    required this.direction,
    required this.anchorIndex,
    required this.zoneTop,
    required this.zoneBottom,
    required this.entry,
    required this.stopLoss,
    required this.target,
    required this.confidence,
    required this.reasoning,
  });

  double get riskPerShare => (entry - stopLoss).abs();
  double get rewardPerShare => (target - entry).abs();
  double get riskReward => riskPerShare > 0 ? rewardPerShare / riskPerShare : 0;

  /// Suggested position size, capped by both the per-trade risk budget AND
  /// the capital available. For high-priced stocks (Reliance, Bajaj Finance,
  /// etc.) the capital cap will bind first; for cheap stocks the risk cap binds.
  int suggestedQty(double riskBudget, {double? maxCapital}) {
    if (riskPerShare <= 0 || entry <= 0) return 0;
    final byRisk = (riskBudget / riskPerShare).floor();
    if (maxCapital == null) return byRisk.clamp(0, 1000000);
    final byCapital = (maxCapital / entry).floor();
    final qty = byRisk < byCapital ? byRisk : byCapital;
    return qty.clamp(0, 1000000);
  }

  /// Why was the qty what it was? Used to label the UI ("risk-capped" vs "capital-capped").
  String qtyConstraintLabel(double riskBudget, double maxCapital) {
    if (riskPerShare <= 0 || entry <= 0) return '—';
    final byRisk = (riskBudget / riskPerShare).floor();
    final byCapital = (maxCapital / entry).floor();
    if (byCapital <= 0) return 'no capital';
    if (byCapital < byRisk) return 'capital-capped';
    return 'risk-sized';
  }

  /// Capital required to enter the trade (entry price × qty).
  double capitalRequired(int qty) => entry * qty;

  double maxLoss(int qty) => riskPerShare * qty;
  double maxGain(int qty) => rewardPerShare * qty;
}

/// An open paper-trade position.
class Position {
  final String symbol;
  final Direction direction;
  final double entry;
  final int qty;
  final double stopLoss;
  final double target;
  final DateTime entryTime;
  final SetupType setupType;

  Position({
    required this.symbol,
    required this.direction,
    required this.entry,
    required this.qty,
    required this.stopLoss,
    required this.target,
    required this.entryTime,
    required this.setupType,
  });

  double get capitalUsed => entry * qty;
  double get maxRisk => (entry - stopLoss).abs() * qty;
  double get maxReward => (target - entry).abs() * qty;

  double currentPnL(double currentPrice) {
    if (direction == Direction.long) {
      return (currentPrice - entry) * qty;
    } else {
      return (entry - currentPrice) * qty;
    }
  }

  /// Returns "stoppedOut", "targetHit", or "open" based on a price.
  String status(double currentPrice) {
    if (direction == Direction.long) {
      if (currentPrice <= stopLoss) return 'stoppedOut';
      if (currentPrice >= target) return 'targetHit';
    } else {
      if (currentPrice >= stopLoss) return 'stoppedOut';
      if (currentPrice <= target) return 'targetHit';
    }
    return 'open';
  }
}

/// FII/DII flow data point (single day).
class FlowData {
  final DateTime date;
  final double fiiCash; // ₹ crore, +ve = net buy
  final double diiCash;
  final double fiiFnoIndexNetLong; // ₹ crore in index futures

  const FlowData({
    required this.date,
    required this.fiiCash,
    required this.diiCash,
    required this.fiiFnoIndexNetLong,
  });

  /// "Regime" classification — drives the FII/DII strip color.
  /// risk-on = FII buying, risk-off = FII heavy selling, churn = both small.
  String get regime {
    if (fiiCash > 1500) return 'risk-on';
    if (fiiCash < -1500) return 'risk-off';
    if (fiiCash.abs() < 500 && diiCash.abs() < 500) return 'churn';
    return 'mixed';
  }
}

/// Helper: clamp utility used across detectors.
double clampDouble(double v, double lo, double hi) =>
    math.max(lo, math.min(hi, v));
