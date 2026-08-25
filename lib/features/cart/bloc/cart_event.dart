part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => const [];
}

class CartLoadRequested extends CartEvent {
  const CartLoadRequested();
}

class CartItemAdded extends CartEvent {
  final String itemableType;
  final int itemableId;
  final int qty;
  final String? notes;
  const CartItemAdded({
    required this.itemableType,
    required this.itemableId,
    required this.qty,
    this.notes,
  });
  @override
  List<Object?> get props => [itemableType, itemableId, qty, notes];
}

class CartItemUpdated extends CartEvent {
  final int itemId;
  final int qty;
  const CartItemUpdated(this.itemId, this.qty);
  @override
  List<Object?> get props => [itemId, qty];
}

class CartItemRemoved extends CartEvent {
  final int itemId;
  const CartItemRemoved(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CartCouponApplied extends CartEvent {
  final String code;
  const CartCouponApplied(this.code);
  @override
  List<Object?> get props => [code];
}

class CartCouponRemoved extends CartEvent {
  const CartCouponRemoved();
}

class CartShippingOptionsRequested extends CartEvent {
  final String city;
  final String courier;
  const CartShippingOptionsRequested({
    required this.city,
    this.courier = 'jne',
  });
  @override
  List<Object?> get props => [city, courier];
}
