part of 'catalog_bloc.dart';

class CatalogFilters extends Equatable {
  final int? categoryId;
  final String? categorySlug;
  final int? brandId;
  final bool featured;
  final bool bestseller;
  final bool isNew;
  final double? minPrice;
  final double? maxPrice;
  final String? search;
  final String sort;
  final int perPage;

  const CatalogFilters({
    this.categoryId,
    this.categorySlug,
    this.brandId,
    this.featured = false,
    this.bestseller = false,
    this.isNew = false,
    this.minPrice,
    this.maxPrice,
    this.search,
    this.sort = 'latest',
    this.perPage = 20,
  });

  CatalogFilters copyWith({
    int? categoryId,
    String? categorySlug,
    int? brandId,
    bool? featured,
    bool? bestseller,
    bool? isNew,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? sort,
    int? perPage,
  }) {
    return CatalogFilters(
      categoryId: categoryId ?? this.categoryId,
      categorySlug: categorySlug ?? this.categorySlug,
      brandId: brandId ?? this.brandId,
      featured: featured ?? this.featured,
      bestseller: bestseller ?? this.bestseller,
      isNew: isNew ?? this.isNew,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      perPage: perPage ?? this.perPage,
    );
  }

  bool get isEmpty =>
      categoryId == null &&
      categorySlug == null &&
      brandId == null &&
      !featured &&
      !bestseller &&
      !isNew &&
      minPrice == null &&
      maxPrice == null &&
      (search == null || search!.isEmpty);

  @override
  List<Object?> get props => [
    categoryId,
    categorySlug,
    brandId,
    featured,
    bestseller,
    isNew,
    minPrice,
    maxPrice,
    search,
    sort,
    perPage,
  ];
}

class CatalogState extends Equatable {
  final bool loading;
  final bool loadingMore;
  final List<ProductSummary> items;
  final PaginationMeta meta;
  final CatalogFilters filters;
  final String? errorMessage;

  const CatalogState({
    this.loading = false,
    this.loadingMore = false,
    this.items = const [],
    this.meta = const PaginationMeta(
      currentPage: 1,
      lastPage: 1,
      perPage: 0,
      total: 0,
    ),
    this.filters = const CatalogFilters(),
    this.errorMessage,
  });

  CatalogState copyWith({
    bool? loading,
    bool? loadingMore,
    List<ProductSummary>? items,
    PaginationMeta? meta,
    CatalogFilters? filters,
    String? errorMessage,
  }) {
    return CatalogState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      filters: filters ?? this.filters,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    loadingMore,
    items.length,
    meta.currentPage,
    meta.total,
    filters,
    errorMessage,
  ];
}
