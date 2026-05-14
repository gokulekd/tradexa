import 'package:flutter/material.dart';
import 'package:tradexa/auth/pin_confirm_screen.dart';
import 'package:tradexa/auth/pin_entry_scaffold.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<String> _entered = [];

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;

    setState(() => _entered.add(digit));

    if (_entered.length == 4) {
      final pin = _entered.join();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PinConfirmScreen(initialPin: pin),
        ),
      );
      setState(() {
        _entered.clear();
      });
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'Create PIN',
      subtitle: 'Set a 4-digit PIN for quick access after email sign-in.',
      enteredDigits: _entered.length,
      onDigit: _onDigit,
      onDelete: _onDelete,
    );
  }
}
