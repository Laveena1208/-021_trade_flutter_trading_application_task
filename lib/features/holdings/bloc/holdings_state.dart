part of 'holdings_bloc.dart';

/// A derived, display-ready view of one holding combined with its
/// latest live price. Recomputed whenever either the holding itself or
/// its LTP changes.
class HoldingView extends Equatable {
  final String symbol;
  final int qty;
  final int avgCostPaise;
  final int ltpPaise;

  const HoldingView({
    required this.symbol,
    required this.qty,
    required this.avgCostPaise,
    required this.ltpPaise,
  });

  int get investedPaise => qty * avgCostPaise;
  int get currentValuePaise => qty * ltpPaise;
  int get pnlPaise => currentValuePaise - investedPaise;
  double get pnlPct => investedPaise == 0 ? 0.0 : (pnlPaise / investedPaise) * 100.0;

  @override
  List<Object?> get props => [symbol, qty, avgCostPaise, ltpPaise];
}

class HoldingsState extends Equatable {
  final Map<String, HoldingView> viewsBySymbol;
  final List<String> orderedSymbols; // stable reference unless rank order actually changes
  final HoldingsSortMode sortMode;

  const HoldingsState({
    this.viewsBySymbol = const {},
    this.orderedSymbols = const [],
    this.sortMode = HoldingsSortMode.pnlDesc,
  });

  int get totalInvestedPaise =>
      viewsBySymbol.values.fold(0, (sum, v) => sum + v.investedPaise);
  int get totalCurrentValuePaise =>
      viewsBySymbol.values.fold(0, (sum, v) => sum + v.currentValuePaise);
  int get totalPnlPaise => totalCurrentValuePaise - totalInvestedPaise;
  double get totalPnlPct =>
      totalInvestedPaise == 0 ? 0.0 : (totalPnlPaise / totalInvestedPaise) * 100.0;

  HoldingsState copyWith({
    Map<String, HoldingView>? viewsBySymbol,
    List<String>? orderedSymbols,
    HoldingsSortMode? sortMode,
  }) =>
      HoldingsState(
        viewsBySymbol: viewsBySymbol ?? this.viewsBySymbol,
        orderedSymbols: orderedSymbols ?? this.orderedSymbols,
        sortMode: sortMode ?? this.sortMode,
      );

  @override
  List<Object?> get props => [viewsBySymbol, orderedSymbols, sortMode];
}
