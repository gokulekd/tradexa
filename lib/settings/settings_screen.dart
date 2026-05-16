import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tradexa/settings/api_settings_screen.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/drawer_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
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
      body: Container(
        color: Colors.black,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _SectionHeader(label: 'ACCOUNT'),
            DrawerTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                // TODO: navigate to Profile screen
              },
            ),
            DrawerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () {
                // TODO: navigate to Wallet screen
              },
            ),
            DrawerTile(
              icon: Icons.tune,
              label: 'Angle One Trade',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApiSettingsScreen(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white12, height: 24),
            ),
            _SectionHeader(label: 'LEGAL'),
            DrawerTile(
              icon: Icons.info_outline,
              label: 'About App',
              onTap: () {
                // TODO: navigate to About screen
              },
            ),
            DrawerTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () {
                // TODO: open Terms & Conditions web view
              },
            ),
            DrawerTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {
                // TODO: open Privacy Policy web view
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white12, height: 24),
            ),
            DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              color: AppColors.danger,
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.inactiveText,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
