import 'package:flutter/material.dart';
import 'package:tradexa/detector/detector.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';
import 'package:tradexa/widgets/section_label.dart';
import 'package:tradexa/widgets/setup_badge.dart';

class OpportunitiesCard extends StatelessWidget {
  final List<Opportunity> opportunities;
  const OpportunitiesCard({super.key, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final obCount = opportunities
        .where((o) =>
            o.type == SetupType.bullishOB || o.type == SetupType.bearishOB)
        .length;
    final fvgCount = opportunities
        .where((o) =>
            o.type == SetupType.bullishFVG || o.type == SetupType.bearishFVG)
        .length;
    final sweepCount = opportunities
        .where((o) =>
            o.type == SetupType.liquiditySweepHigh ||
            o.type == SetupType.liquiditySweepLow)
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            icon: Icons.auto_graph,
            label: 'DETECTED SETUPS',
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SetupBadge(
                label: 'Order Blocks',
                count: obCount,
                color: AppColors.buttonGreen,
              ),
              const SizedBox(width: 10),
              SetupBadge(
                label: 'FVGs',
                count: fvgCount,
                color: const Color(0xFF66BB6A),
              ),
              const SizedBox(width: 10),
              SetupBadge(
                label: 'Sweeps',
                count: sweepCount,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${opportunities.length} total opportunities on 15m chart',
            style: const TextStyle(
              color: AppColors.inactiveText,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
