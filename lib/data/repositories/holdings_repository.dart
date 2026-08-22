import 'package:hive/hive.dart';
import '../../domain/entities/entities.dart';

class HoldingsRepository {
  static const String boxName = 'holdings';
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  List<Holding> getAll() => _box.values
      .map((e) => Holding.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  Holding? getBySymbol(String symbol) {
    final raw = _box.get(symbol);
    if (raw == null) return null;
    return Holding.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Stream<List<Holding>> watchAll() async* {
    yield getAll();
    yield* _box.watch().map((_) => getAll());
  }

  Stream<Holding?> watchSymbol(String symbol) async* {
    yield getBySymbol(symbol);
    yield* _box.watch(key: symbol).map((_) => getBySymbol(symbol));
  }

  /// Buy: creates the holding or recomputes weighted-average cost.
  Future<void> applyBuy(String symbol, int qty, int priceAtExecutionPaise) async {
    final existing = getBySymbol(symbol);
    if (existing == null) {
      await _box.put(symbol, Holding(
        symbol: symbol,
        qty: qty,
        avgCostPaise: priceAtExecutionPaise,
      ).toMap());
      return;
    }
    final newQty = existing.qty + qty;
    // Weighted average cost, integer-safe: round-to-nearest paise.
    final totalCost = (existing.avgCostPaise * existing.qty) + (priceAtExecutionPaise * qty);
    final newAvgCost = (totalCost / newQty).round();
    await _box.put(symbol, existing.copyWith(qty: newQty, avgCostPaise: newAvgCost).toMap());
  }

  /// Sell: reduces qty; removes the holding entirely if it hits zero.
  /// Returns false if [qty] exceeds what's held (caller should validate
  /// before calling, but this is a safety net).
  Future<bool> applySell(String symbol, int qty) async {
    final existing = getBySymbol(symbol);
    if (existing == null || qty > existing.qty) return false;
    final remaining = existing.qty - qty;
    if (remaining == 0) {
      await _box.delete(symbol);
    } else {
      await _box.put(symbol, existing.copyWith(qty: remaining).toMap());
    }
    return true;
  }
}
