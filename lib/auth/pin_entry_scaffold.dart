import 'package:flutter/material.dart';
import 'package:tradexa/auth/auth_logo.dart';

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

  static const _bgColor = Color(0xFF000000);
  static const _keyColor = Color(0xFF2C2C2C);
  static const _keyBorderColor = Color(0xFF3A3A3A);
  static const _dotEmpty = Color(0x66FFFFFF);
  static const _dotFilled = Color(0xFFFFFFFF);

  static const _keyLabels = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const AuthLogo(width: 130),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            _buildPinDots(),
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: Text(
                errorText ?? '',
                style: TextStyle(
                  color: errorText == null
                      ? Colors.transparent
                      : const Color(0xFFFF453A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            const Spacer(),
            _buildNumpad(),
            const SizedBox(height: 40),
          ],
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
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: filled ? _dotFilled : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? _dotFilled : _dotEmpty,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80);

              if (key == 'del') {
                return _KeyButton(
                  onTap: isBusy ? null : onDelete,
                  transparent: true,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              }

              return _KeyButton(
                onTap: isBusy ? null : () => onDigit(key),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                    ),
                    if (_keyLabels.containsKey(key))
                      Text(
                        _keyLabels[key]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      )
                    else
                      const SizedBox(height: 11),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.child,
    required this.onTap,
    this.transparent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool transparent;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: widget.transparent
              ? Colors.transparent
              : _pressed
                  ? const Color(0xFF4A4A4A)
                  : PinEntryScaffold._keyColor,
          shape: BoxShape.circle,
          border: widget.transparent
              ? null
              : Border.all(
                  color: PinEntryScaffold._keyBorderColor,
                  width: 0.5,
                ),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
