import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

/// Wishlist endpoint returns the products directly (not wrapped in a wishlist
/// row). The [CatalogRepository] parser handles this so we reuse it.

class WishlistRepository {
  WishlistRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> raw() async {
    final res = await _api.get<List<dynamic>>(ApiEndpoints.wishlist);
    if (res.data is List) {
      return res.data!
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Returns true when the item ended up in wishlist, false when removed.
  Future<bool> toggle(int productId) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.wishlistToggle,
      body: {'product_id': productId},
    );
    final msg = (res.message).toLowerCase();
    return msg.contains('ditambahkan');
  }

  Future<void> clear() async {
    await _api.delete<dynamic>(ApiEndpoints.wishlistClear);
  }
}
