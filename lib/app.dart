import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/holdings_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/watchlist_repository.dart';
import 'features/holdings/bloc/holdings_bloc.dart';
import 'features/holdings/view/holdings_screen.dart';
import 'features/market/bloc/market_bloc.dart';
import 'features/market/view/market_screen.dart';
import 'features/watchlist/bloc/watchlist_bloc.dart';
import 'features/watchlist/view/watchlist_list_screen.dart';

class TradingApp extends StatelessWidget {
  final WatchlistRepository watchlistRepository;
  final WalletRepository walletRepository;
  final HoldingsRepository holdingsRepository;
  final OrderRepository orderRepository;

  const TradingApp({
    super.key,
    required this.watchlistRepository,
    required this.walletRepository,
    required this.holdingsRepository,
    required this.orderRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: watchlistRepository),
        RepositoryProvider.value(value: walletRepository),
        RepositoryProvider.value(value: holdingsRepository),
        RepositoryProvider.value(value: orderRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // Root-level Blocs, created once and shared across the whole
          // app so every screen sees the same live prices / holdings
          // state without re-fetching.
          BlocProvider(create: (_) => MarketBloc()..add(const MarketStarted())),
          BlocProvider(
            create: (context) => WatchlistBloc(repository: watchlistRepository)
              ..add(const WatchlistSubscriptionRequested()),
          ),
          BlocProvider(
            create: (context) => HoldingsBloc(repository: holdingsRepository)
              ..add(const HoldingsSubscriptionRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'Trading App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const RootTabScreen(),
        ),
      ),
    );
  }
}

class RootTabScreen extends StatefulWidget {
  const RootTabScreen({super.key});

  @override
  State<RootTabScreen> createState() => _RootTabScreenState();
}

class _RootTabScreenState extends State<RootTabScreen> {
  int _index = 0;

  static const _screens = [
    MarketScreen(),
    WatchlistListScreen(),
    HoldingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Watchlists'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Holdings'),
        ],
      ),
    );
  }
}
