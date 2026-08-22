# Trading App (Flutter, BLoC)

A mock trading app: watchlists, a live market feed, a buy/sell ticket, and a holdings/P&L view.

## Run

```bash
flutter pub get
flutter run
```

No backend, no codegen step Hive is used with plain `Map` serialization.

## Architecture

```
lib/
  core/          constants (the 10 stocks), money formatting, theme
  data/
    market/      MarketDataService - the single mock price feed for the whole app
    repositories/ Hive-backed repositories (watchlists, wallet, holdings, orders)
  domain/
    entities/    plain Dart models (PriceTick, Watchlist, TradeOrder, Holding)
  features/
    market/      Feature 2 - Live Prices (bloc + view + widgets)
    watchlist/   Feature 1 - Watchlists (bloc + view + widgets)
    order_ticket/ Feature 3 - Buy/Sell ticket (bloc + view)
    holdings/    Feature 4 - Holdings (bloc + view + widgets)
```

Each feature is `bloc / view / widgets`. Blocs never talk to Hive directly - they go
through a `Repository`, and every repository exposes a reactive `watchAll()` stream
built on `Box.watch()`, so persistence and in-memory state can't drift apart, and a
Bloc automatically reflects changes made anywhere else in the app.

### Money

Every price, balance and order value is an `int` number of **paise** (₹1 = 100 paise).
There is no `double` money arithmetic anywhere in `data/` or `domain/` - formatting to
"₹" strings happens in exactly one place, `core/utils/money.dart`, at the UI edge. This
is what the brief means by "no floating-point drift visible to the user."

### The mock feed (single source of truth)

`MarketDataService` (`data/market/market_data_service.dart`) is a singleton with one
broadcast `Stream<PriceTick>`. A `Timer.periodic` loop (default 100ms) does a random
walk on each of the 10 stocks with a per-stock update probability, which produces
~5 ticks/sec/stock ≈ 50+ ticks/sec overall - every other feature (watchlist rows,
holdings P&L, the order ticket's live LTP) reads from this same stream. Tick rate is
configurable at runtime from the Live Market screen's speedometer icon (debug control),
or by editing the `tickIntervalMs` / `updateProbabilityPerStock` constants.

### Keeping the UI smooth under load

Every list row (`PriceFlashCell`, `HoldingRow`) uses `BlocSelector` keyed by symbol,
e.g.:

```dart
BlocSelector<MarketBloc, MarketState, PriceTick?>(
  selector: (state) => state.prices[symbol],
  builder: (context, tick) => ...,
)
```

`MarketBloc` emits a new state on *every single tick from any stock*, but a row only
rebuilds when the tick for **its own** symbol changes - unaffected rows don't rebuild.
Rows are also keyed by symbol (not list index), so drag-reordering a watchlist can
never leave a stale price bound to the wrong row.

Holdings sorting follows the same idea one level up: the sorted `orderedSymbols` list
in `HoldingsState` is only replaced with a new `List` instance when the rank order
actually changes (see `HoldingsBloc._recompute`), so the `ListView` doesn't rebuild on
every tick - only when a row genuinely crosses another.

## Feature coverage checklist

**1. Watchlist** - multiple watchlists (create/rename/delete), stock picker over the
10 stocks, drag-to-reorder (`ReorderableListView`, symbol-keyed), swipe-to-remove,
per-row live price, persisted to Hive, empty state, tap-to-trade.

**2. Live Prices** - all 10 stocks, LTP/change/change% + green/red flash on update,
continuous mock feed, configurable tick rate, only affected cells rebuild, smooth
under a 50+ ticks/sec stress setting, `IndexedStack` keeps the feed running so prices
are never stale when you navigate away and back.

**3. Buy/Sell Ticket** - pre-filled from Watchlist/Holdings taps, live LTP + live
order value while the form is open, balance check (buy) / held-qty check (sell),
inline validation errors, integer-only quantity (blocks fractional/negative/zero),
execution price snapshotted at submit time, wallet + holdings + order history all
persisted, confirmation screen.

**4. Holdings** - qty/avg cost/LTP/current value/P&L (₹ and %) per row, live updates,
sortable (P&L desc default / symbol / value) with stable re-ordering, aggregate
summary derived from the same data the rows show (always internally consistent),
tap-to-trade, empty state, sell-to-zero removes the holding, persisted.

## Suggested commit order

This mirrors how the project was actually built and is a reasonable order to commit in:

1. `chore: project init` - pubspec, gitignore, folder structure
2. `feat: domain models + money utils`
3. `feat: mock market data service`
4. `feat: hive-backed repositories`
5. `feat: market bloc + live prices screen`
6. `feat: watchlist bloc (crud, add/remove/reorder)`
7. `feat: watchlist screens (list, detail, stock picker)`
8. `feat: order ticket bloc (validation + submit)`
9. `feat: order ticket screen + confirmation`
10. `feat: holdings bloc (live P&L, stable sort)`
11. `feat: holdings screen (summary, sortable list)`
12. `feat: app shell - providers, bottom nav`
13. `docs: README`
14. `test: add unit/widget tests` (see Testing below)
15. `chore: record + attach Loom walkthrough`

## Testing

Not included by default to keep the initial drop focused, but the architecture is
built for it: `MarketDataService` is a singleton you can point at a fake stream in
tests, and every Bloc takes its repository via constructor injection, so you can pass
an in-memory fake repository and unit test each Bloc's event → state transitions
directly (money math, avg-cost recompute, buy/sell validation, sort stability) without
touching Hive or Flutter widgets at all.

## Known limitations / things to verify before submitting

- Built without access to a Flutter SDK in this environment, so it has **not been run
  through `flutter analyze` / `flutter run`** - please do that first and fix any
  small issues (package version pins in `pubspec.yaml` may need adjusting to whatever
  Flutter/Dart SDK you have installed).
- Reorder + swipe-to-dismiss are combined on the same watchlist row; test this
  combination on a real device, as gesture arenas between `ReorderableListView` and
  `Dismissible` can occasionally need tuning.
- The stress-test control only changes the running app's tick rate at runtime; if you
  want a truly fixed "debug setting," wire `tickIntervalMs` to a `--dart-define`.
