# Kite Insights — Institutional Trading View (v1 MVP)

A single-screen Flutter app that shows live-style candle charts for an Indian-market stock with overlays for the same institutional setups described in the FII/DII playbook — **order blocks, fair value gaps (FVGs), and liquidity sweeps** — plus an opportunities panel that computes capital required and projected P&L, and a demo account balance so you can paper-trade the setups.

This v1 uses **deterministic mock data** so it runs on any device with zero API setup. The architecture is designed so you can later swap `mock_data.dart` for a live Kite Connect data source without touching the detection logic or UI.

## What it does

- Renders a candlestick chart (custom-painted, scrollable horizontally) for a single stock (RELIANCE-shaped data).
- Detects and overlays three institutional setup types on the chart:
  - **Order Blocks** (bullish + bearish) — the last opposite-colored candle before a strong impulse move. Drawn as translucent rectangles extending right.
  - **Fair Value Gaps (FVGs)** — 3-candle imbalance patterns where price left an inefficiency. Drawn as fine-lined rectangles.
  - **Liquidity Sweeps** — wicks that ran a recent swing high/low and reversed. Drawn as dashed horizontal lines with a stop-hunt marker.
- Shows an FII/DII flow strip (mock daily numbers) at the top — the regime indicator your playbook calls out.
- Lists detected opportunities below the chart with: entry, stop-loss, target, R:R, **capital required, max loss, max gain**, and a "Take Trade" button.
- Tracks a demo account starting at ₹5,00,000. Each trade deducts capital used and shows live P&L against the latest mock close. You can close positions to realize P&L back to the balance.
- Tap any opportunity card to highlight its zone on the chart.

## How to run it

You need Flutter installed: <https://docs.flutter.dev/get-started/install>

```bash
# 1. Create a fresh Flutter project (this generates the android/, ios/ folders we don't ship)
flutter create kite_insights
cd kite_insights

# 2. Replace pubspec.yaml and lib/ with the files from this folder
#    (overwrite pubspec.yaml; replace the entire lib/ directory)

# 3. Get packages
flutter pub get

# 4. Run on Android (device connected via USB with debugging, or emulator running)
flutter run
```

If `flutter devices` doesn't show your Android device, enable Developer Options + USB Debugging on the phone, plug it in via USB, and `adb devices` should show it. Then `flutter run` will pick it up.

## File map

```
kite_insights/
├── README.md
├── pubspec.yaml
└── lib/
    ├── main.dart                 # App entry, theme, provider setup
    ├── models.dart               # Candle, Opportunity, Position, FlowData
    ├── mock_data.dart            # Deterministic candle + FII/DII generator
    ├── detector.dart             # The institutional setup detection logic
    ├── portfolio.dart            # Demo balance + open positions (ChangeNotifier)
    ├── chart_screen.dart         # The single screen — assembles everything
    ├── candle_chart.dart         # CustomPaint candlestick + overlays
    └── opportunity_card.dart     # Cards in the opportunities panel
```

## Architecture notes (for when you go live)

The mock data layer is the only thing that needs replacing for live data. `mock_data.dart` exposes:

```dart
List<Candle> getCandles(String symbol);
List<FlowData> getFlowHistory();
```

To go live, build a `live_data.dart` that talks to Kite Connect's REST API (for historical candles via `/instruments/historical/...`) and WebSocket (for live ticks). Keep the `Candle` model identical and the rest of the app works unchanged.

The detector (`detector.dart`) is pure functions over `List<Candle>` — no UI dependency, no Flutter import. You can unit-test it, backtest with it, and run it server-side in a future agent loop.

## What this MVP deliberately doesn't do

- No real order placement. The "Take Trade" button is paper-trading only.
- No live ticks. The latest candle's close is "now."
- No multi-symbol watchlist. One stock, focus on showing the idea.
- No persistence. Restart wipes positions. (Add `shared_preferences` if you want this.)
- No timeframe switcher. Mock data is 15-min candles.
- No advanced setups (breaker blocks, mitigation, premium/discount zones). Easy to add — extend `detector.dart`.

## Disclaimer

Paper-trading tool with mock data. Detection logic is heuristic, not signal-quality verified, and shouldn't be used for live trading decisions without backtesting on your own data. You are not a SEBI Registered Investment Advisor and neither is this app.