import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/portfolio/portfolio.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';
import 'package:tradexa/widgets/section_label.dart';
import 'package:tradexa/widgets/stat_item.dart';

class PortfolioCard extends StatelessWidget {
  final double lastClose;
  const PortfolioCard({super.key, required this.lastClose});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Consumer<Portfolio>(
      builder: (context, p, _) {
        final equity = p.equity(lastClose);
        final returnPct =
            ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) *
                100;
        final isPositive = returnPct >= 0;
        final pnlColor = isPositive ? AppColors.buttonGreen : AppColors.danger;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(
                icon: Icons.account_balance_wallet_outlined,
                label: 'DEMO PORTFOLIO',
                color: AppColors.inactiveText,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equity',
                        style: TextStyle(
                          color: AppColors.inactiveText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmt.format(equity),
                        style: const TextStyle(
                          color: AppColors.activeText,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: pnlColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: pnlColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatItem(
                    label: 'Cash',
                    value: fmt.format(p.cash),
                    valueColor: AppColors.activeText,
                  ),
                  const SizedBox(width: 24),
                  StatItem(
                    label: 'Positions',
                    value: '${p.openPositions.length}',
                    valueColor: p.openPositions.isEmpty
                        ? AppColors.inactiveText
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 24),
                  StatItem(
                    label: 'Starting',
                    value: fmt.format(Portfolio.startingBalance),
                    valueColor: AppColors.inactiveText,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
