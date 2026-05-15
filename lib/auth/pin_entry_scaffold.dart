import 'package:flutter/material.dart';
import 'package:tradexa/auth/auth_logo.dart';
import 'package:tradexa/theme/app_colors.dart';

class PinEntryScaffold extends StatelessWidget {
  const PinEntryScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.enteredDigits,
    required this.onDigit,
    required this.onDelete,
    this.isBusy = false,
    this.errorText,
  });

  final String title;
  final String subtitle;
  final int enteredDigits;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool isBusy;
  final String? errorText;

  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthLogo(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.activeText,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.inactiveText,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        _buildPinDots(),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 20,
                          child: Text(
                            errorText ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: errorText == null
                                  ? Colors.transparent
                                  : AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isBusy)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        _buildNumpad(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pinLength, (index) {
        final filled = index < enteredDigits;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryBlue : AppColors.border,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 84);

              if (key == 'del') {
                return _NumKey(
                  onTap: isBusy ? null : onDelete,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.inactiveText,
                    size: 22,
                  ),
                );
              }

              return _NumKey(
                onTap: isBusy ? null : () => onDigit(key),
                child: Text(
                  key,
                  style: const TextStyle(
                    color: AppColors.activeText,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: 76,
          height: 76,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
