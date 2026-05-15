import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.width = 150,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/splash_screen/tradexe_logo.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}
