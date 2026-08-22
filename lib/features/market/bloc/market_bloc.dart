import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/market/market_data_service.dart';
import '../../../domain/entities/entities.dart';

part 'market_event.dart';
part 'market_state.dart';

/// Single Bloc, provided once at the app root, that mirrors
/// MarketDataService's tick stream into Bloc state.
///
/// UI widgets should almost never listen to the whole state - instead use
///   BlocSelector<MarketBloc, MarketState, PriceTick?>(
///     selector: (s) => s.prices[symbol],
///     builder: (context, tick) => ...,
///   )
/// so a row only rebuilds when THAT symbol's tick changes, even though
/// this Bloc emits a new state on every single tick from any stock.
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  StreamSubscription<PriceTick>? _sub;

  MarketBloc() : super(const MarketState()) {
    on<MarketStarted>(_onStarted);
    on<MarketTickReceived>(_onTick);
  }

  void _onStarted(MarketStarted event, Emitter<MarketState> emit) {
    MarketDataService.instance.start();
    _sub?.cancel();
    _sub = MarketDataService.instance.tickStream.listen((tick) {
      add(MarketTickReceived(tick));
    });
  }

  void _onTick(MarketTickReceived event, Emitter<MarketState> emit) {
    final updated = Map<String, PriceTick>.from(state.prices);
    updated[event.tick.symbol] = event.tick;
    emit(state.copyWith(prices: updated));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
