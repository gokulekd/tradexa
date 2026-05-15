import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tradexa/auth/auth_service.dart';
import 'package:tradexa/auth/pin_unlock_screen.dart';
import 'package:tradexa/auth/pin_setup_screen.dart';
import 'package:tradexa/auth/sign_in_screen.dart';
import 'package:tradexa/home/home_screen.dart';
import 'package:tradexa/theme/app_colors.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  final AuthService _authService = AuthService();
  String? _pinVerifiedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          _pinVerifiedUid = null;
          return const SignInScreen();
        }

        return FutureBuilder<bool>(
          future: _authService.userHasPin(),
          builder: (context, pinSnapshot) {
            if (pinSnapshot.connectionState != ConnectionState.done) {
              return const _AuthLoadingScreen();
            }

            if (pinSnapshot.data == true) {
              if (_pinVerifiedUid == user.uid) {
                return const HomeScreen();
              }

              return PinUnlockScreen(
                onVerified: () {
                  setState(() {
                    _pinVerifiedUid = user.uid;
                  });
                },
              );
            }

            if (_pinVerifiedUid == user.uid) {
              _pinVerifiedUid = null;
            }

            return PinSetupScreen(
              onPinSaved: () => setState(() => _pinVerifiedUid = user.uid),
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
  }
}
