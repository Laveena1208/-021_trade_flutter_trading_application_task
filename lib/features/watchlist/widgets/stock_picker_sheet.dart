import 'package:flutter/material.dart';
import '../../../core/constants/stocks.dart';

/// Bottom sheet showing all 10 available stocks, disabling ones already
/// in the target watchlist. Returns the chosen symbol via Navigator.pop.
class StockPickerSheet extends StatelessWidget {
  final List<String> alreadyAdded;

  const StockPickerSheet({super.key, required this.alreadyAdded});

  static Future<String?> show(BuildContext context, {required List<String> alreadyAdded}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StockPickerSheet(alreadyAdded: alreadyAdded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add a stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: kStocks.length,
                itemBuilder: (context, index) {
                  final s = kStocks[index];
                  final disabled = alreadyAdded.contains(s.symbol);
                  return ListTile(
                    enabled: !disabled,
                    title: Text(s.symbol),
                    subtitle: Text(s.name),
                    trailing: disabled ? const Text('Added', style: TextStyle(color: Colors.grey)) : null,
                    onTap: disabled ? null : () => Navigator.pop(context, s.symbol),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
