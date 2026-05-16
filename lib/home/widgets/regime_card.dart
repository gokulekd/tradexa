import 'package:flutter/material.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';

class RegimeCard extends StatelessWidget {
  final FlowData? latestFlow;
  final double lastClose;
  final String symbol;
  const RegimeCard({
    super.key,
    required this.latestFlow,
    required this.lastClose,
    required this.symbol,
  });

  Color get _regimeColor {
    switch (latestFlow?.regime) {
      case 'risk-on':
        return AppColors.buttonGreen;
      case 'risk-off':
        return AppColors.danger;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final regime = (latestFlow?.regime ?? 'mixed').toUpperCase();
    final color = _regimeColor;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Center(
              child: Icon(
                latestFlow?.regime == 'risk-on'
                    ? Icons.trending_up
                    : latestFlow?.regime == 'risk-off'
                        ? Icons.trending_down
                        : Icons.swap_horiz,
                color: color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MARKET REGIME',
                style: TextStyle(
                  color: AppColors.inactiveText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                regime,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  color: AppColors.inactiveText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${lastClose.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.activeText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
