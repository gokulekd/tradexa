import 'package:flutter/material.dart';
import 'package:tradexa/theme/app_colors.dart';

class DataBanner extends StatelessWidget {
  final bool isLive;
  const DataBanner({super.key, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppColors.buttonGreen : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.circle : Icons.science_outlined,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isLive
                ? 'LIVE · Angel One SmartAPI'
                : 'DEMO MODE · Mock data (tap ⚙ to connect Angel One)',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
