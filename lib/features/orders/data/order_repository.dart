import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../shared/utils/pagination.dart';

/// Order, OrderItem, tracking, invoice models + repository.
class OrderTimestamps {
  final String? paidAt;
  final String? shippedAt;
  final String? deliveredAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? expiresAt;
  const OrderTimestamps({
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.expiresAt,
  });

  factory OrderTimestamps.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return OrderTimestamps(
      paidAt: json['paid_at'] as String?,
      shippedAt: json['shipped_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      completedAt: json['completed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      expiresAt: json['expires_at'] as String?,
    );
  }
}

class OrderItem {
  final int id;
  final String itemableType;
  final int itemableId;
  final String? name;
  final String? sku;
  final String? image;
  final double price;
  final int qty;
  final double subtotal;
  final Map<String, dynamic>? variationAttributes;
  final String? notes;

  const OrderItem({
    required this.id,
    required this.itemableType,
    required this.itemableId,
    this.name,
    this.sku,
    this.image,
    required this.price,
    required this.qty,
    required this.subtotal,
    this.variationAttributes,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemableType: (json['itemable_type'] as String?) ?? '',
      itemableId: (json['itemable_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?),
      sku: json['sku'] as String?,
      image: (json['image'] is Map)
          ? ((json['image'] as Map)['url']) as String?
          : json['image'] as String?,
      price: _toDouble(json['price']) ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      subtotal: _toDouble(json['subtotal']) ?? 0,
      variationAttributes: json['variation_attributes'] is Map
          ? Map<String, dynamic>.from(json['variation_attributes'] as Map)
          : null,
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

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String? statusLabel;
  final bool isPaid;
  final bool isPendingPayment;
  final bool isCompleted;
  final bool isCancelled;
  final String? paymentMethod;
  final double subtotal;
  final double discount;
  final double tax;
  final double shippingCost;
  final double total;
  final String currency;
  final String? couponCode;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String? shippingCourier;
  final String? shippingService;
  final String? shippingTrackingNumber;
  final String? customerNotes;
  final int itemCount;
  final List<OrderItem> items;
  final OrderTimestamps timestamps;
  final List<Map<String, dynamic>> statusHistory;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? customer;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.statusLabel,
    required this.isPaid,
    required this.isPendingPayment,
    required this.isCompleted,
    required this.isCancelled,
    this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shippingCost,
    required this.total,
    required this.currency,
    this.couponCode,
    this.shippingAddress,
    this.billingAddress,
    this.shippingCourier,
    this.shippingService,
    this.shippingTrackingNumber,
    this.customerNotes,
    required this.itemCount,
    this.items = const [],
    required this.timestamps,
    this.statusHistory = const [],
    this.createdAt,
    this.updatedAt,
    this.customer,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final histRaw = json['status_history'];
    return Order(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber: (json['order_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      statusLabel: json['status_label'] as String?,
      isPaid: json['is_paid'] == true,
      isPendingPayment: json['is_pending_payment'] == true,
      isCompleted: json['is_completed'] == true,
      isCancelled: json['is_cancelled'] == true,
      paymentMethod: json['payment_method'] as String?,
      subtotal: _toDouble(json['subtotal']) ?? 0,
      discount: _toDouble(json['discount']) ?? 0,
      tax: _toDouble(json['tax']) ?? 0,
      shippingCost: _toDouble(json['shipping_cost']) ?? 0,
      total: _toDouble(json['total']) ?? 0,
      currency: (json['currency'] as String?) ?? 'IDR',
      couponCode: json['coupon_code'] as String?,
      shippingAddress: json['shipping_address'] is Map
          ? Map<String, dynamic>.from(json['shipping_address'] as Map)
          : null,
      billingAddress: json['billing_address'] is Map
          ? Map<String, dynamic>.from(json['billing_address'] as Map)
          : null,
      shippingCourier: json['shipping_courier'] as String?,
      shippingService: json['shipping_service'] as String?,
      shippingTrackingNumber: json['shipping_tracking_number'] as String?,
      customerNotes: json['customer_notes'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      timestamps: OrderTimestamps.fromJson(
        json['timestamps'] is Map
            ? Map<String, dynamic>.from(json['timestamps'] as Map)
            : null,
      ),
      statusHistory: histRaw is List
          ? histRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      customer: json['customer'] is Map
          ? Map<String, dynamic>.from(json['customer'] as Map)
          : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class OrderTracking {
  final String orderNumber;
  final String status;
  final String? shippingCourier;
  final String? shippingService;
  final String? trackingNumber;
  final List<TrackingStep> steps;
  final List<Map<String, dynamic>> statusHistory;

  const OrderTracking({
    required this.orderNumber,
    required this.status,
    this.shippingCourier,
    this.shippingService,
    this.trackingNumber,
    this.steps = const [],
    this.statusHistory = const [],
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final stepsRaw = json['tracking_steps'];
    final histRaw = json['status_history'];
    return OrderTracking(
      orderNumber: (json['order_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      shippingCourier: json['shipping_courier'] as String?,
      shippingService: json['shipping_service'] as String?,
      trackingNumber: json['shipping_tracking_number'] as String?,
      steps: stepsRaw is List
          ? stepsRaw
                .whereType<Map>()
                .map((e) => TrackingStep.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      statusHistory: histRaw is List
          ? histRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const [],
    );
  }
}

class TrackingStep {
  final String status;
  final String label;
  final bool done;
  const TrackingStep({
    required this.status,
    required this.label,
    required this.done,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) => TrackingStep(
    status: (json['status'] as String?) ?? '',
    label: (json['label'] as String?) ?? '',
    done: json['done'] == true,
  );
}

class OrderRepository {
  OrderRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<({List<Order> items, PaginationMeta meta})> list({
    String? status,
    String sort = 'latest',
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.get<List<dynamic>>(
      ApiEndpoints.orders,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      },
    );
    final list = (res.data ?? [])
        .whereType<Map>()
        .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (items: list, meta: PaginationMeta.fromResponse(res.meta));
  }

  Future<Order> detail(String orderNumber) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail(orderNumber),
    );
    return Order.fromJson(res.data ?? const {});
  }

  Future<Order> cancel(String orderNumber, {required String reason}) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orderCancel(orderNumber),
      body: {'reason': reason},
    );
    return Order.fromJson(res.data ?? const {});
  }

  Future<Order> confirmDelivery(String orderNumber) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orderConfirmDelivery(orderNumber),
    );
    return Order.fromJson(res.data ?? const {});
  }

  Future<OrderTracking> tracking(String orderNumber) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderTracking(orderNumber),
    );
    return OrderTracking.fromJson(res.data ?? const {});
  }

  Future<Map<String, dynamic>> invoice(String orderNumber) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderInvoice(orderNumber),
    );
    return res.data ?? const {};
  }
}
