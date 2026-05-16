import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/portfolio/portfolio.dart';
import 'package:tradexa/theme/app_colors.dart';

class HomeHeroCard extends StatelessWidget {
  final bool isLive;
  final double lastClose;

  const HomeHeroCard({
    super.key,
    required this.isLive,
    required this.lastClose,
  });

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
        final unrealizedPnl = p.unrealizedPnL(lastClose);
        final returnPct =
            ((equity - Portfolio.startingBalance) / Portfolio.startingBalance) *
                100;
        final isPositive = returnPct >= 0;
        final pnlPositive = unrealizedPnl >= 0;
        final pnlColor =
            pnlPositive ? AppColors.buttonGreen : AppColors.danger;
        final retColor = isPositive ? AppColors.buttonGreen : AppColors.danger;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live status row
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppColors.buttonGreen
                          : AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLive
                        ? 'Live: Angel One SmartAPI'
                        : 'Demo: Angel One SmartAPI',
                    style: TextStyle(
                      color: isLive
                          ? AppColors.buttonGreen
                          : AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Account label
              const Text(
                'DEMO ACCOUNT',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              // Equity + return %
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      fmt.format(equity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: retColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: retColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: retColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Divider
              Container(height: 1, color: Colors.white12),

              const SizedBox(height: 16),

              // Stats row: Cash | P&L | Positions
              Row(
                children: [
                  _StatCell(
                    label: 'Cash',
                    value: fmt.format(p.cash),
                    valueColor: Colors.white,
                  ),
                  _Divider(),
                  _StatCell(
                    label: 'Unrealised P&L',
                    value:
                        '${pnlPositive ? '+' : ''}${fmt.format(unrealizedPnl)}',
                    valueColor: pnlColor,
                  ),
                  _Divider(),
                  _StatCell(
                    label: 'Positions',
                    value: '${p.openPositions.length}',
                    valueColor: p.openPositions.isEmpty
                        ? Colors.white38
                        : AppColors.primaryBlue,
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

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
