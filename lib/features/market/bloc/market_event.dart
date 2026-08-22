part of 'market_bloc.dart';

abstract class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => [];
}

class MarketStarted extends MarketEvent {
  const MarketStarted();
}

/// Internal - fired for every tick coming off MarketDataService.
class MarketTickReceived extends MarketEvent {
  final PriceTick tick;
  const MarketTickReceived(this.tick);
  @override
  List<Object?> get props => [tick];
}
