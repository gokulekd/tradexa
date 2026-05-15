import 'package:flutter/material.dart';
import 'package:tradexa/auth/auth_service.dart';
import 'package:tradexa/auth/pin_entry_scaffold.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({
    super.key,
    required this.onVerified,
  });

  final VoidCallback onVerified;

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final AuthService _authService = AuthService();
  final List<String> _entered = [];
  bool _isChecking = false;
  String? _errorText;

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4 || _isChecking) return;

    setState(() {
      _entered.add(digit);
      _errorText = null;
    });

    if (_entered.length == 4) {
      await _submitPin();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty || _isChecking) return;
    setState(() {
      _entered.removeLast();
      _errorText = null;
    });
  }

  Future<void> _submitPin() async {
    setState(() => _isChecking = true);

    try {
      final isValid = await _authService.verifyPin(_entered.join());
      if (!mounted) return;

      if (isValid) {
        widget.onVerified();
        return;
      }

      setState(() {
        _entered.clear();
        _isChecking = false;
        _errorText = 'Incorrect PIN. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entered.clear();
        _isChecking = false;
        _errorText = 'Unable to verify your PIN right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'Enter PIN',
      subtitle: 'Use your 4-digit PIN to continue.',
      enteredDigits: _entered.length,
      onDigit: _onDigit,
      onDelete: _onDelete,
      isBusy: _isChecking,
      errorText: _errorText,
    );
  }
}
