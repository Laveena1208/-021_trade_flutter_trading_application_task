import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/money.dart';
import '../../order_ticket/view/order_ticket_screen.dart';
import '../bloc/holdings_bloc.dart';
import '../widgets/holding_row.dart';

/// Feature 4: Holdings / portfolio overview.
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          BlocBuilder<HoldingsBloc, HoldingsState>(
            buildWhen: (prev, curr) => prev.sortMode != curr.sortMode,
            builder: (context, state) => PopupMenuButton<HoldingsSortMode>(
              icon: const Icon(Icons.sort),
              initialValue: state.sortMode,
              onSelected: (mode) => context.read<HoldingsBloc>().add(HoldingsSortChanged(mode)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: HoldingsSortMode.pnlDesc, child: Text('Sort: P&L (high to low)')),
                PopupMenuItem(value: HoldingsSortMode.symbolAsc, child: Text('Sort: Symbol (A-Z)')),
                PopupMenuItem(value: HoldingsSortMode.valueDesc, child: Text('Sort: Current value')),
              ],
            ),
          ),
        ],
      ),
      body: BlocBuilder<HoldingsBloc, HoldingsState>(
        // Only rebuilds the outer scaffold (summary + list shape) when
        // the SET of holdings or their order changes - not on every tick,
        // since individual rows read their own data via HoldingRow's
        // BlocSelector instead of through this builder.
        buildWhen: (prev, curr) => prev.orderedSymbols != curr.orderedSymbols,
        builder: (context, state) {
          if (state.orderedSymbols.isEmpty) {
            return const _EmptyHoldingsState();
          }
          return Column(
            children: [
              _AggregateSummary(),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: state.orderedSymbols.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final symbol = state.orderedSymbols[index];
                    return HoldingRow(
                      key: ValueKey(symbol),
                      symbol: symbol,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderTicketScreen(symbol: symbol)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AggregateSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoldingsBloc, HoldingsState>(
      builder: (context, state) {
        // Always derived live from the same views map the rows read from,
        // so the summary is guaranteed to equal the sum of the rows.
        final isProfit = state.totalPnlPaise >= 0;
        final color = isProfit ? Colors.green.shade700 : Colors.red.shade700;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryColumn('Invested', Money.format(state.totalInvestedPaise)),
              _summaryColumn('Current', Money.format(state.totalCurrentValuePaise)),
              _summaryColumn(
                'P&L',
                '${Money.formatSignedChange(state.totalPnlPaise)}\n(${Money.formatPct(state.totalPnlPct)})',
                color: color,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _EmptyHoldingsState extends StatelessWidget {
  const _EmptyHoldingsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No holdings yet'),
          const SizedBox(height: 4),
          Text('Buy a stock to see it here', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
