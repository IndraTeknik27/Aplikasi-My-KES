import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

// The Dart SDK shipped with this Flutter version rejects `?'key': value`
// for map entries (emit "invalid_null_aware_operator") while the
// `use_null_aware_elements` lint still recommends it. Keep the explicit
// `if` form for now and revisit when the SDK catches up.
// ignore_for_file: use_null_aware_elements
/// Cart models with safe parsing — backend may return the cart either as a
/// top-level object or wrapped in a `cart` key depending on the endpoint.
class CartItem {
  final int id;
  final String itemableType; // 'product' or 'variation'
  final int itemableId;
  final String? name;
  final String? slug;
  final String? imageUrl;
  final String? sku;
  final int qty;
  final double price;
  final double subtotal;
  final String? notes;

  const CartItem({
    required this.id,
    required this.itemableType,
    required this.itemableId,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.sku,
    required this.qty,
    required this.price,
    required this.subtotal,
    this.notes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    String? name;
    String? slug;
    String? imageUrl;
    if (item is Map) {
      name = (item['name'] ?? item['title']) as String?;
      slug = item['slug'] as String?;
      imageUrl = (item['image_url'] ?? item['image']) as String?;
    }
    imageUrl ??= (json['image'] is Map)
        ? (json['image'] as Map)['url'] as String?
        : json['image'] as String?;
    imageUrl ??= (json['image_url']) as String?;

    final rawPrice = json['price'] ?? (item is Map ? item['price'] : null);
    final qty = (json['qty'] as num?)?.toInt() ?? 1;
    final subtotalRaw = json['subtotal'];

    return CartItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemableType:
          (json['itemable_type'] as String?)?.toLowerCase().contains(
                'variation',
              ) ==
              true
          ? 'variation'
          : 'product',
      itemableId: (json['itemable_id'] as num?)?.toInt() ?? 0,
      name: name ?? json['name'] as String?,
      slug: slug ?? (json['slug'] as String?),
      imageUrl: imageUrl,
      sku: json['sku'] as String?,
      qty: qty,
      price: _toDouble(rawPrice) ?? 0,
      subtotal: _toDouble(subtotalRaw) ?? (_toDouble(rawPrice) ?? 0) * qty,
      notes: json['notes'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class Cart {
  final int id;
  final String? sessionId;
  final int? customerId;
  final bool isGuest;
  final String? couponCode;
  final int itemCount;
  final int itemUniqueCount;
  final double subtotal;
  final double discount;
  final double tax;
  final double shippingCost;
  final double total;
  final String currency;
  final String? expiresAt;
  final List<CartItem> items;

  const Cart({
    required this.id,
    this.sessionId,
    this.customerId,
    required this.isGuest,
    this.couponCode,
    required this.itemCount,
    required this.itemUniqueCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shippingCost,
    required this.total,
    required this.currency,
    this.expiresAt,
    this.items = const [],
  });

  bool get isEmpty => items.isEmpty;
  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return Cart(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sessionId: json['session_id'] as String?,
      customerId: (json['customer_id'] as num?)?.toInt(),
      isGuest: json['is_guest'] == true,
      couponCode: json['coupon_code'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      itemUniqueCount: (json['item_unique_count'] as num?)?.toInt() ?? 0,
      subtotal: _toDouble(json['subtotal']) ?? 0,
      discount: _toDouble(json['discount']) ?? 0,
      tax: _toDouble(json['tax']) ?? 0,
      shippingCost: _toDouble(json['shipping_cost']) ?? 0,
      total: _toDouble(json['total']) ?? 0,
      currency: (json['currency'] as String?) ?? 'IDR',
      expiresAt: json['expires_at'] as String?,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class CartRepository {
  CartRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<Cart> fetch() async {
    final res = await _api.get<Map<String, dynamic>>(ApiEndpoints.cart);
    return Cart.fromJson(res.data ?? const {});
  }

  Future<Cart> addItem({
    required String itemableType, // 'product' or 'variation'
    required int itemableId,
    required int qty,
    String? notes,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      body: {
        'itemable_type': itemableType,
        'itemable_id': itemableId,
        'qty': qty,
        if (notes != null) 'notes': notes,
      },
    );
    final data = res.data ?? const {};
    final cart = data['cart'];
    if (cart is Map) {
      return Cart.fromJson(Map<String, dynamic>.from(cart));
    }
    return Cart.fromJson(data);
  }

  Future<Cart> updateItem(int itemId, int qty) async {
    final res = await _api.put<Map<String, dynamic>>(
      ApiEndpoints.cartItem(itemId),
      body: {'qty': qty},
    );
    final data = res.data ?? const {};
    final cart = data['cart'];
    if (cart is Map) {
      return Cart.fromJson(Map<String, dynamic>.from(cart));
    }
    return Cart.fromJson(data);
  }

  Future<Cart> removeItem(int itemId) async {
    final res = await _api.delete<Map<String, dynamic>>(
      ApiEndpoints.cartItem(itemId),
    );
    return Cart.fromJson(res.data ?? const {});
  }

  Future<Cart> clear() async {
    final res = await _api.delete<Map<String, dynamic>>(ApiEndpoints.cartClear);
    return Cart.fromJson(res.data ?? const {});
  }

  Future<Cart> applyCoupon(String code) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.cartCoupon,
      body: {'code': code},
    );
    return Cart.fromJson(res.data ?? const {});
  }

  Future<Cart> removeCoupon() async {
    final res = await _api.delete<Map<String, dynamic>>(
      ApiEndpoints.cartCoupon,
    );
    return Cart.fromJson(res.data ?? const {});
  }

  /// Returns the list of shipping options from `cart/shipping` endpoint.
  Future<List<Map<String, dynamic>>> calculateShipping({
    required String city,
    String courier = 'jne',
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.cartShipping,
      body: {'city': city, 'courier': courier},
    );
    final opts = res.data?['options'];
    if (opts is List) {
      return opts
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}
