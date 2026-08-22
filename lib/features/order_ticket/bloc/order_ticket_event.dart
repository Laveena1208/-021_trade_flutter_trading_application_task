part of 'order_ticket_bloc.dart';

abstract class OrderTicketEvent extends Equatable {
  const OrderTicketEvent();
  @override
  List<Object?> get props => [];
}

class OrderTicketStarted extends OrderTicketEvent {
  const OrderTicketStarted();
}

class OrderTicketLtpUpdated extends OrderTicketEvent {
  final int ltpPaise;
  const OrderTicketLtpUpdated(this.ltpPaise);
  @override
  List<Object?> get props => [ltpPaise];
}

class OrderTicketWalletUpdated extends OrderTicketEvent {
  final int balancePaise;
  const OrderTicketWalletUpdated(this.balancePaise);
  @override
  List<Object?> get props => [balancePaise];
}

class OrderTicketHeldQtyUpdated extends OrderTicketEvent {
  final int heldQty;
  const OrderTicketHeldQtyUpdated(this.heldQty);
  @override
  List<Object?> get props => [heldQty];
}

class OrderTicketSideChanged extends OrderTicketEvent {
  final OrderSide side;
  const OrderTicketSideChanged(this.side);
  @override
  List<Object?> get props => [side];
}

class OrderTicketQtyChanged extends OrderTicketEvent {
  final String qtyText;
  const OrderTicketQtyChanged(this.qtyText);
  @override
  List<Object?> get props => [qtyText];
}

class OrderTicketSubmitted extends OrderTicketEvent {
  const OrderTicketSubmitted();
}
