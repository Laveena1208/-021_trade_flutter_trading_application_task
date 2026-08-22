import 'package:flutter/material.dart';

import '../../../core/constants/stocks.dart';
import '../../../data/market/market_data_service.dart';
import '../../order_ticket/view/order_ticket_screen.dart';
import '../widgets/price_flash_cell.dart';

/// Feature 2: Live Prices Mimic.
/// A continuously updating market overview for all 10 stocks.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Stress test tick rate',
            onPressed: () => _showTickRateSheet(context),
          ),
        ],
      ),
      // ListView.builder + per-row BlocSelector keeps this smooth even
      // under the 50+ ticks/sec stress scenario, and scrolling doesn't
      // interrupt updates since each row manages its own subscription.
      body: ListView.separated(
        itemCount: kStocks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final symbol = kStocks[index].symbol;
          return PriceFlashCell(
            key: ValueKey(symbol),
            symbol: symbol,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderTicketScreen(symbol: symbol)),
            ),
          );
        },
      ),
    );
  }

  void _showTickRateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final svc = MarketDataService.instance;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Debug: Tick Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Loop interval: ${svc.tickIntervalMs}ms  •  '
                      'Update chance/stock: ${(svc.updateProbabilityPerStock * 100).round()}%'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _rateButton(context, setSheetState, 'Normal (~1/s)', 500, 0.5),
                      _rateButton(context, setSheetState, 'Fast (~5/s)', 100, 0.5),
                      _rateButton(context, setSheetState, 'Stress (~10/s)', 50, 0.5),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rateButton(BuildContext context, void Function(void Function()) setSheetState,
      String label, int intervalMs, double probability) {
    return ElevatedButton(
      onPressed: () {
        MarketDataService.instance.setTickRate(intervalMs: intervalMs, probability: probability);
        setSheetState(() {});
      },
      child: Text(label),
    );
  }
}
