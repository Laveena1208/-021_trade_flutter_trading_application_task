import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/watchlist_bloc.dart';
import 'watchlist_detail_screen.dart';

/// Top-level screen: shows all of the user's watchlists.
class WatchlistListScreen extends StatelessWidget {
  const WatchlistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlists')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          if (state.status == WatchlistStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.watchlists.isEmpty) {
            return const _EmptyWatchlistsState();
          }
          return ListView.separated(
            itemCount: state.watchlists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final w = state.watchlists[index];
              return ListTile(
                title: Text(w.name),
                subtitle: Text('${w.symbols.length} stock${w.symbols.length == 1 ? '' : 's'}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') _showRenameDialog(context, w.id, w.name);
                    if (value == 'delete') {
                      context.read<WatchlistBloc>().add(WatchlistDeleted(w.id));
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WatchlistDetailScreen(watchlistId: w.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final bloc = context.read<WatchlistBloc>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Watchlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Banking Stocks'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              bloc.add(WatchlistCreated(controller.text));
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName) {
    final bloc = context.read<WatchlistBloc>();
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Watchlist'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              bloc.add(WatchlistRenamed(id, controller.text));
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWatchlistsState extends StatelessWidget {
  const _EmptyWatchlistsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No watchlists yet'),
          const SizedBox(height: 4),
          Text('Tap + to create one', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
