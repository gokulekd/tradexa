// Opportunity card — dark TradingView theme.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/theme/app_colors.dart';

const _cardBg = AppColors.surface;
const _border = AppColors.border;
const _txtPri = AppColors.activeText;
const _txtSec = AppColors.inactiveText;
const _chipBg = Color(0xFFF4F7FF);
const _bull = AppColors.buttonGreen;
const _bear = AppColors.danger;

class OpportunityCard extends StatelessWidget {
  final Opportunity opp;
  final bool isSelected;
  final double riskBudget;
  final double maxCapital;
  final VoidCallback onTap;
  final void Function(int qty) onTakeTrade;

  const OpportunityCard({
    super.key,
    required this.opp,
    required this.isSelected,
    required this.riskBudget,
    required this.maxCapital,
    required this.onTap,
    required this.onTakeTrade,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final qty = opp.suggestedQty(riskBudget, maxCapital: maxCapital);
    final constraint = opp.qtyConstraintLabel(riskBudget, maxCapital);
    final capital = opp.capitalRequired(qty);
    final maxLoss = opp.maxLoss(qty);
    final maxGain = opp.maxGain(qty);
    final dirColor = opp.direction == Direction.long ? _bull : _bear;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? dirColor : _border,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: badge · direction · R:R · confidence
            Row(children: [
              _Badge(text: opp.type.shortLabel, color: dirColor),
              const SizedBox(width: 8),
              Text(
                opp.direction.label,
                style: TextStyle(
                  color: dirColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _MetricChip(
                  label: 'R:R',
                  value: '1:${opp.riskReward.toStringAsFixed(1)}'),
              const SizedBox(width: 6),
              _ConfidenceDot(value: opp.confidence),
            ]),
            const SizedBox(height: 8),
            Text(
              opp.reasoning,
              style:
                  const TextStyle(color: _txtSec, fontSize: 11.5, height: 1.3),
            ),
            const SizedBox(height: 10),

            // Entry / SL / Target
            Row(children: [
              _PriceCell(
                  label: 'ENTRY',
                  value: '₹${opp.entry.toStringAsFixed(2)}',
                  color: AppColors.primaryBlue),
              _PriceCell(
                  label: 'STOP',
                  value: '₹${opp.stopLoss.toStringAsFixed(2)}',
                  color: _bear),
              _PriceCell(
                  label: 'TARGET',
                  value: '₹${opp.target.toStringAsFixed(2)}',
                  color: _bull),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 10),

            // Capital / Max Loss / Max Gain
            Row(children: [
              Expanded(
                child: _MoneyCell(
                  label: 'CAPITAL',
                  value: fmt.format(capital),
                  sub: qty > 0 ? '$qty sh · $constraint' : constraint,
                  valueColor: _txtPri,
                ),
              ),
              Expanded(
                child: _MoneyCell(
                  label: 'MAX LOSS',
                  value: '−${fmt.format(maxLoss)}',
                  sub: 'if SL hit',
                  valueColor: _bear,
                ),
              ),
              Expanded(
                child: _MoneyCell(
                  label: 'MAX GAIN',
                  value: '+${fmt.format(maxGain)}',
                  sub: 'at target',
                  valueColor: _bull,
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // Take-trade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: qty > 0 ? () => onTakeTrade(qty) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: _txtSec,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                icon: Icon(
                  opp.direction == Direction.long
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 15,
                ),
                label: Text(
                  qty > 0
                      ? 'Take trade · ${opp.direction.label} $qty @ ₹${opp.entry.toStringAsFixed(2)}'
                      : (constraint == 'no capital'
                          ? 'Not enough demo cash'
                          : 'Risk budget too small'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: '$label ',
            style: const TextStyle(color: _txtSec, fontSize: 10)),
        TextSpan(
            text: value,
            style: const TextStyle(
                color: _txtPri, fontSize: 10, fontWeight: FontWeight.w700)),
      ])),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final double value;
  const _ConfidenceDot({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.75
        ? _bull
        : value >= 0.5
            ? AppColors.primaryBlue
            : _bear;
    return Tooltip(
      message: 'Confidence ${(value * 100).toStringAsFixed(0)}%',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
        ),
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PriceCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _txtSec,
                fontSize: 8.5,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MoneyCell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  const _MoneyCell({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: _txtSec,
              fontSize: 8.5,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              color: valueColor, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 1),
      Text(sub, style: const TextStyle(color: _txtSec, fontSize: 9)),
    ]);
  }
}
