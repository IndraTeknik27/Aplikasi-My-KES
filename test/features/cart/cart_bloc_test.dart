import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_kes/core/api/api_client.dart';
import 'package:my_kes/features/cart/bloc/cart_bloc.dart';
import 'package:my_kes/features/cart/data/cart_repository.dart';

class _FakeCartRepository extends CartRepository {
  _FakeCartRepository();

  Cart cartToReturn = const Cart(
    id: 1,
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

  Object? errorToThrow;

  @override
  Future<Cart> fetch() async {
    if (errorToThrow != null) throw errorToThrow!;
    return cartToReturn;
  }

  @override
  Future<Cart> addItem({
    required String itemableType,
    required int itemableId,
    required int qty,
    String? notes,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return cartToReturn;
  }

  @override
  Future<Cart> updateItem(int itemId, int qty) async {
    if (errorToThrow != null) throw errorToThrow!;
    return cartToReturn;
  }

  @override
  Future<Cart> removeItem(int itemId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return cartToReturn;
  }

  @override
  Future<Cart> applyCoupon(String code) async {
    if (errorToThrow != null) throw errorToThrow!;
    return cartToReturn;
  }
}

void main() {
  late _FakeCartRepository repo;

  setUp(() {
    repo = _FakeCartRepository();
  });

  CartBloc build() => CartBloc(repository: repo);

  blocTest<CartBloc, CartState>(
    'loads cart successfully',
    build: () {
      repo.cartToReturn = const Cart(
        id: 7,
        isGuest: false,
        customerId: 1,
        couponCode: null,
        itemCount: 3,
        itemUniqueCount: 2,
        subtotal: 300000,
        discount: 0,
        tax: 30000,
        shippingCost: 10000,
        total: 340000,
        currency: 'IDR',
      );
      return build();
    },
    act: (bloc) => bloc.add(const CartLoadRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CartStatus.loading),
      isA<CartState>()
          .having((s) => s.status, 'status', CartStatus.loaded)
          .having((s) => s.cart.total, 'total', 340000)
          .having((s) => s.cart.itemCount, 'itemCount', 3),
    ],
  );

  blocTest<CartBloc, CartState>(
    'emits error state when fetch throws',
    build: () {
      repo.errorToThrow = ApiException(message: 'Network down', statusCode: 0);
      return build();
    },
    act: (bloc) => bloc.add(const CartLoadRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CartStatus.loading),
      isA<CartState>().having((s) => s.status, 'status', CartStatus.error),
    ],
  );

  blocTest<CartBloc, CartState>(
    'addItem updates the cart and emits success message',
    build: () {
      repo.cartToReturn = const Cart(
        id: 1,
        isGuest: false,
        itemCount: 1,
        itemUniqueCount: 1,
        subtotal: 100,
        discount: 0,
        tax: 0,
        shippingCost: 0,
        total: 100,
        currency: 'IDR',
      );
      return build();
    },
    act: (bloc) => bloc.add(
      const CartItemAdded(itemableType: 'product', itemableId: 42, qty: 1),
    ),
    expect: () => [
      isA<CartState>().having((s) => s.mutationInProgress, 'mutating', true),
      isA<CartState>()
          .having((s) => s.mutationInProgress, 'mutating', false)
          .having((s) => s.cart.itemCount, 'itemCount', 1)
          .having((s) => s.lastMessage, 'message', 'Ditambahkan ke keranjang'),
    ],
  );

  blocTest<CartBloc, CartState>(
    'applyCoupon updates coupon code',
    build: () {
      repo.cartToReturn = const Cart(
        id: 1,
        isGuest: false,
        couponCode: 'HEMAT10',
        itemCount: 0,
        itemUniqueCount: 0,
        subtotal: 0,
        discount: 1000,
        tax: 0,
        shippingCost: 0,
        total: -1000,
        currency: 'IDR',
      );
      return build();
    },
    act: (bloc) => bloc.add(const CartCouponApplied('HEMAT10')),
    expect: () => [
      isA<CartState>().having((s) => s.mutationInProgress, 'mutating', true),
      isA<CartState>()
          .having((s) => s.cart.couponCode, 'coupon', 'HEMAT10')
          .having((s) => s.lastMessage, 'message', 'Kupon diterapkan'),
    ],
  );
}
