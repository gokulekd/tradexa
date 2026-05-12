// Demo portfolio state. ChangeNotifier so the UI rebuilds on changes.
// Persistence intentionally omitted in v1 — restart wipes positions.

import 'package:flutter/foundation.dart';
import 'package:tradexa/model/candle.dart';

class Portfolio extends ChangeNotifier {
  static const double startingBalance = 500000.0;

  double _cash = startingBalance;
  final List<Position> _openPositions = [];
  final List<_ClosedPosition> _closedPositions = [];

  double get cash => _cash;
  double get startingCash => startingBalance;
  List<Position> get openPositions => List.unmodifiable(_openPositions);
  int get openPositionCount => _openPositions.length;

  double get totalCapitalDeployed =>
      _openPositions.fold(0.0, (sum, p) => sum + p.capitalUsed);

  double unrealizedPnL(double currentPrice) =>
      _openPositions.fold(0.0, (sum, p) => sum + p.currentPnL(currentPrice));

  double get realizedPnL =>
      _closedPositions.fold(0.0, (sum, p) => sum + p.realizedPnL);

  double equity(double currentPrice) =>
      _cash + totalCapitalDeployed + unrealizedPnL(currentPrice);

  double get totalReturnPct {
    final realizedEquity = _cash + totalCapitalDeployed;
    return ((realizedEquity - startingBalance) / startingBalance) * 100;
  }

  /// Attempt to open a position from an opportunity. Returns null on success,
  /// or an error string explaining why it failed.
  String? takeTrade({
    required Opportunity opp,
    required int qty,
    required String symbol,
  }) {
    if (qty <= 0) return 'Quantity must be positive.';
    final capitalNeeded = opp.entry * qty;
    if (capitalNeeded > _cash) {
      return 'Insufficient demo cash. Need ₹${_fmt(capitalNeeded)}, have ₹${_fmt(_cash)}.';
    }
    _cash -= capitalNeeded;
    _openPositions.add(Position(
      symbol: symbol,
      direction: opp.direction,
      entry: opp.entry,
      qty: qty,
      stopLoss: opp.stopLoss,
      target: opp.target,
      entryTime: DateTime.now(),
      setupType: opp.type,
    ));
    notifyListeners();
    return null;
  }

  /// Close a position at the given current price. Realizes P&L and frees capital.
  void closePosition(Position p, double atPrice) {
    if (!_openPositions.remove(p)) return;
    final pnl = p.currentPnL(atPrice);
    _cash += p.capitalUsed + pnl;
    _closedPositions.add(_ClosedPosition(p, atPrice, pnl));
    notifyListeners();
  }

  void reset() {
    _cash = startingBalance;
    _openPositions.clear();
    _closedPositions.clear();
    notifyListeners();
  }

  String _fmt(double n) => n.toStringAsFixed(0);
}

class _ClosedPosition {
  final Position position;
  final double exitPrice;
  final double realizedPnL;
  _ClosedPosition(this.position, this.exitPrice, this.realizedPnL);
}
