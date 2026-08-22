import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/entities.dart';

/// Persists watchlists to Hive as plain Maps (no generated TypeAdapters
/// needed, so `flutter run` works with zero extra codegen steps).
///
/// [watchAll] is reactive: it re-emits whenever the underlying Hive box
/// changes (from this repository or -- in principle -- another isolate),
/// so any Bloc listening to it stays in sync automatically.
class WatchlistRepository {
  static const String boxName = 'watchlists';
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    // Debug print stored entries when running in debug mode to help
    // diagnose persistence issues. This is harmless in production
    // but guarded by kDebugMode to avoid noisy logs.
    // Using try/catch in case box access throws on unexpected data.
    // No debug logging in production; keep init minimal and robust.
    try {
      // access the box to ensure it's open
      _box.isOpen;
    } catch (_) {
      // ignore any init-time read errors here
    }
  }

  List<Watchlist> getAll() {
    final lists = <Watchlist>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        final map = Map<String, dynamic>.from(raw as Map);
        lists.add(Watchlist.fromMap(map));
      } catch (_) {
        // Ignore malformed entries so a single bad value doesn't
        // break restoring all watchlists on startup.
      }
    }
    lists.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    return lists;
  }

  Stream<List<Watchlist>> watchAll() async* {
    yield getAll();
    yield* _box.watch().map((_) => getAll());
  }

  Future<void> upsert(Watchlist w) async {
    await _box.put(w.id, w.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
