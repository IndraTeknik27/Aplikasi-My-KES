import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

// The Dart SDK shipped with this Flutter version rejects `?'key': value`
// for map entries (emit "invalid_null_aware_operator") while the
// `use_null_aware_elements` lint still recommends it. Keep the explicit
// `if` form for now and revisit when the SDK catches up.
// ignore_for_file: use_null_aware_elements
class Payment {
  final int id;
  final String? paymentNumber;
  final String? orderNumber;
  final String? gateway;
  final String? transactionId;
  final String? paymentType;
  final String? bank;
  final String? vaNumber;
  final double grossAmount;
  final double feeAmount;
  final double? netAmount;
  final String status;
  final bool isSuccessful;
  final bool isPending;
  final bool isFailed;
  final String? fraudStatus;
  final String? snapToken;
  final String? redirectUrl;
  final String? clientKey;
  final String? paidAt;
  final String? expiredAt;
  final String? createdAt;
  final String? updatedAt;

  const Payment({
    required this.id,
    this.paymentNumber,
    this.orderNumber,
    this.gateway,
    this.transactionId,
    this.paymentType,
    this.bank,
    this.vaNumber,
    required this.grossAmount,
    required this.feeAmount,
    this.netAmount,
    required this.status,
    required this.isSuccessful,
    required this.isPending,
    required this.isFailed,
    this.fraudStatus,
    this.snapToken,
    this.redirectUrl,
    this.clientKey,
    this.paidAt,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return Payment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentNumber: json['payment_number'] as String?,
      orderNumber: json['order_number'] as String?,
      gateway: json['gateway'] as String?,
      transactionId: json['transaction_id'] as String?,
      paymentType: json['payment_type'] as String?,
      bank: json['bank'] as String?,
      vaNumber: json['va_number'] as String?,
      grossAmount: toDouble(json['gross_amount']) ?? 0,
      feeAmount: toDouble(json['fee_amount']) ?? 0,
      netAmount: toDouble(json['net_amount']),
      status: (json['status'] as String?) ?? 'pending',
      isSuccessful: json['is_successful'] == true,
      isPending: json['is_pending'] == true,
      isFailed: json['is_failed'] == true,
      fraudStatus: json['fraud_status'] as String?,
      snapToken: json['snap_token'] as String?,
      redirectUrl: json['redirect_url'] as String?,
      clientKey: json['client_key'] as String?,
      paidAt: json['paid_at'] as String?,
      expiredAt: json['expired_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class PaymentRepository {
  PaymentRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<Payment> initiate(String orderNumber, {String? method}) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.paymentInitiate(orderNumber),
      body: {if (method != null) 'payment_method_type': method},
    );
    return Payment.fromJson(res.data ?? const {});
  }

  Future<Payment> status(String orderNumber) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.paymentStatus(orderNumber),
    );
    return Payment.fromJson(res.data ?? const {});
  }

  Future<Payment> refresh(String orderNumber) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.paymentRefresh(orderNumber),
    );
    return Payment.fromJson(res.data ?? const {});
  }
}
