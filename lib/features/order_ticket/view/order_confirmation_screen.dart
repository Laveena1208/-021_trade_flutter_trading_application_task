import 'package:flutter/material.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/entities.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final TradeOrder order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 72, color: isBuy ? Colors.green.shade700 : Colors.red.shade700),
              const SizedBox(height: 16),
              Text(
                '${isBuy ? 'Bought' : 'Sold'} ${order.qty} × ${order.symbol}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('at ${Money.format(order.priceAtExecutionPaise)} per share'),
              const SizedBox(height: 4),
              Text('Total: ${Money.format(order.orderValuePaise)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
