import 'package:equatable/equatable.dart';

enum TickDirection { up, down, flat }

enum OrderSide { buy, sell }

/// A single price update for one symbol, emitted by the mock market feed.
class PriceTick extends Equatable {
  final String symbol;
  final int ltpPaise;
  final int prevClosePaise;
  final int changeAbsPaise;
  final double changePct;
  final TickDirection direction;
  final DateTime timestamp;

  const PriceTick({
    required this.symbol,
    required this.ltpPaise,
    required this.prevClosePaise,
    required this.changeAbsPaise,
    required this.changePct,
    required this.direction,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [symbol, ltpPaise, prevClosePaise, changeAbsPaise, changePct, direction];
}

/// A user-created watchlist. [symbols] preserves user-defined order.
class Watchlist extends Equatable {
  final String id;
  final String name;
  final List<String> symbols;
  final int createdAtMs;

  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
    required this.createdAtMs,
  });

  Watchlist copyWith({String? name, List<String>? symbols}) => Watchlist(
        id: id,
        name: name ?? this.name,
        symbols: symbols ?? this.symbols,
        createdAtMs: createdAtMs,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'symbols': symbols,
        'createdAtMs': createdAtMs,
      };

  factory Watchlist.fromMap(Map map) => Watchlist(
        id: map['id'] as String,
        name: map['name'] as String,
        symbols: List<String>.from(map['symbols'] as List),
        createdAtMs: map['createdAtMs'] as int,
      );

  @override
  List<Object?> get props => [id, name, symbols, createdAtMs];
}

/// A completed simulated order (buy or sell), executed at LTP at submit time.
class TradeOrder extends Equatable {
  final String id;
  final String symbol;
  final OrderSide side;
  final int qty;
  final int priceAtExecutionPaise;
  final int orderValuePaise;
  final int timestampMs;

  const TradeOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.qty,
    required this.priceAtExecutionPaise,
    required this.orderValuePaise,
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'qty': qty,
        'priceAtExecutionPaise': priceAtExecutionPaise,
        'orderValuePaise': orderValuePaise,
        'timestampMs': timestampMs,
      };

  factory TradeOrder.fromMap(Map map) => TradeOrder(
        id: map['id'] as String,
        symbol: map['symbol'] as String,
        side: OrderSide.values.firstWhere((s) => s.name == map['side']),
        qty: map['qty'] as int,
        priceAtExecutionPaise: map['priceAtExecutionPaise'] as int,
        orderValuePaise: map['orderValuePaise'] as int,
        timestampMs: map['timestampMs'] as int,
      );

  @override
  List<Object?> get props =>
      [id, symbol, side, qty, priceAtExecutionPaise, orderValuePaise, timestampMs];
}

/// A currently-held position. Removed entirely (not zero-qty) once sold out.
class Holding extends Equatable {
  final String symbol;
  final int qty;
  final int avgCostPaise;

  const Holding({
    required this.symbol,
    required this.qty,
    required this.avgCostPaise,
  });

  Holding copyWith({int? qty, int? avgCostPaise}) => Holding(
        symbol: symbol,
        qty: qty ?? this.qty,
        avgCostPaise: avgCostPaise ?? this.avgCostPaise,
      );

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'qty': qty,
        'avgCostPaise': avgCostPaise,
      };

  factory Holding.fromMap(Map map) => Holding(
        symbol: map['symbol'] as String,
        qty: map['qty'] as int,
        avgCostPaise: map['avgCostPaise'] as int,
      );

  @override
  List<Object?> get props => [symbol, qty, avgCostPaise];
}
