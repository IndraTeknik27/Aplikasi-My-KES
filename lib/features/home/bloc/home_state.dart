part of 'home_bloc.dart';

class HomeState extends Equatable {
  final bool loading;
  final Map<String, List<Banner>> banners;
  final List<ProductSummary> featured;
  final List<ProductSummary> bestSellers;
  final List<ProductSummary> newArrivals;
  final List<Category> categories;
  final String? errorMessage;

  const HomeState({
    this.loading = false,
    this.banners = const {},
    this.featured = const [],
    this.bestSellers = const [],
    this.newArrivals = const [],
    this.categories = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    bool? loading,
    Map<String, List<Banner>>? banners,
    List<ProductSummary>? featured,
    List<ProductSummary>? bestSellers,
    List<ProductSummary>? newArrivals,
    List<Category>? categories,
    String? errorMessage,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      banners: banners ?? this.banners,
      featured: featured ?? this.featured,
      bestSellers: bestSellers ?? this.bestSellers,
      newArrivals: newArrivals ?? this.newArrivals,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    banners.length,
    featured.length,
    bestSellers.length,
    newArrivals.length,
    categories.length,
    errorMessage,
  ];
}
