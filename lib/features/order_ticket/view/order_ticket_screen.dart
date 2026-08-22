import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/stocks.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/holdings_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/order_ticket_bloc.dart';
import 'order_confirmation_screen.dart';

/// Feature 3: Buy/Sell ticket. Always opened pre-filled with a symbol,
/// e.g. from a Watchlist row or a Holdings row.
class OrderTicketScreen extends StatelessWidget {
  final String symbol;

  const OrderTicketScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderTicketBloc(
        symbol: symbol,
        walletRepository: context.read<WalletRepository>(),
        holdingsRepository: context.read<HoldingsRepository>(),
        orderRepository: context.read<OrderRepository>(),
      )..add(const OrderTicketStarted()),
      child: const _OrderTicketView(),
    );
  }
}

class _OrderTicketView extends StatefulWidget {
  const _OrderTicketView();

  @override
  State<_OrderTicketView> createState() => _OrderTicketViewState();
}

class _OrderTicketViewState extends State<_OrderTicketView> {
  final _qtyController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderTicketBloc, OrderTicketState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == OrderTicketSubmitStatus.success && state.lastOrder != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: state.lastOrder!)),
          );
        }
      },
      builder: (context, state) {
        final stockName = stockBySymbol(state.symbol).name;
        return Scaffold(
          appBar: AppBar(title: Text('${state.symbol} · $stockName')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live LTP', style: TextStyle(color: Colors.grey)),
                        Text(
                          state.ltpPaise == null ? '—' : Money.format(state.ltpPaise!),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<OrderSide>(
                  segments: const [
                    ButtonSegment(value: OrderSide.buy, label: Text('BUY')),
                    ButtonSegment(value: OrderSide.sell, label: Text('SELL')),
                  ],
                  selected: {state.side},
                  onSelectionChanged: (set) =>
                      context.read<OrderTicketBloc>().add(OrderTicketSideChanged(set.first)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => context.read<OrderTicketBloc>().add(OrderTicketQtyChanged(v)),
                ),
                const SizedBox(height: 8),
                Text('Available balance: ${Money.format(state.walletBalancePaise)}',
                    style: const TextStyle(color: Colors.grey)),
                if (state.side == OrderSide.sell)
                  Text('Held quantity: ${state.heldQty}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order value'),
                        Text(
                          Money.format(state.orderValuePaise),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.submitStatus == OrderTicketSubmitStatus.submitting
                      ? null
                      : () => context.read<OrderTicketBloc>().add(const OrderTicketSubmitted()),
                  style: FilledButton.styleFrom(
                    backgroundColor: state.side == OrderSide.buy ? Colors.green.shade700 : Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.submitStatus == OrderTicketSubmitStatus.submitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('${state.side == OrderSide.buy ? 'BUY' : 'SELL'} ${state.symbol}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
