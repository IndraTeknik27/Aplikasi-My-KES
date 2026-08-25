import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../../shared/utils/pagination.dart';
import '../data/catalog_repository.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({CatalogRepository? repository})
    : _repo = repository ?? CatalogRepository(),
      super(const CatalogState()) {
    on<CatalogFiltersChanged>(_onFiltersChanged);
    on<CatalogPageRequested>(_onPageRequested);
    on<CatalogRefreshed>(_onRefresh);
    on<CatalogSortChanged>(_onSortChanged);
    on<CatalogLoadMore>(_onLoadMore);
  }

  final CatalogRepository _repo;

  Future<void> _onFiltersChanged(
    CatalogFiltersChanged event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        filters: event.filters,
        items: const [],
        meta: const PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: 0,
          total: 0,
        ),
        loading: true,
      ),
    );
    await _load(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    CatalogRefreshed event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    await _load(emit, page: 1, append: false);
  }

  Future<void> _onPageRequested(
    CatalogPageRequested event,
    Emitter<CatalogState> emit,
  ) async {
    await _load(emit, page: event.page, append: false);
  }

  Future<void> _onLoadMore(
    CatalogLoadMore event,
    Emitter<CatalogState> emit,
  ) async {
    if (state.loading || state.loadingMore) return;
    if (!state.meta.hasNext) return;
    emit(state.copyWith(loadingMore: true));
    await _load(emit, page: state.meta.currentPage + 1, append: true);
  }

  Future<void> _onSortChanged(
    CatalogSortChanged event,
    Emitter<CatalogState> emit,
  ) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(sort: event.sort),
        loading: true,
      ),
    );
    await _load(emit, page: 1, append: false);
  }

  Future<void> _load(
    Emitter<CatalogState> emit, {
    required int page,
    required bool append,
  }) async {
    try {
      final f = state.filters;
      final res = await _repo.products(
        categoryId: f.categoryId,
        categorySlug: f.categorySlug,
        brandId: f.brandId,
        featured: f.featured,
        bestseller: f.bestseller,
        isNew: f.isNew,
        minPrice: f.minPrice,
        maxPrice: f.maxPrice,
        search: f.search,
        sort: f.sort,
        page: page,
        perPage: f.perPage,
      );
      final newItems = append ? [...state.items, ...res.items] : res.items;
      emit(
        state.copyWith(
          items: newItems,
          meta: res.meta,
          loading: false,
          loadingMore: false,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loading: false,
          loadingMore: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          loadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
