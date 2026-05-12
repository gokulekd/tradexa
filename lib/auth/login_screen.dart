import 'package:flutter/material.dart';
import 'package:tradexa/home/home_screen.dart';

// Change this to your preferred PIN.
const String _kPin = '1234';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _entered = [];
  bool _hasError = false;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeCtrl.reset();
        setState(() {
          _entered.clear();
          _hasError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_entered.length >= _pinLength || _hasError) return;
    setState(() => _entered.add(d));
    if (_entered.length == _pinLength) {
      _validate();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty || _hasError) return;
    setState(() => _entered.removeLast());
  }

  void _validate() {
    if (_entered.join() == _kPin) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() => _hasError = true);
      _shakeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildPinDots(),
                  const SizedBox(height: 40),
                  _buildNumpad(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFB300).withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFFFB300),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter PIN',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kite Insights · Personal Access',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final offset = _hasError
            ? ((_shakeAnim.value * 12) * (_shakeCtrl.value < 0.5 ? 1 : -1))
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_pinLength, (i) {
          final filled = i < _entered.length;
          final dotColor = _hasError
              ? const Color(0xFFEF5350)
              : filled
                  ? const Color(0xFFFFB300)
                  : const Color(0xFFE2E8F0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hasError
                    ? const Color(0xFFEF5350)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
          );
        }),
      ),
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
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 84);
              if (k == 'del') {
                return _NumKey(
                  child: const Icon(Icons.backspace_outlined,
                      color: Color(0xFF64748B), size: 22),
                  onTap: _onDelete,
                );
              }
              return _NumKey(
                child: Text(
                  k,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _onDigit(k),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NumKey({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
