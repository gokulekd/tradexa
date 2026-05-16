import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tradexa/settings/api_settings_screen.dart';
import 'package:tradexa/theme/app_colors.dart';
import 'package:tradexa/widgets/drawer_tile.dart';

class HomeDrawer extends StatelessWidget {
  final VoidCallback onReload;
  const HomeDrawer({super.key, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Image.asset(
                'assets/splash_screen/tradexe_logo.png',
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  DrawerTile(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: navigate to Profile screen
                    },
                  ),
                  DrawerTile(
                    icon: Icons.tune,
                    label: 'Angle one trade',
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApiSettingsScreen(),
                        ),
                      );
                      onReload();
                    },
                  ),
                  DrawerTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: navigate to Wallet screen
                    },
                  ),
                  DrawerTile(
                    icon: Icons.info_outline,
                    label: 'About App',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: navigate to About screen
                    },
                  ),
                  DrawerTile(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: open Terms & Conditions web view
                    },
                  ),
                  DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
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
                    onTap: () {
                      Navigator.pop(context);
                      FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
