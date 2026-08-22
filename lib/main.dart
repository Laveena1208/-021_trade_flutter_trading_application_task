import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/repositories/holdings_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/watchlist_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Repositories are opened once here and injected down via
  // MultiRepositoryProvider - every Bloc reads from the same instances,
  // and every Hive box is open before the first frame so persisted data
  // (watchlists, wallet, holdings, orders) is available immediately on
  // app restart with no loading flicker.
  final watchlistRepository = WatchlistRepository();
  final walletRepository = WalletRepository();
  final holdingsRepository = HoldingsRepository();
  final orderRepository = OrderRepository();

  await Future.wait([
    watchlistRepository.init(),
    walletRepository.init(),
    holdingsRepository.init(),
    orderRepository.init(),
  ]);

  runApp(TradingApp(
    watchlistRepository: watchlistRepository,
    walletRepository: walletRepository,
    holdingsRepository: holdingsRepository,
    orderRepository: orderRepository,
  ));
}
