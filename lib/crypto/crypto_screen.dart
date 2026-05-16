import 'package:flutter/material.dart';
import 'package:tradexa/theme/app_colors.dart';

class CryptoScreen extends StatelessWidget {
  const CryptoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Crypto Arbitrage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.buttonGreen.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.buttonGreen.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.currency_bitcoin,
                size: 32,
                color: AppColors.buttonGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Crypto Arbitrage',
              style: TextStyle(
                color: AppColors.activeText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: AppColors.buttonGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cross-exchange crypto arbitrage\nopportunities, coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inactiveText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
