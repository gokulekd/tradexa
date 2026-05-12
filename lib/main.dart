import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tradexa/chart%20screen/chart_screen.dart';
import 'package:tradexa/portfolio/portfolio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KiteInsightsApp());
}

class KiteInsightsApp extends StatelessWidget {
  const KiteInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Portfolio(),
      child: MaterialApp(
        title: 'Kite Insights',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const ChartScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFB300),
        secondary: Color(0xFF26A69A),
        surface: Color(0xFF161B22),
        background: Color(0xFF0E1116),
      ),
      cardColor: const Color(0xFF161B22),
      dividerColor: const Color(0xFF2A2F38),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1116),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: const Color(0xFFE6E9EE),
        displayColor: const Color(0xFFE6E9EE),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
