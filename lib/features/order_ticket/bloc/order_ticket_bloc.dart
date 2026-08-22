import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/market/market_data_service.dart';
import '../../../data/repositories/holdings_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../domain/entities/entities.dart';

part 'order_ticket_event.dart';
part 'order_ticket_state.dart';

/// Feature 3: Buy/Sell ticket.
///
/// One instance is created per screen (scoped to a single symbol). It
/// listens to the live market feed for real-time LTP, the wallet for
/// balance, and holdings for current qty held - so validation is always
/// checked against up-to-the-moment data, not what was true when the
/// screen opened.
class OrderTicketBloc extends Bloc<OrderTicketEvent, OrderTicketState> {
  final WalletRepository walletRepository;
  final HoldingsRepository holdingsRepository;
  final OrderRepository orderRepository;
  final _uuid = const Uuid();

  StreamSubscription<PriceTick>? _priceSub;
  StreamSubscription<int>? _walletSub;
  StreamSubscription<Holding?>? _holdingSub;

  OrderTicketBloc({
    required String symbol,
    required this.walletRepository,
    required this.holdingsRepository,
    required this.orderRepository,
  }) : super(OrderTicketState(symbol: symbol)) {
    on<OrderTicketStarted>(_onStarted);
    on<OrderTicketLtpUpdated>((e, emit) => emit(state.copyWith(ltpPaise: e.ltpPaise)));
    on<OrderTicketWalletUpdated>((e, emit) => emit(state.copyWith(walletBalancePaise: e.balancePaise)));
    on<OrderTicketHeldQtyUpdated>((e, emit) => emit(state.copyWith(heldQty: e.heldQty)));
    on<OrderTicketSideChanged>((e, emit) => emit(state.copyWith(side: e.side, clearError: true)));
    on<OrderTicketQtyChanged>((e, emit) => emit(state.copyWith(qtyText: e.qtyText, clearError: true)));
    on<OrderTicketSubmitted>(_onSubmitted);
  }

  void _onStarted(OrderTicketStarted event, Emitter<OrderTicketState> emit) {
    // Seed immediately so the screen never shows a blank LTP while
    // waiting for the next tick.
    emit(state.copyWith(
      ltpPaise: MarketDataService.instance.currentLtp(state.symbol),
      walletBalancePaise: walletRepository.getBalance(),
      heldQty: holdingsRepository.getBySymbol(state.symbol)?.qty ?? 0,
    ));

    _priceSub = MarketDataService.instance.tickStream
        .where((t) => t.symbol == state.symbol)
        .listen((t) => add(OrderTicketLtpUpdated(t.ltpPaise)));

    _walletSub = walletRepository.watchBalance().listen((b) => add(OrderTicketWalletUpdated(b)));

    _holdingSub = holdingsRepository
        .watchSymbol(state.symbol)
        .listen((h) => add(OrderTicketHeldQtyUpdated(h?.qty ?? 0)));
  }

  Future<void> _onSubmitted(OrderTicketSubmitted event, Emitter<OrderTicketState> emit) async {
    final ltp = state.ltpPaise;
    if (ltp == null) {
      emit(state.copyWith(errorMessage: 'Price not available yet, try again.'));
      return;
    }

    // --- Validation ---
    final qtyText = state.qtyText.trim();
    final parsedQty = int.tryParse(qtyText);
    if (qtyText.isEmpty || parsedQty == null) {
      emit(state.copyWith(errorMessage: 'Enter a quantity.'));
      return;
    }
    if (parsedQty <= 0) {
      emit(state.copyWith(errorMessage: 'Quantity must be a positive whole number.'));
      return;
    }
    // int.tryParse already rejects fractional/decimal input (e.g. "1.5"
    // fails to parse), so fractional quantities are structurally blocked.

    final orderValue = parsedQty * ltp;

    if (state.side == OrderSide.buy) {
      if (orderValue > state.walletBalancePaise) {
        emit(state.copyWith(errorMessage: 'Order value exceeds available balance.'));
        return;
      }
    } else {
      if (parsedQty > state.heldQty) {
        emit(state.copyWith(
            errorMessage: 'You only hold ${state.heldQty} share(s) of ${state.symbol}.'));
        return;
      }
    }

    emit(state.copyWith(submitStatus: OrderTicketSubmitStatus.submitting, clearError: true));

    // Snapshot LTP at the instant of submission - this is the execution
    // price, independent of any tick that arrives mid-await below.
    final executionPrice = ltp;

    if (state.side == OrderSide.buy) {
      final ok = await walletRepository.debit(orderValue);
      if (!ok) {
        emit(state.copyWith(
          submitStatus: OrderTicketSubmitStatus.failure,
          errorMessage: 'Order value exceeds available balance.',
        ));
        return;
      }
      await holdingsRepository.applyBuy(state.symbol, parsedQty, executionPrice);
    } else {
      final ok = await holdingsRepository.applySell(state.symbol, parsedQty);
      if (!ok) {
        emit(state.copyWith(
          submitStatus: OrderTicketSubmitStatus.failure,
          errorMessage: 'Insufficient quantity held.',
        ));
        return;
      }
      await walletRepository.credit(orderValue);
    }

    final order = TradeOrder(
      id: _uuid.v4(),
      symbol: state.symbol,
      side: state.side,
      qty: parsedQty,
      priceAtExecutionPaise: executionPrice,
      orderValuePaise: orderValue,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    await orderRepository.add(order);

    emit(state.copyWith(submitStatus: OrderTicketSubmitStatus.success, lastOrder: order));
  }

  @override
  Future<void> close() {
    _priceSub?.cancel();
    _walletSub?.cancel();
    _holdingSub?.cancel();
    return super.close();
  }
}
