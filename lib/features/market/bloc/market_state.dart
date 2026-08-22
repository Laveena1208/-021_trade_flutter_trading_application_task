part of 'market_bloc.dart';

class MarketState extends Equatable {
  /// Latest known tick per symbol. Immutable map replaced on each update
  /// so BlocSelector equality checks are cheap value compares.
  final Map<String, PriceTick> prices;

  const MarketState({this.prices = const {}});

  MarketState copyWith({Map<String, PriceTick>? prices}) =>
      MarketState(prices: prices ?? this.prices);

  @override
  List<Object?> get props => [prices];
}
