import 'package:flutter/material.dart';
import 'package:tradexa/theme/app_colors.dart';

class Strategy {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String timeframe;
  final String riskReward;
  final String winRate;
  final List<String> howItWorks;
  final List<String> signals;

  const Strategy({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.timeframe,
    required this.riskReward,
    required this.winRate,
    required this.howItWorks,
    required this.signals,
  });

  static const all = [orderBlock, fairValueGap, liquiditySweep];

  static const orderBlock = Strategy(
    id: 'order_block',
    name: 'Order Block',
    tagline: 'Institutional supply & demand zones',
    description:
        'Order Blocks mark the last candle before a sharp impulsive move, '
        'representing zones where institutions placed large orders. Price '
        'frequently returns to these zones for a reaction.',
    icon: Icons.grid_view_rounded,
    accentColor: AppColors.primaryBlue,
    timeframe: '15m / 1h',
    riskReward: '1 : 2.5',
    winRate: '62%',
    howItWorks: [
      'Identify a strong impulsive move (3%+ in a few candles)',
      'Mark the last opposite-colored candle before the impulse as the OB',
      'Wait for price to retrace back into the OB zone',
      'Enter at the zone edge with a tight stop beyond the OB',
    ],
    signals: [
      'Bullish OB — last bearish candle before a bullish impulse',
      'Bearish OB — last bullish candle before a bearish impulse',
      'Higher confidence near HTF support / resistance',
    ],
  );

  static const fairValueGap = Strategy(
    id: 'fair_value_gap',
    name: 'Fair Value Gap',
    tagline: 'Price imbalances left behind by institutions',
    description:
        'A Fair Value Gap (FVG) forms when a 3-candle sequence leaves a gap '
        'between candle 1\'s high and candle 3\'s low (bullish) or vice versa. '
        'Markets are drawn to fill these imbalances.',
    icon: Icons.space_dashboard_outlined,
    accentColor: Color(0xFF7C3AED),
    timeframe: '15m / 1h',
    riskReward: '1 : 3.0',
    winRate: '58%',
    howItWorks: [
      'Look for a strong directional candle (candle 2) in the middle of 3',
      'A gap exists when C1 high < C3 low (bullish) or C1 low > C3 high (bearish)',
      'Wait for price to retrace and fill half of the FVG',
      'Enter at the 50% level with stop beyond the full FVG',
    ],
    signals: [
      'Bullish FVG — gap above candle 1, price dips to fill',
      'Bearish FVG — gap below candle 1, price rises to fill',
      'Unfilled FVGs act as strong magnets for price',
    ],
  );

  static const liquiditySweep = Strategy(
    id: 'liquidity_sweep',
    name: 'Liquidity Sweep',
    tagline: 'Stop-hunt reversals at swing extremes',
    description:
        'Institutions sweep clustered stop orders sitting above swing highs '
        'or below swing lows, triggering a sharp reversal immediately after. '
        'The entry is taken once the sweep candle closes back inside the range.',
    icon: Icons.waterfall_chart,
    accentColor: AppColors.buttonGreen,
    timeframe: '15m / 1h',
    riskReward: '1 : 2.0',
    winRate: '55%',
    howItWorks: [
      'Identify a clean swing high or low with clustered stops',
      'Watch for a wick that spikes beyond the level then snaps back',
      'Enter when the sweep candle closes back inside the prior range',
      'Stop is placed beyond the sweep wick extreme',
    ],
    signals: [
      'Sweep of highs → bearish reversal entry (sell-side liquidity)',
      'Sweep of lows → bullish reversal entry (buy-side liquidity)',
      'Best when sweep coincides with an OB or FVG',
    ],
  );
}
