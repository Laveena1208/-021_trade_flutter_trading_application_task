part of 'order_ticket_bloc.dart';

enum OrderTicketSubmitStatus { idle, submitting, success, failure }

class OrderTicketState extends Equatable {
  final String symbol;
  final OrderSide side;
  final String qtyText;
  final int? ltpPaise;
  final int walletBalancePaise;
  final int heldQty;
  final String? errorMessage;
  final OrderTicketSubmitStatus submitStatus;
  final TradeOrder? lastOrder;

  const OrderTicketState({
    required this.symbol,
    this.side = OrderSide.buy,
    this.qtyText = '',
    this.ltpPaise,
    this.walletBalancePaise = 0,
    this.heldQty = 0,
    this.errorMessage,
    this.submitStatus = OrderTicketSubmitStatus.idle,
    this.lastOrder,
  });

  int get qty => int.tryParse(qtyText) ?? 0;

  int get orderValuePaise => ltpPaise == null ? 0 : qty * ltpPaise!;

  OrderTicketState copyWith({
    OrderSide? side,
    String? qtyText,
    int? ltpPaise,
    int? walletBalancePaise,
    int? heldQty,
    String? errorMessage,
    bool clearError = false,
    OrderTicketSubmitStatus? submitStatus,
    TradeOrder? lastOrder,
  }) =>
      OrderTicketState(
        symbol: symbol,
        side: side ?? this.side,
        qtyText: qtyText ?? this.qtyText,
        ltpPaise: ltpPaise ?? this.ltpPaise,
        walletBalancePaise: walletBalancePaise ?? this.walletBalancePaise,
        heldQty: heldQty ?? this.heldQty,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        submitStatus: submitStatus ?? this.submitStatus,
        lastOrder: lastOrder ?? this.lastOrder,
      );

  @override
  List<Object?> get props => [
        symbol,
        side,
        qtyText,
        ltpPaise,
        walletBalancePaise,
        heldQty,
        errorMessage,
        submitStatus,
        lastOrder,
      ];
}
