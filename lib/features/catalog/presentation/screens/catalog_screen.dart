import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/states.dart';
import '../../bloc/catalog_bloc.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _scrollCtl = ScrollController();
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(
      const CatalogFiltersChanged(CatalogFilters()),
    );
    _scrollCtl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;
    if (_scrollCtl.position.pixels >
        _scrollCtl.position.maxScrollExtent - 400) {
      context.read<CatalogBloc>().add(const CatalogLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                hintText: 'Cari produk…',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchCtl.clear();
                          context.read<CatalogBloc>().add(
                            const CatalogFiltersChanged(CatalogFilters()),
                          );
                          setState(() {});
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 8,
                ),
              ),
              onSubmitted: (q) {
                context.read<CatalogBloc>().add(
                  CatalogFiltersChanged(
                    CatalogFilters(search: q.trim().isEmpty ? null : q.trim()),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilterSheet),
        ],
      ),
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => const ProductCardSkeleton(),
            );
          }
          if (state.items.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Produk tidak ditemukan',
              subtitle: 'Coba ubah filter atau kata kunci pencarian Anda.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CatalogBloc>().add(const CatalogRefreshed()),
            child: Column(
              children: [
                _Toolbar(state: state),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollCtl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.62,
                        ),
                    itemCount:
                        state.items.length + (state.meta.hasNext ? 2 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= state.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final p = state.items[i];
                      return ProductCard(
                        slug: p.slug,
                        name: p.name,
                        price: p.price,
                        salePrice: p.salePrice,
                        imageUrl: p.imageUrl,
                        brandName: p.brandName,
                        categoryName: p.categoryName,
                        rating: p.rating,
                        reviewCount: p.reviewCount,
                        isBestseller: p.isBestseller,
                        isFeatured: p.isFeatured,
                        isNew: p.isNewArrival,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFilterSheet() {
    final bloc = context.read<CatalogBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _FilterSheet()),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final CatalogState state;
  const _Toolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${state.meta.total} produk',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            position: PopupMenuPosition.under,
            onSelected: (v) =>
                context.read<CatalogBloc>().add(CatalogSortChanged(v)),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'latest', child: Text('Terbaru')),
              PopupMenuItem(value: 'popular', child: Text('Populer')),
              PopupMenuItem(value: 'price_asc', child: Text('Harga Termurah')),
              PopupMenuItem(
                value: 'price_desc',
                child: Text('Harga Tertinggi'),
              ),
              PopupMenuItem(value: 'name_asc', child: Text('Nama A-Z')),
            ],
            child: Row(
              children: [
                const Icon(Icons.sort, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  _label(state.filters.sort),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(String sort) {
    switch (sort) {
      case 'price_asc':
        return 'Harga ↑';
      case 'price_desc':
        return 'Harga ↓';
      case 'name_asc':
        return 'A-Z';
      case 'popular':
        return 'Populer';
      default:
        return 'Terbaru';
    }
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CatalogFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = context.read<CatalogBloc>().state.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter Produk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Tipe Produk',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: const Text('Best Seller'),
                  selected: _draft.bestseller,
                  onSelected: (v) =>
                      setState(() => _draft = _draft.copyWith(bestseller: v)),
                ),
                FilterChip(
                  label: const Text('Produk Baru'),
                  selected: _draft.isNew,
                  onSelected: (v) =>
                      setState(() => _draft = _draft.copyWith(isNew: v)),
                ),
                FilterChip(
                  label: const Text('Featured'),
                  selected: _draft.featured,
                  onSelected: (v) =>
                      setState(() => _draft = _draft.copyWith(featured: v)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Rentang Harga (Rp)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Min',
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        _draft = _draft.copyWith(minPrice: double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Max',
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        _draft = _draft.copyWith(maxPrice: double.tryParse(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CatalogBloc>().add(
                        const CatalogFiltersChanged(CatalogFilters()),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CatalogBloc>().add(
                        CatalogFiltersChanged(_draft),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
