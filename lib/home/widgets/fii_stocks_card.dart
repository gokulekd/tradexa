import 'package:flutter/material.dart';
import 'package:tradexa/home/models/stock.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/app_card.dart';
import 'package:tradexa/widgets/section_label.dart';

class FiiStocksCard extends StatelessWidget {
  final List<Stock> stocks;
  final String? loadingSymbol;
  final bool candlesLoaded;
  final void Function(String symbol) onStockTap;

  const FiiStocksCard({
    super.key,
    required this.stocks,
    required this.loadingSymbol,
    required this.candlesLoaded,
    required this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.corporate_fare,
            label: 'FII INSTITUTIONAL UNIVERSE  (${stocks.length} stocks)',
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          ...List.generate(stocks.length, (i) {
            final s = stocks[i];
            final color = Stock.sectorColor(s.sector);
            final isLoading = loadingSymbol == s.symbol;
            return Column(
              children: [
                if (i > 0) const Divider(color: AppColors.border, height: 1),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: candlesLoaded ? () => onStockTap(s.symbol) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.symbol,
                                style: const TextStyle(
                                  color: AppColors.activeText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.name,
                                style: const TextStyle(
                                  color: AppColors.inactiveText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: color.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            s.sector,
                            style: TextStyle(
                              color: color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.inactiveText,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
