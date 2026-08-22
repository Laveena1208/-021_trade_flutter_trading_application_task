import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/money.dart';
import '../bloc/holdings_bloc.dart';

/// One row in Holdings. Uses BlocSelector keyed by symbol so a tick for
/// THIS symbol updates THIS row only - other rows don't rebuild.
class HoldingRow extends StatelessWidget {
  final String symbol;
  final VoidCallback? onTap;

  const HoldingRow({super.key, required this.symbol, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HoldingsBloc, HoldingsState, HoldingView?>(
      selector: (state) => state.viewsBySymbol[symbol],
      builder: (context, view) {
        if (view == null) return const SizedBox.shrink();
        final isProfit = view.pnlPaise >= 0;
        final color = isProfit ? Colors.green.shade700 : Colors.red.shade700;

        return ListTile(
          onTap: onTap,
          title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${view.qty} shares @ avg ${Money.format(view.avgCostPaise)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(view.currentValuePaise),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${Money.formatSignedChange(view.pnlPaise)} (${Money.formatPct(view.pnlPct)})',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
