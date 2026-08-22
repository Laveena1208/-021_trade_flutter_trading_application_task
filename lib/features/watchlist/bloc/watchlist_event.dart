part of 'watchlist_bloc.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => [];
}

class WatchlistSubscriptionRequested extends WatchlistEvent {
  const WatchlistSubscriptionRequested();
}

/// Internal - fired whenever the repository's underlying Hive box changes.
class WatchlistsUpdated extends WatchlistEvent {
  final List<Watchlist> watchlists;
  const WatchlistsUpdated(this.watchlists);
  @override
  List<Object?> get props => [watchlists];
}

class WatchlistCreated extends WatchlistEvent {
  final String name;
  const WatchlistCreated(this.name);
  @override
  List<Object?> get props => [name];
}

class WatchlistRenamed extends WatchlistEvent {
  final String id;
  final String newName;
  const WatchlistRenamed(this.id, this.newName);
  @override
  List<Object?> get props => [id, newName];
}

class WatchlistDeleted extends WatchlistEvent {
  final String id;
  const WatchlistDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class WatchlistStockAdded extends WatchlistEvent {
  final String watchlistId;
  final String symbol;
  const WatchlistStockAdded(this.watchlistId, this.symbol);
  @override
  List<Object?> get props => [watchlistId, symbol];
}

class WatchlistStockRemoved extends WatchlistEvent {
  final String watchlistId;
  final String symbol;
  const WatchlistStockRemoved(this.watchlistId, this.symbol);
  @override
  List<Object?> get props => [watchlistId, symbol];
}

class WatchlistStockReordered extends WatchlistEvent {
  final String watchlistId;
  final int oldIndex;
  final int newIndex;
  const WatchlistStockReordered(this.watchlistId, this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [watchlistId, oldIndex, newIndex];
}
