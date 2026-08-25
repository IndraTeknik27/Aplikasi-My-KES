import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../shared/utils/pagination.dart';

// The Dart SDK shipped with this Flutter version rejects `?'key': value`
// for map entries (emit "invalid_null_aware_operator") while the
// `use_null_aware_elements` lint still recommends it. Keep the explicit
// `if` form for now and revisit when the SDK catches up.
// ignore_for_file: use_null_aware_elements
class ProductSummary {
  final int id;
  final String slug;
  final String name;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final String? brandName;
  final String? categoryName;
  final double? rating;
  final int? reviewCount;
  final bool isBestseller;
  final bool isNewArrival;
  final bool isFeatured;

  const ProductSummary({
    required this.id,
    required this.slug,
    required this.name,
    required this.price,
    this.salePrice,
    this.imageUrl,
    this.brandName,
    this.categoryName,
    this.rating,
    this.reviewCount,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.isFeatured = false,
  });

  /// Tolerant parser — accepts both the lightweight `index` shape and the
  /// condensed payload returned by `WishlistController::index`.
  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final brand = json['brand'];
    final images = json['images'];
    String? imageUrl;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        imageUrl =
            (first['url'] ??
                    first['image_url'] ??
                    first['path'] ??
                    first['src'])
                as String?;
      }
    }
    imageUrl ??= json['image_url'] as String?;
    imageUrl ??= (json['image'] is Map)
        ? (json['image'] as Map)['url'] as String?
        : null;
    imageUrl ??= (json['item'] is Map)
        ? (json['item'] as Map)['image_url'] as String?
        : null;

    return ProductSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      price: _toDouble(json['price']) ?? 0,
      salePrice: _toDouble(json['sale_price']),
      imageUrl: imageUrl,
      brandName: brand is Map ? brand['name'] as String? : null,
      categoryName: cat is Map ? cat['name'] as String? : null,
      rating: _toDouble(json['rating'] ?? json['average_rating']),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      isBestseller: json['is_bestseller'] == true,
      isNewArrival: json['is_new_arrival'] == true,
      isFeatured: json['is_featured'] == true,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class Category {
  final int id;
  final String slug;
  final String name;
  final int? parentId;
  final String? imageUrl;
  final List<Category> children;
  final bool isFeatured;

  const Category({
    required this.id,
    required this.slug,
    required this.name,
    this.parentId,
    this.imageUrl,
    this.children = const [],
    this.isFeatured = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final children = json['children'];
    return Category(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      parentId: (json['parent_id'] as num?)?.toInt(),
      imageUrl: (json['image_url'] ?? json['image']) as String?,
      isFeatured: json['is_featured'] == true,
      children: children is List
          ? children
                .whereType<Map>()
                .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

class Banner {
  final int id;
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? link;
  final String position;
  final int sort;

  const Banner({
    required this.id,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.link,
    required this.position,
    required this.sort,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    final img = json['image'];
    String? imageUrl;
    if (img is Map) {
      imageUrl = (img['url'] ?? img['path']) as String?;
    } else if (img is String) {
      imageUrl = img;
    }
    imageUrl ??= (json['image_url'] ?? json['banner_url']) as String?;

    return Banner(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageUrl: imageUrl,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      link: json['link'] as String?,
      position: (json['position'] as String?) ?? 'home',
      sort: (json['sort'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Single network repo covering everything catalog-related.
class CatalogRepository {
  CatalogRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<ProductSummary>> featured() async {
    final res = await _api.get<List<dynamic>>(ApiEndpoints.featuredProducts);
    return _parseList(res.data);
  }

  Future<List<ProductSummary>> bestSellers() async {
    final res = await _api.get<List<dynamic>>(ApiEndpoints.bestSellers);
    return _parseList(res.data);
  }

  Future<List<ProductSummary>> newArrivals() async {
    final res = await _api.get<List<dynamic>>(ApiEndpoints.newArrivals);
    return _parseList(res.data);
  }

  Future<({List<ProductSummary> items, PaginationMeta meta})> products({
    int? categoryId,
    String? categorySlug,
    int? brandId,
    bool? featured,
    bool? bestseller,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    String? search,
    String sort = 'latest',
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.get<List<dynamic>>(
      ApiEndpoints.products,
      query: {
        if (categoryId != null) 'category_id': categoryId,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'category_slug': categorySlug,
        if (brandId != null) 'brand_id': brandId,
        if (featured == true) 'featured': '1',
        if (bestseller == true) 'bestseller': '1',
        if (isNew == true) 'new': '1',
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (search != null && search.isNotEmpty) 'q': search,
        'sort': sort,
        'page': page,
        'per_page': perPage,
      },
    );
    return (
      items: _parseList(res.data),
      meta: PaginationMeta.fromResponse(res.meta),
    );
  }

  Future<ProductDetail> productDetail(String slug) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.productDetail(slug),
    );
    return ProductDetail.fromJson(res.data ?? const {});
  }

  Future<List<ProductSummary>> relatedProducts(String slug) async {
    final res = await _api.get<List<dynamic>>(
      ApiEndpoints.relatedProducts(slug),
    );
    return _parseList(res.data);
  }

  Future<List<Category>> categories({bool tree = false}) async {
    final path = tree ? ApiEndpoints.categoriesTree : ApiEndpoints.categories;
    final res = await _api.get<List<dynamic>>(path);
    return (res.data ?? [])
        .whereType<Map>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, List<Banner>>> banners({String? position}) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.banners,
      query: position != null ? {'position': position} : null,
    );
    final data = res.data ?? const {};
    final byPos = data['by_position'];
    final map = <String, List<Banner>>{};
    if (byPos is Map) {
      byPos.forEach((k, v) {
        if (v is List) {
          map[k.toString()] = v
              .whereType<Map>()
              .map((e) => Banner.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
    }
    return map;
  }

  List<ProductSummary> _parseList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ProductSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}

class ProductVariation {
  final int id;
  final String name;
  final String? sku;
  final double? price;
  final double? salePrice;
  final int? stockQty;
  final int? reservedQty;
  final bool isActive;
  final Map<String, dynamic>? attributes;

  const ProductVariation({
    required this.id,
    required this.name,
    this.sku,
    this.price,
    this.salePrice,
    this.stockQty,
    this.reservedQty,
    required this.isActive,
    this.attributes,
  });

  int get availableStock {
    if (stockQty == null) return 0;
    final reserved = reservedQty ?? 0;
    return (stockQty! - reserved).clamp(0, stockQty!);
  }

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      sku: json['sku'] as String?,
      price: _toDouble(json['price']),
      salePrice: _toDouble(json['sale_price']),
      stockQty: (json['stock_qty'] as num?)?.toInt(),
      reservedQty: (json['reserved_qty'] as num?)?.toInt(),
      isActive: json['is_active'] != false,
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
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

class ProductImage {
  final int id;
  final String? url;
  final int sort;
  final String? alt;
  const ProductImage({
    required this.id,
    this.url,
    required this.sort,
    this.alt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    String? url = (json['url'] ?? json['image_url'] ?? json['path']) as String?;
    final img = json['image'];
    if (url == null && img is Map) {
      url = (img['url'] ?? img['path']) as String?;
    }
    return ProductImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: url,
      sort: (json['sort'] as num?)?.toInt() ?? 0,
      alt: json['alt'] as String?,
    );
  }
}

class ProductDetail {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? salePrice;
  final int? stockQty;
  final bool manageStock;
  final String? sku;
  final Category? category;
  final dynamic brand; // Brand map; rarely used in detail screen
  final List<ProductImage> images;
  final List<ProductVariation> variations;
  final double? rating;
  final int? reviewCount;
  final int? salesCount;
  final int? views;
  final bool isBestseller;
  final bool isNewArrival;
  final bool isFeatured;
  final List<ProductSpec>? specifications;

  const ProductDetail({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.shortDescription,
    required this.price,
    this.salePrice,
    this.stockQty,
    required this.manageStock,
    this.sku,
    this.category,
    this.brand,
    this.images = const [],
    this.variations = const [],
    this.rating,
    this.reviewCount,
    this.salesCount,
    this.views,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.specifications,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final imgsRaw = json['images'];
    final specsRaw = json['specifications'] ?? json['specs'];
    return ProductDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      shortDescription:
          (json['short_description'] ?? json['excerpt']) as String?,
      price: _toDouble(json['price']) ?? 0,
      salePrice: _toDouble(json['sale_price']),
      stockQty: (json['stock_qty'] as num?)?.toInt(),
      manageStock: json['manage_stock'] == true,
      sku: json['sku'] as String?,
      category: json['category'] is Map
          ? Category.fromJson(
              Map<String, dynamic>.from(json['category'] as Map),
            )
          : null,
      brand: json['brand'],
      images: imgsRaw is List
          ? imgsRaw
                .whereType<Map>()
                .map((e) => ProductImage.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      variations: json['variations'] is List
          ? (json['variations'] as List)
                .whereType<Map>()
                .map(
                  (e) =>
                      ProductVariation.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      rating: _toDouble(json['rating'] ?? json['average_rating']),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      salesCount: (json['sales_count'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt(),
      isBestseller: json['is_bestseller'] == true,
      isNewArrival: json['is_new_arrival'] == true,
      isFeatured: json['is_featured'] == true,
      specifications: specsRaw is List
          ? specsRaw
                .whereType<Map>()
                .map((e) => ProductSpec.fromJson(Map<String, dynamic>.from(e)))
                .toList()
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

class ProductSpec {
  final String label;
  final String value;
  const ProductSpec({required this.label, required this.value});
  factory ProductSpec.fromJson(Map<String, dynamic> json) {
    final v = json['value'];
    return ProductSpec(
      label: (json['label'] ?? json['name'] ?? json['key'] ?? '') as String,
      value: v == null ? '' : v.toString(),
    );
  }
}
