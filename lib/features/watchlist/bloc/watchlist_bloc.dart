import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/watchlist_repository.dart';
import '../../../domain/entities/entities.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

/// Owns all watchlist CRUD + reordering, backed by [WatchlistRepository]
/// (Hive). The Bloc subscribes to the repository's reactive stream, so
/// persisted state and in-memory Bloc state can never drift apart, and
/// restarts restore automatically (the repository re-reads Hive on init).
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistRepository repository;
  final _uuid = const Uuid();
  StreamSubscription<List<Watchlist>>? _sub;

  WatchlistBloc({required this.repository}) : super(const WatchlistState()) {
    on<WatchlistSubscriptionRequested>(_onSubscriptionRequested);
    on<WatchlistsUpdated>(_onUpdated);
    on<WatchlistCreated>(_onCreated);
    on<WatchlistRenamed>(_onRenamed);
    on<WatchlistDeleted>(_onDeleted);
    on<WatchlistStockAdded>(_onStockAdded);
    on<WatchlistStockRemoved>(_onStockRemoved);
    on<WatchlistStockReordered>(_onStockReordered);
  }

  Future<void> _onSubscriptionRequested(
      WatchlistSubscriptionRequested event, Emitter<WatchlistState> emit) async {
    emit(state.copyWith(status: WatchlistStatus.loading));
    await _sub?.cancel();
    _sub = repository.watchAll().listen((lists) => add(WatchlistsUpdated(lists)));
  }

  void _onUpdated(WatchlistsUpdated event, Emitter<WatchlistState> emit) {
    emit(state.copyWith(status: WatchlistStatus.ready, watchlists: event.watchlists));
  }

  Future<void> _onCreated(WatchlistCreated event, Emitter<WatchlistState> emit) async {
    final w = Watchlist(
      id: _uuid.v4(),
      name: event.name.trim().isEmpty ? 'Untitled Watchlist' : event.name.trim(),
      symbols: const [],
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await repository.upsert(w);
  }

  Future<void> _onRenamed(WatchlistRenamed event, Emitter<WatchlistState> emit) async {
    final existing = state.byId(event.id);
    if (existing == null) return;
    await repository.upsert(existing.copyWith(name: event.newName.trim()));
  }

  Future<void> _onDeleted(WatchlistDeleted event, Emitter<WatchlistState> emit) async {
    await repository.delete(event.id);
  }

  Future<void> _onStockAdded(WatchlistStockAdded event, Emitter<WatchlistState> emit) async {
    final existing = state.byId(event.watchlistId);
    if (existing == null) return;
    if (existing.symbols.contains(event.symbol)) return; // no duplicates
    final updated = [...existing.symbols, event.symbol];
    await repository.upsert(existing.copyWith(symbols: updated));
  }

  Future<void> _onStockRemoved(WatchlistStockRemoved event, Emitter<WatchlistState> emit) async {
    final existing = state.byId(event.watchlistId);
    if (existing == null) return;
    final updated = existing.symbols.where((s) => s != event.symbol).toList();
    await repository.upsert(existing.copyWith(symbols: updated));
  }

  Future<void> _onStockReordered(
      WatchlistStockReordered event, Emitter<WatchlistState> emit) async {
    final existing = state.byId(event.watchlistId);
    if (existing == null) return;
    final symbols = List<String>.from(existing.symbols);
    var newIndex = event.newIndex;
    // Standard ReorderableListView adjustment: removing the item first
    // shifts indices below it up by one.
    if (event.oldIndex < newIndex) newIndex -= 1;
    final symbol = symbols.removeAt(event.oldIndex);
    symbols.insert(newIndex, symbol);
    // Because rows are keyed by symbol (not index) in the UI, each row's
    // live price binding follows its symbol wherever it lands - no stale
    // ticks under the wrong row after reorder.
    await repository.upsert(existing.copyWith(symbols: symbols));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
