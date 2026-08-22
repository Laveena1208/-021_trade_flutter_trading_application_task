# 021 Trading App (Flutter)

A small mock trading app demonstrating core flows for the assignment.

Features
- Live market mock feed for 10 stocks: RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, ITC, LT, BHARTIARTL, AXISBANK
- Watchlists: create, rename, delete, add/remove stocks, reorder via drag handle
- Buy/Sell ticket (simulated) and Holdings with local persistence
- Per-symbol numeric price flash; money handled as integer paise

Quick start
1. Install Flutter (stable channel)
2. From the project root run:

   flutter pub get
   flutter run

Run tests
- flutter test

Recording
- Attached a short walkthrough video later showing all features.
- https://github.com/user-attachments/assets/2cd43f4a-9bf0-4a2b-a10f-bf7a83ef1a7e

Notes
- No backend required; local persistence via Hive (plain Map serialization).
- Money is stored as paise (integers). Formatting is handled in lib/core/utils/money.dart.

