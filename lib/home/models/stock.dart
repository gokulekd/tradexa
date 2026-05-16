import 'package:flutter/material.dart';
import 'package:tradexa/theme/app_colors.dart';

class Stock {
  final String symbol;
  final String name;
  final String sector;

  const Stock(this.symbol, this.name, this.sector);

  static Color sectorColor(String sector) {
    switch (sector) {
      case 'Energy':
        return AppColors.primaryBlue;
      case 'Financials':
        return const Color(0xFF3F6AE5);
      case 'IT':
        return const Color(0xFF6A1B9A);
      case 'Telecom':
        return const Color(0xFF00838F);
      case 'Staples':
        return AppColors.buttonGreen;
      case 'Cap Goods':
        return const Color(0xFF283593);
      case 'NBFC':
        return const Color(0xFF00695C);
      case 'Auto':
        return const Color(0xFFAD1457);
      case 'Discretionary':
        return const Color(0xFFE65100);
      case 'Materials':
        return const Color(0xFF5D4037);
      case 'Pharma':
        return const Color(0xFF0277BD);
      default:
        return AppColors.inactiveText;
    }
  }

  static const List<Stock> fiiUniverse = [
    Stock('RELIANCE', 'Reliance Industries', 'Energy'),
    Stock('HDFCBANK', 'HDFC Bank', 'Financials'),
    Stock('ICICIBANK', 'ICICI Bank', 'Financials'),
    Stock('AXISBANK', 'Axis Bank', 'Financials'),
    Stock('SBIN', 'State Bank of India', 'Financials'),
    Stock('KOTAKBANK', 'Kotak Mahindra Bank', 'Financials'),
    Stock('INFY', 'Infosys', 'IT'),
    Stock('TCS', 'TCS', 'IT'),
    Stock('HCLTECH', 'HCL Technologies', 'IT'),
    Stock('WIPRO', 'Wipro', 'IT'),
    Stock('BHARTIARTL', 'Bharti Airtel', 'Telecom'),
    Stock('ITC', 'ITC', 'Staples'),
    Stock('HINDUNILVR', 'Hindustan Unilever', 'Staples'),
    Stock('LT', 'Larsen & Toubro', 'Cap Goods'),
    Stock('BAJFINANCE', 'Bajaj Finance', 'NBFC'),
    Stock('BAJAJFINSV', 'Bajaj Finserv', 'NBFC'),
    Stock('MARUTI', 'Maruti Suzuki', 'Auto'),
    Stock('TATAMOTORS', 'Tata Motors', 'Auto'),
    Stock('M&M', 'Mahindra & Mahindra', 'Auto'),
    Stock('ASIANPAINT', 'Asian Paints', 'Discretionary'),
    Stock('ULTRACEMCO', 'UltraTech Cement', 'Materials'),
    Stock('SUNPHARMA', 'Sun Pharma', 'Pharma'),
    Stock('DRREDDY', "Dr Reddy's", 'Pharma'),
    Stock('CIPLA', 'Cipla', 'Pharma'),
  ];
}
