// Candlestick chart with institutional overlays.
//
// Architecture:
//   - A horizontally scrollable CustomPaint draws candles + zones.
//   - A fixed-width Y-axis sits on the right, showing price labels.
//   - Both share the same price range so labels stay aligned with candles.
//
// Tap detection: GestureDetector wraps the CustomPaint; tap location is mapped
// back to a candle index and price; if a zone contains it, that opportunity
// is reported via onOpportunityTap.

import 'package:flutter/material.dart';
import 'package:tradexa/model/candle.dart';

class CandleChart extends StatefulWidget {
  final List<Candle> candles;
  final List<Opportunity> opportunities;
  final int? selectedOpportunityIndex;
  final ValueChanged<int?> onOpportunityTap;

  const CandleChart({
    super.key,
    required this.candles,
    required this.opportunities,
    required this.selectedOpportunityIndex,
    required this.onOpportunityTap,
  });

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  static const double slotWidth = 14.0;
  static const double candleWidth = 9.0;
  static const double chartHeight = 320.0;
  static const double yAxisWidth = 56.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Jump to the right edge (most recent candles) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ({double yMin, double yMax}) _priceRange() {
    if (widget.candles.isEmpty) return (yMin: 0, yMax: 1);
    double lo = widget.candles.first.low;
    double hi = widget.candles.first.high;
    for (final c in widget.candles) {
      if (c.low < lo) lo = c.low;
      if (c.high > hi) hi = c.high;
    }
    // Expand range to include opportunity zones so SLs and targets are visible
    for (final op in widget.opportunities) {
      lo = lo < op.stopLoss ? lo : op.stopLoss;
      lo = lo < op.zoneBottom ? lo : op.zoneBottom;
      hi = hi > op.target ? hi : op.target;
      hi = hi > op.zoneTop ? hi : op.zoneTop;
    }
    final pad = (hi - lo) * 0.03;
    return (yMin: lo - pad, yMax: hi + pad);
  }

  @override
  Widget build(BuildContext context) {
    final range = _priceRange();
    final totalWidth = widget.candles.length * slotWidth + 20;

    return SizedBox(
      height: chartHeight,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(details.localPosition, range),
                child: CustomPaint(
                  size: Size(totalWidth, chartHeight),
                  painter: _ChartPainter(
                    candles: widget.candles,
                    opportunities: widget.opportunities,
                    selectedIndex: widget.selectedOpportunityIndex,
                    yMin: range.yMin,
                    yMax: range.yMax,
                    slotWidth: slotWidth,
                    candleWidth: candleWidth,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: yAxisWidth,
            child: CustomPaint(
              size: Size(yAxisWidth, chartHeight),
              painter: _YAxisPainter(
                yMin: range.yMin,
                yMax: range.yMax,
                latestClose: widget.candles.isNotEmpty
                    ? widget.candles.last.close
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset local, ({double yMin, double yMax}) range) {
    if (widget.candles.isEmpty) return;
    final tappedPrice =
        range.yMax - (local.dy / chartHeight) * (range.yMax - range.yMin);
    final tappedX = local.dx;
    final candleIndex = (tappedX / slotWidth).floor();

    // Find an opportunity whose zone+x-range contains the tap.
    // Zones extend from anchor to the rightmost candle.
    int? bestIdx;
    double bestScore = -1;
    for (int i = 0; i < widget.opportunities.length; i++) {
      final op = widget.opportunities[i];
      if (candleIndex < op.anchorIndex) continue;
      if (tappedPrice < op.zoneBottom || tappedPrice > op.zoneTop) continue;
      if (op.confidence > bestScore) {
        bestScore = op.confidence;
        bestIdx = i;
      }
    }
    widget.onOpportunityTap(bestIdx);
  }
}

class _ChartPainter extends CustomPainter {
  final List<Candle> candles;
  final List<Opportunity> opportunities;
  final int? selectedIndex;
  final double yMin;
  final double yMax;
  final double slotWidth;
  final double candleWidth;

  _ChartPainter({
    required this.candles,
    required this.opportunities,
    required this.selectedIndex,
    required this.yMin,
    required this.yMax,
    required this.slotWidth,
    required this.candleWidth,
  });

  double _y(double price, double height) =>
      height * (yMax - price) / (yMax - yMin);

  double _xCenter(int i) => slotWidth * i + slotWidth / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;

    // Grid lines (subtle horizontal)
    final gridPaint = Paint()
      ..color = const Color(0xFF1F2630)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      final y = h * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1) Draw non-selected zones first (so selected appears on top)
    for (int i = 0; i < opportunities.length; i++) {
      if (i == selectedIndex) continue;
      _drawZone(canvas, size, opportunities[i], false);
    }

    // 2) Draw candles
    final wickPaint = Paint()..strokeWidth = 1.0;
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final cx = _xCenter(i);
      final color =
          c.isBullish ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

      wickPaint.color = color;
      canvas.drawLine(
        Offset(cx, _y(c.high, h)),
        Offset(cx, _y(c.low, h)),
        wickPaint,
      );

      final top = _y(c.bodyTop, h);
      final bot = _y(c.bodyBottom, h);
      final rect = Rect.fromLTRB(
        cx - candleWidth / 2,
        top,
        cx + candleWidth / 2,
        bot < top + 1 ? top + 1 : bot,
      );
      canvas.drawRect(rect, Paint()..color = color);
    }

    // 3) Selected zone on top with stronger styling
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < opportunities.length) {
      _drawZone(canvas, size, opportunities[selectedIndex!], true);
    }
  }

  void _drawZone(Canvas canvas, Size size, Opportunity op, bool selected) {
    final h = size.height;
    final left = _xCenter(op.anchorIndex);
    final right = size.width;

    final yTop = _y(op.zoneTop, h);
    final yBot = _y(op.zoneBottom, h);

    final isBullish = op.direction == Direction.long;
    final baseColor =
        isBullish ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

    switch (op.type) {
      case SetupType.bullishOB:
      case SetupType.bearishOB:
        // Filled translucent rectangle, solid border
        final fill = Paint()
          ..color = baseColor.withOpacity(selected ? 0.32 : 0.14);
        canvas.drawRect(Rect.fromLTRB(left, yTop, right, yBot), fill);

        final border = Paint()
          ..color = baseColor.withOpacity(selected ? 1.0 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.6 : 1.0;
        canvas.drawRect(Rect.fromLTRB(left, yTop, right, yBot), border);

        _drawLabel(canvas, left, yTop, op.type.shortLabel, baseColor, selected);
        break;

      case SetupType.bullishFVG:
      case SetupType.bearishFVG:
        // Dashed border rectangle (FVGs are more transient than OBs)
        final fill = Paint()
          ..color = baseColor.withOpacity(selected ? 0.22 : 0.08);
        canvas.drawRect(Rect.fromLTRB(left, yTop, right, yBot), fill);
        _drawDashedRect(
          canvas,
          Rect.fromLTRB(left, yTop, right, yBot),
          baseColor.withOpacity(selected ? 1.0 : 0.5),
          selected ? 1.4 : 0.9,
        );
        _drawLabel(canvas, left, yTop, op.type.shortLabel, baseColor, selected);
        break;

      case SetupType.liquiditySweepHigh:
      case SetupType.liquiditySweepLow:
        // Dashed horizontal line at the swept level + small marker
        final lineY = op.type == SetupType.liquiditySweepHigh
            ? _y(op.zoneBottom, h)
            : _y(op.zoneTop, h);
        final color = baseColor.withOpacity(selected ? 1.0 : 0.7);
        _drawDashedLine(canvas, Offset(left - 30, lineY), Offset(right, lineY),
            color, selected ? 2.0 : 1.2);

        // Small "x" marker at the anchor candle showing the sweep
        final mp = Paint()..color = color;
        canvas.drawCircle(Offset(_xCenter(op.anchorIndex), lineY), 3.5, mp);

        _drawLabel(
            canvas, left, lineY - 18, op.type.shortLabel, baseColor, selected);
        break;
    }

    // Entry / SL / Target lines (only on selected to avoid clutter)
    if (selected) {
      _drawLevelLine(canvas, size, op.entry, const Color(0xFFFFD54F), 'Entry',
          op.anchorIndex);
      _drawLevelLine(canvas, size, op.stopLoss, const Color(0xFFEF5350), 'SL',
          op.anchorIndex);
      _drawLevelLine(canvas, size, op.target, const Color(0xFF66BB6A), 'TGT',
          op.anchorIndex);
    }
  }

  void _drawLevelLine(Canvas canvas, Size size, double price, Color color,
      String label, int fromIndex) {
    final y = _y(price, size.height);
    final fromX = _xCenter(fromIndex);
    _drawDashedLine(canvas, Offset(fromX, y), Offset(size.width, y),
        color.withOpacity(0.9), 1.0,
        dashWidth: 5, dashGap: 3);
    final tp = TextPainter(
      text: TextSpan(
        text: ' $label ₹${price.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          backgroundColor: const Color(0xFF0E1116),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(fromX, y - tp.height - 1));
  }

  void _drawLabel(
      Canvas canvas, double x, double y, String text, Color color, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: '  $text  ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          backgroundColor: color.withOpacity(bold ? 1.0 : 0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 2, y + 2));
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Color color, double strokeWidth,
      {double dashWidth = 4, double dashGap = 3}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lenSqrt = (end - start).distance;
    if (lenSqrt == 0) return;
    final ux = dx / lenSqrt;
    final uy = dy / lenSqrt;
    double drawn = 0;
    bool on = true;
    while (drawn < lenSqrt) {
      final seg = on ? dashWidth : dashGap;
      final segEnd = (drawn + seg).clamp(0.0, lenSqrt);
      if (on) {
        canvas.drawLine(
          Offset(start.dx + ux * drawn, start.dy + uy * drawn),
          Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
          paint,
        );
      }
      drawn = segEnd;
      on = !on;
    }
  }

  void _drawDashedRect(
      Canvas canvas, Rect rect, Color color, double strokeWidth) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, color, strokeWidth);
    _drawDashedLine(
        canvas, rect.topRight, rect.bottomRight, color, strokeWidth);
    _drawDashedLine(
        canvas, rect.bottomRight, rect.bottomLeft, color, strokeWidth);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, color, strokeWidth);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) {
    return old.candles != candles ||
        old.opportunities != opportunities ||
        old.selectedIndex != selectedIndex ||
        old.yMin != yMin ||
        old.yMax != yMax;
  }
}

class _YAxisPainter extends CustomPainter {
  final double yMin;
  final double yMax;
  final double? latestClose;

  _YAxisPainter({
    required this.yMin,
    required this.yMax,
    required this.latestClose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background to match scaffold so the axis "covers" any candle that scrolled under
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E1116),
    );

    // Left border
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      Paint()
        ..color = const Color(0xFF2A2F38)
        ..strokeWidth = 0.5,
    );

    // Tick labels
    const ticks = 5;
    for (int i = 0; i <= ticks; i++) {
      final price = yMin + (yMax - yMin) * (ticks - i) / ticks;
      final y = size.height * i / ticks;
      final tp = TextPainter(
        text: TextSpan(
          text: '₹${price.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Color(0xFF8B95A1),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }

    // Latest-close marker
    if (latestClose != null) {
      final y = size.height * (yMax - latestClose!) / (yMax - yMin);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFFFFB300)
          ..strokeWidth = 1.0,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: ' ₹${latestClose!.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFFFFB300),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _YAxisPainter old) =>
      old.yMin != yMin || old.yMax != yMax || old.latestClose != latestClose;
}
