part of 'cart_bloc.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final Cart cart;
  final bool mutationInProgress;
  final bool shippingLoading;
  final List<Map<String, dynamic>> shippingOptions;
  final String? lastMessage;
  final String? errorMessage;

  const CartState({
    this.status = CartStatus.initial,
    Cart? cart,
    this.mutationInProgress = false,
    this.shippingLoading = false,
    this.shippingOptions = const [],
    this.lastMessage,
    this.errorMessage,
  }) : cart =
           cart ??
           const Cart(
             id: 0,
             isGuest: false,
             itemCount: 0,
             itemUniqueCount: 0,
             subtotal: 0,
             discount: 0,
             tax: 0,
             shippingCost: 0,
             total: 0,
             currency: 'IDR',
           );

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    bool? mutationInProgress,
    bool? shippingLoading,
    List<Map<String, dynamic>>? shippingOptions,
    String? lastMessage,
    String? errorMessage,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      shippingLoading: shippingLoading ?? this.shippingLoading,
      shippingOptions: shippingOptions ?? this.shippingOptions,
      lastMessage: lastMessage,
      errorMessage: errorMessage,
    );
  }

  int get totalItems => cart.itemCount;

  @override
  List<Object?> get props => [
    status,
    cart.id,
    cart.itemCount,
    cart.total,
    cart.couponCode,
    mutationInProgress,
    shippingLoading,
    shippingOptions.length,
    errorMessage,
  ];
}
