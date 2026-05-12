// Candlestick chart — TradingView dark theme.
// Long-press activates crosshair; tap selects an opportunity zone.
// Volume bars at bottom, time labels on X-axis, flexible height via LayoutBuilder.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tradexa/model/candle.dart';

// ── Palette (shared across painters) ─────────────────────────────────────────
const _bg      = Color(0xFF131722);
const _panelBg = Color(0xFF1E222D);
const _grid    = Color(0xFF2A2E39);
const _txtSec  = Color(0xFF787B86);
const _bull    = Color(0xFF26A69A);
const _bear    = Color(0xFFEF5350);
const _xhClr   = Color(0xFF9598A1); // crosshair
const _amber   = Color(0xFFFFB300);

class CandleChart extends StatefulWidget {
  final List<Candle> candles;
  final List<Opportunity> opportunities;
  final int? selectedOpportunityIndex;
  final ValueChanged<int?> onOpportunityTap;
  final ValueChanged<Candle?> onCrosshairChange;

  const CandleChart({
    super.key,
    required this.candles,
    required this.opportunities,
    required this.selectedOpportunityIndex,
    required this.onOpportunityTap,
    required this.onCrosshairChange,
  });

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  static const double _slotW  = 12.0;
  static const double _canW   = 8.0;
  static const double _yAxisW = 64.0;
  static const double _xAxisH = 22.0;
  static const double _volR   = 0.18;

  final _scroll = ScrollController();
  Offset? _crosshair; // local canvas coords of the CustomPaint

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  ({double lo, double hi}) _range() {
    if (widget.candles.isEmpty) return (lo: 0, hi: 1);
    double lo = widget.candles.first.low, hi = widget.candles.first.high;
    for (final c in widget.candles) {
      if (c.low < lo) lo = c.low;
      if (c.high > hi) hi = c.high;
    }
    for (final op in widget.opportunities) {
      lo = math.min(lo, math.min(op.stopLoss, op.zoneBottom));
      hi = math.max(hi, math.max(op.target, op.zoneTop));
    }
    final pad = (hi - lo) * 0.04;
    return (lo: lo - pad, hi: hi + pad);
  }

  double _maxVol() {
    double m = 1;
    for (final c in widget.candles) {
      if (c.volume > m) m = c.volume;
    }
    return m;
  }

  void _setCrosshair(Offset local, double priceH) {
    setState(() => _crosshair = local);
    if (widget.candles.isEmpty) return;
    final idx = (local.dx / _slotW).floor().clamp(0, widget.candles.length - 1);
    widget.onCrosshairChange(widget.candles[idx]);
  }

  void _clearCrosshair() {
    setState(() => _crosshair = null);
    widget.onCrosshairChange(null);
  }

  void _handleTap(Offset local, ({double lo, double hi}) r, double priceH) {
    if (widget.candles.isEmpty) return;
    final price = r.hi - (local.dy / priceH) * (r.hi - r.lo);
    final ci = (local.dx / _slotW).floor();
    int? bestIdx;
    double best = -1;
    for (int i = 0; i < widget.opportunities.length; i++) {
      final op = widget.opportunities[i];
      if (ci < op.anchorIndex) continue;
      if (price < op.zoneBottom || price > op.zoneTop) continue;
      if (op.confidence > best) {
        best = op.confidence;
        bestIdx = i;
      }
    }
    widget.onOpportunityTap(bestIdx);
  }

  @override
  Widget build(BuildContext context) {
    final r   = _range();
    final mv  = _maxVol();
    final totalW = widget.candles.length * _slotW + 40.0;

    return LayoutBuilder(builder: (ctx, box) {
      final fullH  = box.maxHeight;
      final chartH = fullH - _xAxisH;
      final volH   = chartH * _volR;
      final priceH = chartH - volH;

      double? crossPrice;
      if (_crosshair != null &&
          _crosshair!.dy >= 0 &&
          _crosshair!.dy <= priceH) {
        crossPrice = r.hi - (_crosshair!.dy / priceH) * (r.hi - r.lo);
      }

      return Row(children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (d) => _setCrosshair(d.localPosition, priceH),
              onLongPressMoveUpdate: (d) => _setCrosshair(d.localPosition, priceH),
              onLongPressEnd: (_) => _clearCrosshair(),
              onTapUp: (d) => _handleTap(d.localPosition, r, priceH),
              child: CustomPaint(
                size: Size(totalW, fullH),
                painter: _ChartPainter(
                  candles: widget.candles,
                  opps: widget.opportunities,
                  selected: widget.selectedOpportunityIndex,
                  lo: r.lo,
                  hi: r.hi,
                  maxVol: mv,
                  slotW: _slotW,
                  canW: _canW,
                  priceH: priceH,
                  volH: volH,
                  xAxisH: _xAxisH,
                  crossX: _crosshair?.dx,
                  crossY: _crosshair?.dy,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: _yAxisW,
          child: CustomPaint(
            painter: _YAxisPainter(
              lo: r.lo,
              hi: r.hi,
              priceH: priceH,
              volH: volH,
              xAxisH: _xAxisH,
              latestClose: widget.candles.isNotEmpty
                  ? widget.candles.last.close
                  : null,
              crossPrice: crossPrice,
            ),
          ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart painter
// ─────────────────────────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final List<Candle> candles;
  final List<Opportunity> opps;
  final int? selected;
  final double lo, hi, maxVol;
  final double slotW, canW, priceH, volH, xAxisH;
  final double? crossX, crossY;

  _ChartPainter({
    required this.candles,
    required this.opps,
    required this.selected,
    required this.lo,
    required this.hi,
    required this.maxVol,
    required this.slotW,
    required this.canW,
    required this.priceH,
    required this.volH,
    required this.xAxisH,
    required this.crossX,
    required this.crossY,
  });

  double _y(double price) => priceH * (hi - price) / (hi - lo);
  double _cx(int i) => slotW * i + slotW / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
    _drawGrid(canvas, size);
    for (int i = 0; i < opps.length; i++) {
      if (i != selected) _drawZone(canvas, size, opps[i], false);
    }
    _drawCandles(canvas);
    if (selected != null && selected! >= 0 && selected! < opps.length) {
      _drawZone(canvas, size, opps[selected!], true);
    }
    _drawVolume(canvas);
    _drawXAxis(canvas, size);
    if (crossX != null && crossY != null) _drawCrosshair(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _grid
      ..strokeWidth = 0.5;
    for (int i = 1; i < 6; i++) {
      final y = priceH * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawCandles(Canvas canvas) {
    final wp = Paint()..strokeWidth = 1.0;
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final cx = _cx(i);
      final color = c.isBullish ? _bull : _bear;
      wp.color = color;
      canvas.drawLine(Offset(cx, _y(c.high)), Offset(cx, _y(c.low)), wp);
      final top = _y(c.bodyTop);
      final bot = _y(c.bodyBottom);
      canvas.drawRect(
        Rect.fromLTRB(
            cx - canW / 2, top, cx + canW / 2, math.max(bot, top + 1)),
        Paint()..color = color,
      );
    }
  }

  void _drawVolume(Canvas canvas) {
    final baseY = priceH + volH;
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final cx = _cx(i);
      final barH = volH * (c.volume / maxVol);
      canvas.drawRect(
        Rect.fromLTRB(
            cx - canW / 2 + 1, baseY - barH, cx + canW / 2 - 1, baseY),
        Paint()..color = (c.isBullish ? _bull : _bear).withOpacity(0.4),
      );
    }
    canvas.drawLine(
      Offset(0, priceH),
      Offset(double.infinity, priceH),
      Paint()
        ..color = _grid
        ..strokeWidth = 0.5,
    );
  }

  void _drawXAxis(Canvas canvas, Size size) {
    final top = priceH + volH;
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, size.height),
      Paint()..color = _panelBg,
    );
    canvas.drawLine(
      Offset(0, top),
      Offset(size.width, top),
      Paint()
        ..color = _grid
        ..strokeWidth = 0.5,
    );
    final fmt = DateFormat('HH:mm');
    const step = 12;
    for (int i = 0; i < candles.length; i += step) {
      final x = _cx(i);
      final tp = TextPainter(
        text: TextSpan(
          text: fmt.format(candles[i].time),
          style: const TextStyle(color: _txtSec, fontSize: 9.0),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, top + 4));
    }
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _xhClr
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(crossX!, 0), Offset(crossX!, priceH + volH), p);
    if (crossY! >= 0 && crossY! <= priceH) {
      canvas.drawLine(Offset(0, crossY!), Offset(size.width, crossY!), p);
    }
    canvas.drawCircle(
      Offset(crossX!, crossY!.clamp(0.0, priceH + volH)),
      3.0,
      Paint()..color = _xhClr,
    );
  }

  void _drawZone(Canvas canvas, Size size, Opportunity op, bool sel) {
    final left  = _cx(op.anchorIndex);
    final right = size.width;
    final yTop  = _y(op.zoneTop);
    final yBot  = _y(op.zoneBottom);
    if (yTop > priceH && yBot > priceH) return;
    final base = op.direction == Direction.long ? _bull : _bear;

    switch (op.type) {
      case SetupType.bullishOB:
      case SetupType.bearishOB:
        canvas.drawRect(
          Rect.fromLTRB(left, yTop, right, yBot),
          Paint()..color = base.withOpacity(sel ? 0.18 : 0.07),
        );
        canvas.drawRect(
          Rect.fromLTRB(left, yTop, right, yBot),
          Paint()
            ..color = base.withOpacity(sel ? 1.0 : 0.40)
            ..style = PaintingStyle.stroke
            ..strokeWidth = sel ? 1.5 : 0.9,
        );
        _zoneLabel(canvas, left, yTop, op.type.shortLabel, base, sel);
        break;

      case SetupType.bullishFVG:
      case SetupType.bearishFVG:
        canvas.drawRect(
          Rect.fromLTRB(left, yTop, right, yBot),
          Paint()..color = base.withOpacity(sel ? 0.13 : 0.05),
        );
        _dashedRect(canvas, Rect.fromLTRB(left, yTop, right, yBot),
            base.withOpacity(sel ? 1.0 : 0.35), sel ? 1.4 : 0.8);
        _zoneLabel(canvas, left, yTop, op.type.shortLabel, base, sel);
        break;

      case SetupType.liquiditySweepHigh:
      case SetupType.liquiditySweepLow:
        final lineY = op.type == SetupType.liquiditySweepHigh
            ? _y(op.zoneBottom)
            : _y(op.zoneTop);
        final c = base.withOpacity(sel ? 1.0 : 0.65);
        _dashedLine(canvas, Offset(left - 20, lineY), Offset(right, lineY),
            c, sel ? 1.8 : 1.1);
        canvas.drawCircle(
            Offset(_cx(op.anchorIndex), lineY), 3.0, Paint()..color = c);
        _zoneLabel(canvas, left, lineY - 16, op.type.shortLabel, base, sel);
        break;
    }

    if (sel) {
      _levelLine(canvas, size, op.entry, _amber, 'Entry', op.anchorIndex);
      _levelLine(canvas, size, op.stopLoss, _bear, 'SL', op.anchorIndex);
      _levelLine(canvas, size, op.target, _bull, 'TGT', op.anchorIndex);
    }
  }

  void _levelLine(Canvas canvas, Size size, double price, Color color,
      String label, int fromIdx) {
    final y = _y(price);
    if (y < 0 || y > priceH) return;
    _dashedLine(canvas, Offset(_cx(fromIdx), y), Offset(size.width, y),
        color.withOpacity(0.85), 0.9, dashW: 5, gapW: 3);
    final tp = TextPainter(
      text: TextSpan(
        text: ' $label ${price.toStringAsFixed(1)} ',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          backgroundColor: _bg.withOpacity(0.85),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(_cx(fromIdx) + 2, y - tp.height - 1));
  }

  void _zoneLabel(
      Canvas canvas, double x, double y, String text, Color color, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: '  $text  ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          backgroundColor: color.withOpacity(bold ? 1.0 : 0.75),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 2, y + 2));
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Color color, double sw,
      {double dashW = 4, double gapW = 3}) {
    final p = Paint()
      ..color = color
      ..strokeWidth = sw;
    final dist = (b - a).distance;
    if (dist == 0) return;
    final ux = (b.dx - a.dx) / dist, uy = (b.dy - a.dy) / dist;
    double d = 0;
    bool on = true;
    while (d < dist) {
      final end = (d + (on ? dashW : gapW)).clamp(0.0, dist);
      if (on) {
        canvas.drawLine(Offset(a.dx + ux * d, a.dy + uy * d),
            Offset(a.dx + ux * end, a.dy + uy * end), p);
      }
      d = end;
      on = !on;
    }
  }

  void _dashedRect(Canvas canvas, Rect rect, Color color, double sw) {
    _dashedLine(canvas, rect.topLeft, rect.topRight, color, sw);
    _dashedLine(canvas, rect.topRight, rect.bottomRight, color, sw);
    _dashedLine(canvas, rect.bottomRight, rect.bottomLeft, color, sw);
    _dashedLine(canvas, rect.bottomLeft, rect.topLeft, color, sw);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.candles != candles ||
      old.opps != opps ||
      old.selected != selected ||
      old.lo != lo ||
      old.hi != hi ||
      old.crossX != crossX ||
      old.crossY != crossY;
}

// ─────────────────────────────────────────────────────────────────────────────
// Y-axis painter
// ─────────────────────────────────────────────────────────────────────────────

class _YAxisPainter extends CustomPainter {
  final double lo, hi, priceH, volH, xAxisH;
  final double? latestClose, crossPrice;

  _YAxisPainter({
    required this.lo,
    required this.hi,
    required this.priceH,
    required this.volH,
    required this.xAxisH,
    required this.latestClose,
    required this.crossPrice,
  });

  double _y(double price) => priceH * (hi - price) / (hi - lo);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _panelBg);
    canvas.drawLine(
      Offset.zero,
      Offset(0, size.height),
      Paint()
        ..color = _grid
        ..strokeWidth = 0.5,
    );

    // Price tick labels
    const ticks = 6;
    for (int i = 0; i <= ticks; i++) {
      final price = lo + (hi - lo) * (ticks - i) / ticks;
      final y = priceH * i / ticks;
      final tp = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(0),
          style: const TextStyle(color: _txtSec, fontSize: 9.5),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }

    // Volume separator in axis
    canvas.drawLine(
      Offset(0, priceH),
      Offset(size.width, priceH),
      Paint()
        ..color = _grid
        ..strokeWidth = 0.5,
    );

    // Latest-close price tag
    if (latestClose != null) {
      final y = _y(latestClose!);
      if (y >= 0 && y <= priceH) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = _amber
            ..strokeWidth = 0.9,
        );
        _priceTag(canvas, size.width, y, latestClose!.toStringAsFixed(2),
            _amber, const Color(0xFF131722));
      }
    }

    // Crosshair price tag
    if (crossPrice != null) {
      final y = _y(crossPrice!);
      if (y >= 0 && y <= priceH) {
        _priceTag(canvas, size.width, y, crossPrice!.toStringAsFixed(2),
            _xhClr, Colors.white);
      }
    }
  }

  void _priceTag(Canvas canvas, double width, double y, String text,
      Color bg, Color fg) {
    final tp = TextPainter(
      text: TextSpan(
        text: ' $text ',
        style: TextStyle(
            color: fg, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final rect =
        Rect.fromLTWH(1, y - tp.height / 2 - 1, width - 2, tp.height + 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = bg,
    );
    tp.paint(canvas, Offset(3, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _YAxisPainter old) =>
      old.lo != lo ||
      old.hi != hi ||
      old.latestClose != latestClose ||
      old.crossPrice != crossPrice;
}
