import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cart_repository.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({CartRepository? repository})
    : _repository = repository ?? CartRepository(),
      super(const CartState()) {
    on<CartLoadRequested>(_onLoad);
    on<CartItemAdded>(_onAddItem);
    on<CartItemUpdated>(_onUpdateItem);
    on<CartItemRemoved>(_onRemoveItem);
    on<CartCleared>(_onClear);
    on<CartCouponApplied>(_onApplyCoupon);
    on<CartCouponRemoved>(_onRemoveCoupon);
    on<CartShippingOptionsRequested>(_onShippingOptions);
  }

  final CartRepository _repository;

  Future<void> _onLoad(CartLoadRequested event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _repository.fetch();
      emit(state.copyWith(status: CartStatus.loaded, cart: cart));
    } catch (e) {
      emit(
        state.copyWith(status: CartStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onAddItem(CartItemAdded event, Emitter<CartState> emit) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.addItem(
        itemableType: event.itemableType,
        itemableId: event.itemableId,
        qty: event.qty,
        notes: event.notes,
      );
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
          lastMessage: 'Ditambahkan ke keranjang',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onUpdateItem(
    CartItemUpdated event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.updateItem(event.itemId, event.qty);
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRemoveItem(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.removeItem(event.itemId);
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
          lastMessage: 'Item dihapus',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onClear(CartCleared event, Emitter<CartState> emit) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.clear();
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
          lastMessage: 'Keranjang dikosongkan',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onApplyCoupon(
    CartCouponApplied event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.applyCoupon(event.code);
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
          lastMessage: 'Kupon diterapkan',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRemoveCoupon(
    CartCouponRemoved event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(mutationInProgress: true));
    try {
      final cart = await _repository.removeCoupon();
      emit(
        state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          mutationInProgress: false,
          lastMessage: 'Kupon dihapus',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(mutationInProgress: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onShippingOptions(
    CartShippingOptionsRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(shippingLoading: true));
    try {
      final options = await _repository.calculateShipping(
        city: event.city,
        courier: event.courier,
      );
      emit(state.copyWith(shippingLoading: false, shippingOptions: options));
    } catch (e) {
      emit(state.copyWith(shippingLoading: false, errorMessage: e.toString()));
    }
  }
}
