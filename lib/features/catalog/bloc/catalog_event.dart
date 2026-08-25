part of 'catalog_bloc.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => const [];
}

class CatalogFiltersChanged extends CatalogEvent {
  final CatalogFilters filters;
  const CatalogFiltersChanged(this.filters);
  @override
  List<Object?> get props => [filters];
}

class CatalogRefreshed extends CatalogEvent {
  const CatalogRefreshed();
}

class CatalogPageRequested extends CatalogEvent {
  final int page;
  const CatalogPageRequested(this.page);
  @override
  List<Object?> get props => [page];
}

class CatalogLoadMore extends CatalogEvent {
  const CatalogLoadMore();
}

class CatalogSortChanged extends CatalogEvent {
  final String sort;
  const CatalogSortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}
