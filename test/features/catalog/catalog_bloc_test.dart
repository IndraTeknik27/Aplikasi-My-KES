import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_kes/core/api/api_client.dart';
import 'package:my_kes/features/catalog/bloc/catalog_bloc.dart';
import 'package:my_kes/features/catalog/data/catalog_repository.dart';
import 'package:my_kes/shared/utils/pagination.dart';

class _FakeCatalogRepository extends Mock implements CatalogRepository {}

ProductSummary _p(int id, String name) => ProductSummary(
  id: id,
  slug: 'p-$id',
  name: name,
  price: 100000,
  salePrice: null,
);

({List<ProductSummary> items, PaginationMeta meta}) _result({
  List<ProductSummary>? items,
  PaginationMeta? meta,
}) => (
  items: items ?? const [],
  meta:
      meta ??
      const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
);

void main() {
  late _FakeCatalogRepository repo;

  setUp(() {
    repo = _FakeCatalogRepository();
    registerFallbackValue(<String, dynamic>{});
  });

  blocTest<CatalogBloc, CatalogState>(
    'initial fetch loads the first page',
    build: () {
      when(
        () => repo.products(
          categoryId: any(named: 'categoryId'),
          categorySlug: any(named: 'categorySlug'),
          brandId: any(named: 'brandId'),
          featured: any(named: 'featured'),
          bestseller: any(named: 'bestseller'),
          isNew: any(named: 'isNew'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          search: any(named: 'search'),
          sort: any(named: 'sort'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => _result(
          items: [_p(1, 'Aki A'), _p(2, 'Aki B')],
          meta: const PaginationMeta(
            currentPage: 1,
            lastPage: 3,
            perPage: 20,
            total: 50,
          ),
        ),
      );
      return CatalogBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const CatalogFiltersChanged(CatalogFilters())),
    expect: () => [
      isA<CatalogState>().having((s) => s.loading, 'loading', true),
      isA<CatalogState>()
          .having((s) => s.items.length, 'count', 2)
          .having((s) => s.meta.hasNext, 'hasNext', true)
          .having((s) => s.loading, 'loading', false),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'loadMore appends the next page when hasNext is true',
    build: () {
      when(
        () => repo.products(
          categoryId: any(named: 'categoryId'),
          categorySlug: any(named: 'categorySlug'),
          brandId: any(named: 'brandId'),
          featured: any(named: 'featured'),
          bestseller: any(named: 'bestseller'),
          isNew: any(named: 'isNew'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          search: any(named: 'search'),
          sort: any(named: 'sort'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int? ?? 1;
        return _result(
          items: List.generate(20, (i) => _p(page * 20 + i, 'P$i')),
          meta: const PaginationMeta(
            currentPage: 1,
            lastPage: 2,
            perPage: 20,
            total: 30,
          ),
        );
      });
      final bloc = CatalogBloc(repository: repo);
      bloc.add(const CatalogFiltersChanged(CatalogFilters()));
      return bloc;
    },
    act: (bloc) => bloc.add(const CatalogLoadMore()),
    skip: 2, // skip loading:true (initial) and loaded:20 (first page)
    expect: () => [
      isA<CatalogState>().having((s) => s.loadingMore, 'loadingMore', true),
      isA<CatalogState>()
          .having((s) => s.items.length, 'count', 40)
          .having((s) => s.loadingMore, 'loadingMore', false),
    ],
  );

  blocTest<CatalogBloc, CatalogState>(
    'sort change triggers a refetch with the new sort',
    build: () {
      when(
        () => repo.products(
          categoryId: any(named: 'categoryId'),
          categorySlug: any(named: 'categorySlug'),
          brandId: any(named: 'brandId'),
          featured: any(named: 'featured'),
          bestseller: any(named: 'bestseller'),
          isNew: any(named: 'isNew'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          search: any(named: 'search'),
          sort: any(named: 'sort'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _result(items: [_p(1, 'Cheap')]));
      return CatalogBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const CatalogSortChanged('price_asc')),
    expect: () => [
      isA<CatalogState>().having((s) => s.loading, 'loading', true),
      isA<CatalogState>().having((s) => s.filters.sort, 'sort', 'price_asc'),
    ],
    verify: (_) {
      verify(
        () => repo.products(
          categoryId: any(named: 'categoryId'),
          categorySlug: any(named: 'categorySlug'),
          brandId: any(named: 'brandId'),
          featured: any(named: 'featured'),
          bestseller: any(named: 'bestseller'),
          isNew: any(named: 'isNew'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          search: any(named: 'search'),
          sort: 'price_asc',
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(greaterThanOrEqualTo(1));
    },
  );

  blocTest<CatalogBloc, CatalogState>(
    'error during fetch surfaces errorMessage',
    build: () {
      when(
        () => repo.products(
          categoryId: any(named: 'categoryId'),
          categorySlug: any(named: 'categorySlug'),
          brandId: any(named: 'brandId'),
          featured: any(named: 'featured'),
          bestseller: any(named: 'bestseller'),
          isNew: any(named: 'isNew'),
          minPrice: any(named: 'minPrice'),
          maxPrice: any(named: 'maxPrice'),
          search: any(named: 'search'),
          sort: any(named: 'sort'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(ApiException(message: 'timeout', statusCode: 0));
      return CatalogBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const CatalogFiltersChanged(CatalogFilters())),
    expect: () => [
      isA<CatalogState>().having((s) => s.loading, 'loading', true),
      isA<CatalogState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.errorMessage, 'errorMessage', 'timeout'),
    ],
  );
}
