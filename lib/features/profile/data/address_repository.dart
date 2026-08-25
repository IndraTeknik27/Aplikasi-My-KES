import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

class Address {
  final int id;
  final String? label;
  final String recipient;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String province;
  final String city;
  final String district;
  final String? village;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final bool isPrimary;
  final String? fullAddress;
  // Sender address (alamat pengirim / return address)
  final String? senderName;
  final String? senderPhone;
  final String? senderAddress;
  final String? senderNotes;
  final String? createdAt;
  final String? updatedAt;

  const Address({
    required this.id,
    this.label,
    required this.recipient,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.province,
    required this.city,
    required this.district,
    this.village,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.notes,
    required this.isPrimary,
    this.fullAddress,
    this.senderName,
    this.senderPhone,
    this.senderAddress,
    this.senderNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: json['label'] as String?,
      recipient: (json['recipient'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      addressLine1: (json['address_line_1'] as String?) ?? '',
      addressLine2: json['address_line_2'] as String?,
      province: (json['province'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      district: (json['district'] as String?) ?? '',
      village: json['village'] as String?,
      postalCode: (json['postal_code'] as String?) ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      notes: json['notes'] as String?,
      isPrimary: json['is_primary'] == true,
      fullAddress: json['full_address'] as String?,
      // Sender address fields
      senderName: json['sender_name'] as String?,
      senderPhone: json['sender_phone'] as String?,
      senderAddress: json['sender_address'] as String?,
      senderNotes: json['sender_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AddressRepository {
  AddressRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<Address>> list() async {
    final res = await _api.get<List<dynamic>>(ApiEndpoints.addresses);
    return (res.data ?? [])
        .whereType<Map>()
        .map((e) => Address.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addresses,
      body: body,
    );
    return Address.fromJson(res.data ?? const {});
  }

  Future<Address> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put<Map<String, dynamic>>(
      ApiEndpoints.addressDetail(id),
      body: body,
    );
    return Address.fromJson(res.data ?? const {});
  }

  Future<void> delete(int id) async {
    await _api.delete<dynamic>(ApiEndpoints.addressDetail(id));
  }

  Future<Address> setPrimary(int id) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addressSetPrimary(id),
    );
    return Address.fromJson(res.data ?? const {});
  }
}
