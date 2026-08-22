import 'package:hive/hive.dart';
import '../../domain/entities/entities.dart';

class OrderRepository {
  static const String boxName = 'orders';
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  List<TradeOrder> getAll() {
    return _box.values
        .map((e) => TradeOrder.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs)); // newest first
  }

  Stream<List<TradeOrder>> watchAll() async* {
    yield getAll();
    yield* _box.watch().map((_) => getAll());
  }

  Future<void> add(TradeOrder order) => _box.put(order.id, order.toMap());
}
