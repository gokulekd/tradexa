import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  const HomeAppBar({super.key, required this.onMenuTap});

  @override
  Size get preferredSize => const Size.fromHeight(71);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Image.asset(
                        'assets/logo/Tradexa no background.png',
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
