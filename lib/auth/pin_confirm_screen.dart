import 'package:flutter/material.dart';
import 'package:tradexa/auth/auth_service.dart';
import 'package:tradexa/auth/pin_entry_scaffold.dart';

class PinConfirmScreen extends StatefulWidget {
  const PinConfirmScreen({
    super.key,
    required this.initialPin,
    required this.onPinSaved,
  });

  final String initialPin;
  final VoidCallback onPinSaved;

  @override
  State<PinConfirmScreen> createState() => _PinConfirmScreenState();
}

class _PinConfirmScreenState extends State<PinConfirmScreen> {
  final AuthService _authService = AuthService();
  final List<String> _entered = [];
  bool _isSaving = false;
  String? _errorText;

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4 || _isSaving) return;

    setState(() {
      _entered.add(digit);
      _errorText = null;
    });

    if (_entered.length == 4) {
      await _submitPin();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty || _isSaving) return;
    setState(() {
      _entered.removeLast();
      _errorText = null;
    });
  }

  Future<void> _submitPin() async {
    final pin = _entered.join();
    if (pin != widget.initialPin) {
      setState(() {
        _entered.clear();
        _errorText = 'PINs did not match. Try again.';
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.savePin(pin);
      if (!mounted) return;
      widget.onPinSaved();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entered.clear();
        _isSaving = false;
        _errorText = 'Unable to save your PIN right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'Confirm PIN',
      subtitle: 'Re-enter the same 4 digits to finish setup.',
      enteredDigits: _entered.length,
      onDigit: (digit) {
        _onDigit(digit);
      },
      onDelete: _onDelete,
      isBusy: _isSaving,
      errorText: _errorText,
    );
  }
}
