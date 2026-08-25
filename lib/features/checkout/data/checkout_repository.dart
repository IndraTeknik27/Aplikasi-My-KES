import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

// The Dart SDK shipped with this Flutter version rejects `?'key': value`
// for map entries (emit "invalid_null_aware_operator") while the
// `use_null_aware_elements` lint still recommends it. Keep the explicit
// `if` form for now and revisit when the SDK catches up.
// ignore_for_file: use_null_aware_elements
class CheckoutRepository {
  CheckoutRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// Returns the preview payload from `OrderService::preview()`. The shape is
  /// mostly cart+shipping+totals, so we pass the Map through and let the UI
  /// extract what it needs.
  Future<Map<String, dynamic>> preview({
    int? shippingAddressId,
    String? shippingCourier,
    String? couponCode,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.checkoutPreview,
      body: {
        if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
        if (shippingCourier != null) 'shipping_courier': shippingCourier,
        if (couponCode != null) 'coupon_code': couponCode,
      },
    );
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.checkoutPlace,
      body: body,
    );
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> validateStock() async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.checkoutValidateStock,
    );
    return res.data ?? const {};
  }
}
