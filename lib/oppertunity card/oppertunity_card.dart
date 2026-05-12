// Card shown in the opportunities panel. One per detected setup.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tradexa/model/candle.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opp;
  final bool isSelected;
  final double riskBudget; // ₹ per trade risk budget — caps qty by risk
  final double maxCapital; // ₹ per trade capital cap — caps qty by cash
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
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final qty = opp.suggestedQty(riskBudget, maxCapital: maxCapital);
    final constraint = opp.qtyConstraintLabel(riskBudget, maxCapital);
    final capital = opp.capitalRequired(qty);
    final maxLoss = opp.maxLoss(qty);
    final maxGain = opp.maxGain(qty);

    final dirColor = opp.direction == Direction.long
        ? const Color(0xFF26A69A)
        : const Color(0xFFEF5350);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? dirColor : const Color(0xFF2A2F38),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type badge, direction, R:R, confidence
            Row(
              children: [
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
                  value: '1:${opp.riskReward.toStringAsFixed(1)}',
                ),
                const SizedBox(width: 6),
                _ConfidenceDot(value: opp.confidence),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              opp.reasoning,
              style: const TextStyle(
                color: Color(0xFFAFB7C2),
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // Entry / SL / Target row
            Row(
              children: [
                _PriceCell(
                    label: 'ENTRY',
                    value: '₹${opp.entry.toStringAsFixed(2)}',
                    color: const Color(0xFFFFD54F)),
                _PriceCell(
                    label: 'STOP',
                    value: '₹${opp.stopLoss.toStringAsFixed(2)}',
                    color: const Color(0xFFEF5350)),
                _PriceCell(
                    label: 'TARGET',
                    value: '₹${opp.target.toStringAsFixed(2)}',
                    color: const Color(0xFF66BB6A)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFF2A2F38)),
            const SizedBox(height: 10),

            // Capital + P&L row
            Row(
              children: [
                Expanded(
                  child: _MoneyCell(
                    label: 'CAPITAL NEEDED',
                    value: fmt.format(capital),
                    sub: qty > 0 ? '$qty shares · $constraint' : constraint,
                    valueColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: _MoneyCell(
                    label: 'MAX LOSS',
                    value: '−${fmt.format(maxLoss)}',
                    sub: 'if SL hit',
                    valueColor: const Color(0xFFEF5350),
                  ),
                ),
                Expanded(
                  child: _MoneyCell(
                    label: 'MAX GAIN',
                    value: '+${fmt.format(maxGain)}',
                    sub: 'at target',
                    valueColor: const Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Take-trade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: qty > 0 ? () => onTakeTrade(qty) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dirColor,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF2A2F38),
                  disabledForegroundColor: const Color(0xFF6B7480),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: Icon(
                  opp.direction == Direction.long
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 16,
                ),
                label: Text(
                  qty > 0
                      ? 'Take trade · ${opp.direction.label} $qty @ ₹${opp.entry.toStringAsFixed(2)}'
                      : (constraint == 'no capital'
                          ? 'Not enough demo cash'
                          : 'Risk budget too small for 1 share'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.55), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
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
        color: const Color(0xFF1F2630),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: Color(0xFF8B95A1),
                fontSize: 10,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final double value;
  const _ConfidenceDot({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.75
        ? const Color(0xFF66BB6A)
        : value >= 0.5
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);
    return Tooltip(
      message: 'Confidence ${(value * 100).toStringAsFixed(0)}%',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.6), blurRadius: 4),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7480),
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7480),
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          sub,
          style: const TextStyle(
            color: Color(0xFF6B7480),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}
