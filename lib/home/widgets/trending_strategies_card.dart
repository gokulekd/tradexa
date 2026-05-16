import 'package:flutter/material.dart';
import 'package:tradexa/strategies/strategy.dart';
import 'package:tradexa/strategies/trading_strategies_screen.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';
import 'package:tradexa/widgets/section_label.dart';

class TrendingStrategiesCard extends StatelessWidget {
  const TrendingStrategiesCard({super.key});

  void _openStrategies(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TradingStrategiesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trending = [Strategy.orderBlock, Strategy.fairValueGap];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            icon: Icons.auto_awesome,
            label: 'TRENDING STRATEGIES',
            color: AppColors.inactiveText,
          ),
          const SizedBox(height: 14),

          // Two strategy mini-cards
          ...trending.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StrategyMiniCard(strategy: s),
            ),
          ),

          const SizedBox(height: 2),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // View All button
          GestureDetector(
            onTap: () => _openStrategies(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all strategies',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyMiniCard extends StatelessWidget {
  final Strategy strategy;

  const _StrategyMiniCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final color = strategy.accentColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(strategy.icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Name + tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy.name,
                  style: const TextStyle(
                    color: AppColors.activeText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strategy.tagline,
                  style: const TextStyle(
                    color: AppColors.inactiveText,
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                strategy.riskReward,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strategy.winRate,
                style: const TextStyle(
                  color: AppColors.inactiveText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
