import 'package:flutter/material.dart';
import 'package:tradexa/theme/app_colors.dart';

class FlowItem extends StatelessWidget {
  final String label;
  final double value;
  const FlowItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isPos = value >= 0;
    final color = isPos ? AppColors.buttonGreen : AppColors.danger;
    final sign = isPos ? '+' : '−';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.inactiveText,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$sign₹${value.abs().toStringAsFixed(0)}cr',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
