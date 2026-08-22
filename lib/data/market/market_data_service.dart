import 'dart:async';
import 'dart:math';

import '../../core/constants/stocks.dart';
import '../../domain/entities/entities.dart';

/// The single source of price data for the entire app.
///
/// Every feature (Live Prices, Watchlist, Order Ticket, Holdings) reads
/// from [tickStream] / [currentLtp]. Nothing else in the app invents
/// its own prices.
///
/// Tick rate is configurable via [tickIntervalMs] (how often the internal
/// loop runs) and [updateProbabilityPerStock] (chance any given stock
/// updates on a loop iteration). Defaults produce ~5 ticks/sec/stock
/// = ~50 ticks/sec overall across the 10 stocks, matching the stress
/// scenario in the assignment brief.
class MarketDataService {
  MarketDataService._internal();
  static final MarketDataService instance = MarketDataService._internal();

  final StreamController<PriceTick> _controller =
      StreamController<PriceTick>.broadcast();

  /// Broadcast stream of individual price ticks (one stock per event).
  Stream<PriceTick> get tickStream => _controller.stream;

  final Map<String, int> _ltp = {};
  final Map<String, int> _prevClose = {};
  Timer? _timer;
  final Random _rand = Random();
  bool _started = false;

  /// How often the internal update loop runs. Lower = more responsive
  /// but more CPU. Change this constant (or call [setTickRate]) to
  /// stress-test the UI.
  int tickIntervalMs = 100;

  /// Probability [0.0-1.0] that any single stock updates on each loop
  /// iteration. At 100ms interval, 0.5 ≈ 5 ticks/sec/stock.
  double updateProbabilityPerStock = 0.5;

  void start() {
    if (_started) return;
    _started = true;
    for (final s in kStocks) {
      _ltp[s.symbol] = s.basePricePaise;
      _prevClose[s.symbol] = s.basePricePaise;
    }
    _scheduleLoop();
  }

  void _scheduleLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: tickIntervalMs), (_) => _tick());
  }

  /// Change tick rate at runtime (used by the debug stress-test control).
  void setTickRate({int? intervalMs, double? probability}) {
    if (intervalMs != null) tickIntervalMs = intervalMs;
    if (probability != null) updateProbabilityPerStock = probability;
    if (_started) _scheduleLoop();
  }

  void _tick() {
    for (final s in kStocks) {
      if (_rand.nextDouble() > updateProbabilityPerStock) continue;

      final current = _ltp[s.symbol]!;
      // Random walk: up to +/- 0.5% of current price per tick.
      final maxDeltaPaise = max(1, (current * 0.005).round());
      final delta = _rand.nextInt(maxDeltaPaise * 2 + 1) - maxDeltaPaise;
      int next = current + delta;
      if (next < 100) next = 100; // floor at ₹1.00 so prices never hit zero/negative

      _ltp[s.symbol] = next;
      final prevClose = _prevClose[s.symbol]!;
      final changeAbs = next - prevClose;
      final changePct = prevClose == 0 ? 0.0 : (changeAbs / prevClose) * 100.0;

      _controller.add(PriceTick(
        symbol: s.symbol,
        ltpPaise: next,
        prevClosePaise: prevClose,
        changeAbsPaise: changeAbs,
        changePct: changePct,
        direction: delta > 0
            ? TickDirection.up
            : (delta < 0 ? TickDirection.down : TickDirection.flat),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Synchronous read of the current LTP for a symbol - used when a
  /// screen needs an immediate value before the next tick arrives
  /// (e.g. opening the Buy/Sell ticket pre-filled).
  int currentLtp(String symbol) => _ltp[symbol] ?? stockBySymbol(symbol).basePricePaise;

  int prevClose(String symbol) =>
      _prevClose[symbol] ?? stockBySymbol(symbol).basePricePaise;

  void dispose() {
    _timer?.cancel();
    _controller.close();
    _started = false;
  }
}
