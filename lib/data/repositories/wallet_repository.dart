import 'package:hive/hive.dart';
import '../../core/constants/stocks.dart';

/// Persists the single wallet balance (in paise). All mutations are
/// simple integer add/subtract - no floating point involved anywhere.
class WalletRepository {
  static const String boxName = 'wallet';
  static const String _balanceKey = 'balancePaise';
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    if (!_box.containsKey(_balanceKey)) {
      await _box.put(_balanceKey, kStartingWalletBalancePaise);
    }
  }

  int getBalance() => _box.get(_balanceKey, defaultValue: kStartingWalletBalancePaise) as int;

  Stream<int> watchBalance() async* {
    yield getBalance();
    yield* _box.watch(key: _balanceKey).map((_) => getBalance());
  }

  /// Returns false (and does not mutate) if balance would go negative.
  Future<bool> debit(int paise) async {
    final current = getBalance();
    if (paise > current) return false;
    await _box.put(_balanceKey, current - paise);
    return true;
  }

  Future<void> credit(int paise) async {
    final current = getBalance();
    await _box.put(_balanceKey, current + paise);
  }
}
