import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/market/market_data_service.dart';
import '../../../data/repositories/holdings_repository.dart';
import '../../../domain/entities/entities.dart';

part 'holdings_event.dart';
part 'holdings_state.dart';

/// Feature 4: Holdings / portfolio.
///
/// Combines persisted [Holding]s (qty, avg cost) with the live market
/// feed to produce per-symbol P&L that updates on every tick, plus a
/// sortable, always-consistent aggregate summary.
///
/// Rows in the UI use BlocSelector keyed by symbol against
/// [HoldingsState.viewsBySymbol] so a tick only rebuilds the row(s) it
/// actually affects. [orderedSymbols] is only replaced with a new list
/// instance when the actual rank order changes, so re-sorting doesn't
/// force a full ListView rebuild on every tick - only when a row
/// genuinely crosses another in the sort.
class HoldingsBloc extends Bloc<HoldingsEvent, HoldingsState> {
  final HoldingsRepository repository;
  StreamSubscription<List<Holding>>? _holdingsSub;
  StreamSubscription<PriceTick>? _tickSub;

  Map<String, Holding> _holdings = {};
  final Map<String, int> _ltp = {};

  HoldingsBloc({required this.repository}) : super(const HoldingsState()) {
    on<HoldingsSubscriptionRequested>(_onSubscriptionRequested);
    on<HoldingsListUpdated>(_onHoldingsUpdated);
    on<HoldingsTickReceived>(_onTick);
    on<HoldingsSortChanged>(_onSortChanged);
  }

  void _onSubscriptionRequested(
      HoldingsSubscriptionRequested event, Emitter<HoldingsState> emit) {
    _holdingsSub?.cancel();
    _holdingsSub = repository.watchAll().listen((list) => add(HoldingsListUpdated(list)));

    _tickSub?.cancel();
    _tickSub = MarketDataService.instance.tickStream.listen((tick) {
      // Only care about ticks for symbols we actually hold.
      if (_holdings.containsKey(tick.symbol)) {
        add(HoldingsTickReceived(tick));
      }
    });
  }

  void _onHoldingsUpdated(HoldingsListUpdated event, Emitter<HoldingsState> emit) {
    _holdings = {for (final h in event.holdings) h.symbol: h};
    // Seed LTP for any newly-held symbol from the feed's current value.
    for (final symbol in _holdings.keys) {
      _ltp.putIfAbsent(symbol, () => MarketDataService.instance.currentLtp(symbol));
    }
    _ltp.removeWhere((symbol, _) => !_holdings.containsKey(symbol));
    _recompute(emit);
  }

  void _onTick(HoldingsTickReceived event, Emitter<HoldingsState> emit) {
    _ltp[event.tick.symbol] = event.tick.ltpPaise;
    _recompute(emit);
  }

  void _onSortChanged(HoldingsSortChanged event, Emitter<HoldingsState> emit) {
    emit(state.copyWith(sortMode: event.mode));
    _recompute(emit, forceReorder: true);
  }

  void _recompute(Emitter<HoldingsState> emit, {bool forceReorder = false}) {
    final views = <String, HoldingView>{};
    for (final h in _holdings.values) {
      views[h.symbol] = HoldingView(
        symbol: h.symbol,
        qty: h.qty,
        avgCostPaise: h.avgCostPaise,
        ltpPaise: _ltp[h.symbol] ?? h.avgCostPaise,
      );
    }

    final newOrder = views.values.toList();
    switch (state.sortMode) {
      case HoldingsSortMode.pnlDesc:
        newOrder.sort((a, b) => b.pnlPaise.compareTo(a.pnlPaise));
        break;
      case HoldingsSortMode.symbolAsc:
        newOrder.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case HoldingsSortMode.valueDesc:
        newOrder.sort((a, b) => b.currentValuePaise.compareTo(a.currentValuePaise));
        break;
    }
    final newSymbolOrder = newOrder.map((v) => v.symbol).toList();

    // Keep the same List instance if the rank order hasn't actually
    // changed - avoids rebuilding the whole ListView on every tick when
    // nothing has crossed.
    final orderUnchanged = !forceReorder &&
        newSymbolOrder.length == state.orderedSymbols.length &&
        _listEquals(newSymbolOrder, state.orderedSymbols);

    emit(state.copyWith(
      viewsBySymbol: views,
      orderedSymbols: orderUnchanged ? state.orderedSymbols : newSymbolOrder,
    ));
  }

  bool _listEquals(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    _holdingsSub?.cancel();
    _tickSub?.cancel();
    return super.close();
  }
}
