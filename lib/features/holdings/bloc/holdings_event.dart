part of 'holdings_bloc.dart';

abstract class HoldingsEvent extends Equatable {
  const HoldingsEvent();
  @override
  List<Object?> get props => [];
}

class HoldingsSubscriptionRequested extends HoldingsEvent {
  const HoldingsSubscriptionRequested();
}

class HoldingsListUpdated extends HoldingsEvent {
  final List<Holding> holdings;
  const HoldingsListUpdated(this.holdings);
  @override
  List<Object?> get props => [holdings];
}

class HoldingsTickReceived extends HoldingsEvent {
  final PriceTick tick;
  const HoldingsTickReceived(this.tick);
  @override
  List<Object?> get props => [tick];
}

enum HoldingsSortMode { pnlDesc, symbolAsc, valueDesc }

class HoldingsSortChanged extends HoldingsEvent {
  final HoldingsSortMode mode;
  const HoldingsSortChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}
