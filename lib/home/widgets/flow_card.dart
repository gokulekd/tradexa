import 'package:flutter/material.dart';
import 'package:tradexa/data/live_data.dart';
import 'package:tradexa/model/candle.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';
import 'package:tradexa/widgets/flow_item.dart';
import 'package:tradexa/widgets/section_label.dart';

class FlowCard extends StatelessWidget {
  final FlowData latestFlow;
  final bool isLive;
  const FlowCard({super.key, required this.latestFlow, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            icon: Icons.bar_chart,
            label: 'FII / DII FLOW (Latest)',
            color: AppColors.inactiveText,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FlowItem(label: 'FII Cash', value: latestFlow.fiiCash),
              const SizedBox(width: 16),
              FlowItem(label: 'DII Cash', value: latestFlow.diiCash),
              const SizedBox(width: 16),
              FlowItem(
                label: 'FII F&O',
                value: latestFlow.fiiFnoIndexNetLong,
              ),
            ],
          ),
          if (isLive) ...[
            const SizedBox(height: 10),
            const Text(
              'Source: NSE India (live)',
              style: TextStyle(color: AppColors.inactiveText, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}
