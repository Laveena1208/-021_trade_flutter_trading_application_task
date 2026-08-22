import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/stocks.dart';
import '../../market/widgets/price_flash_cell.dart';
import '../../order_ticket/view/order_ticket_screen.dart';
import '../bloc/watchlist_bloc.dart';
import '../widgets/stock_picker_sheet.dart';

/// Feature 1: a single watchlist - reorderable stock rows with live prices.
class WatchlistDetailScreen extends StatelessWidget {
  final String watchlistId;

  const WatchlistDetailScreen({super.key, required this.watchlistId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, state) {
        final watchlist = state.byId(watchlistId);
        if (watchlist == null) {
          // Deleted (e.g. from another screen) while this screen was open.
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This watchlist was deleted.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(watchlist.name)),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final symbol = await StockPickerSheet.show(context, alreadyAdded: watchlist.symbols);
              if (symbol != null && context.mounted) {
                context.read<WatchlistBloc>().add(WatchlistStockAdded(watchlistId, symbol));
              }
            },
            child: const Icon(Icons.add),
          ),
          body: watchlist.symbols.isEmpty
              ? const _EmptyWatchlistState()
              : ReorderableListView.builder(
                  itemCount: watchlist.symbols.length,
                  onReorder: (oldIndex, newIndex) {
                    context
                        .read<WatchlistBloc>()
                        .add(WatchlistStockReordered(watchlistId, oldIndex, newIndex));
                  },
                  itemBuilder: (context, index) {
                    final symbol = watchlist.symbols[index];
                    // Keyed by symbol (not index!) so live price bindings
                    // never point at the wrong row after a drag-reorder.
                    // The ReorderableListView expects the direct child to have
                    // a stable Key identifying the item. Use the symbol as the
                    // canonical key. Avoid adding another conflicting key to the
                    // inner PriceFlashCell.
                    // Use a simple keyed PriceFlashCell with an explicit delete
                    // button (no Dismissible). This avoids gesture conflicts
                    // between swipe-to-dismiss and drag-to-reorder on some
                    // platforms/devices. The ReorderableListView requires the
                    // returned widget to have a stable Key.
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(symbol),
                      index: index,
                      child: PriceFlashCell(
                        symbol: symbol,
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Icon(Icons.drag_indicator),
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrderTicketScreen(symbol: symbol)),
                        ),
                        onDelete: () => context.read<WatchlistBloc>().add(WatchlistStockRemoved(watchlistId, symbol)),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyWatchlistState extends StatelessWidget {
  const _EmptyWatchlistState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No stocks in this watchlist'),
          const SizedBox(height: 4),
          Text('Tap + to add from the ${kStocks.length} available stocks',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
