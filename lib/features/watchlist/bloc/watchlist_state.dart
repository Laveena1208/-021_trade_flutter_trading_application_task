part of 'watchlist_bloc.dart';

enum WatchlistStatus { initial, loading, ready }

class WatchlistState extends Equatable {
  final WatchlistStatus status;
  final List<Watchlist> watchlists;

  const WatchlistState({
    this.status = WatchlistStatus.initial,
    this.watchlists = const [],
  });

  WatchlistState copyWith({WatchlistStatus? status, List<Watchlist>? watchlists}) =>
      WatchlistState(
        status: status ?? this.status,
        watchlists: watchlists ?? this.watchlists,
      );

  Watchlist? byId(String id) {
    for (final w in watchlists) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  List<Object?> get props => [status, watchlists];
}
