import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../catalog/data/catalog_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({CatalogRepository? repo})
    : _repo = repo ?? CatalogRepository(),
      super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshed>(_onRefresh);
  }

  final CatalogRepository _repo;

  Future<void> _onLoad(HomeLoadRequested e, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true));
    await _fetch(emit);
  }

  Future<void> _onRefresh(HomeRefreshed e, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true));
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<HomeState> emit) async {
    try {
      final banners = await _repo.banners();
      final featured = await _repo.featured();
      final bestSellers = await _repo.bestSellers();
      final newArrivals = await _repo.newArrivals();
      final categories = await _repo.categories(tree: true);
      emit(
        state.copyWith(
          loading: false,
          banners: banners,
          featured: featured,
          bestSellers: bestSellers,
          newArrivals: newArrivals,
          categories: categories,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }
}
