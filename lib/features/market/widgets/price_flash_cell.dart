import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/stocks.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/market_bloc.dart';

/// One row in the Live Prices list.
///
/// This widget uses BlocSelector so it ONLY rebuilds when its own
/// symbol's PriceTick changes - other rows ticking does not touch it.
/// This is what satisfies "only the affected cells visibly change".
class PriceFlashCell extends StatefulWidget {
  final String symbol;
  final VoidCallback? onTap;
  final Widget? leading;
  final VoidCallback? onDelete;

  const PriceFlashCell({super.key, required this.symbol, this.onTap, this.leading, this.onDelete});

  @override
  State<PriceFlashCell> createState() => _PriceFlashCellState();
}

class _PriceFlashCellState extends State<PriceFlashCell> {
  Color _flashColor = Colors.transparent;
  int? _lastLtp;

  void _handleTick(PriceTick? tick) {
    if (tick == null) return;
    if (_lastLtp != null && tick.ltpPaise != _lastLtp) {
      setState(() {
        _flashColor = tick.direction == TickDirection.up
            ? Colors.green.withOpacity(0.25)
            : Colors.red.withOpacity(0.25);
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _flashColor = Colors.transparent);
      });
    }
    _lastLtp = tick.ltpPaise;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketBloc, MarketState, PriceTick?>(
      selector: (state) => state.prices[widget.symbol],
      builder: (context, tick) {
        // Fire the flash side-effect as this cell's own tick arrives.
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleTick(tick));

        final name = stockBySymbol(widget.symbol).name;
        final isUp = (tick?.changeAbsPaise ?? 0) >= 0;
        final color = tick == null
            ? Colors.grey
            : (isUp ? Colors.green.shade700 : Colors.red.shade700);

        // Only flash the numeric price itself (not the change %).
        // Constrain the ListTile height to avoid small overflows when the
        // trailing price area briefly grows during the flash animation.
        return SizedBox(
          height: 64,
          child: ListTile(
            leading: widget.leading,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: widget.onTap,
            title: Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated background only around the numeric price text itself.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: _flashColor, borderRadius: BorderRadius.circular(4)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      tick == null ? '—' : Money.format(tick.ltpPaise),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // The change/percent text does not flash; it is separate.
                Text(
                  tick == null
                      ? ''
                      : '${Money.formatSignedChange(tick.changeAbsPaise)} (${Money.formatPct(tick.changePct)})',
                  style: TextStyle(color: color, fontSize: 12),
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    padding: const EdgeInsets.all(8),
                    onPressed: widget.onDelete,
                    tooltip: 'Remove',
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
