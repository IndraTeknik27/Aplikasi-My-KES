import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/states.dart';
import '../../bloc/home_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeLoadRequested());
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.loading && state.featured.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<HomeBloc>().add(const HomeRefreshed()),
                child: ListView(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.lg),
                    ...List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Skeleton(height: 120),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<HomeBloc>().add(const HomeRefreshed()),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  if (state.banners['home_top']?.isNotEmpty == true)
                    SliverToBoxAdapter(
                      child: _BannerStrip(banners: state.banners['home_top']!),
                    ),
                  if (state.categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _CategoryStrip(categories: state.categories),
                    ),
                  if (state.bestSellers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Best Seller',
                        actionLabel: 'Lihat semua',
                        onAction: () => context.go(Routes.catalog),
                      ),
                    ),
                  if (state.bestSellers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _HorizontalProducts(items: state.bestSellers),
                    ),
                  if (state.featured.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Produk Pilihan',
                        actionLabel: 'Lihat semua',
                        onAction: () => context.go(Routes.catalog),
                      ),
                    ),
                  if (state.featured.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _HorizontalProducts(items: state.featured),
                    ),
                  if (state.newArrivals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Produk Baru',
                        actionLabel: 'Lihat semua',
                        onAction: () => context.go(Routes.catalog),
                      ),
                    ),
                  if (state.newArrivals.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.62,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ProductCard(
                            slug: state.newArrivals[i].slug,
                            name: state.newArrivals[i].name,
                            price: state.newArrivals[i].price,
                            salePrice: state.newArrivals[i].salePrice,
                            imageUrl: state.newArrivals[i].imageUrl,
                            brandName: state.newArrivals[i].brandName,
                            isNew: state.newArrivals[i].isNewArrival,
                            rating: state.newArrivals[i].rating,
                            reviewCount: state.newArrivals[i].reviewCount,
                          ),
                          childCount: state.newArrivals.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My KES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'KARTEKS Energy Solution',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur dalam pengembangan.')),
                  );
                },
                color: AppColors.textPrimary,
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.go(Routes.cart),
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => setState(() => _searching = !_searching),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _searchCtl.text.isEmpty
                          ? 'Cari produk, brand, atau kategori…'
                          : _searchCtl.text,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(Icons.tune, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStrip extends StatelessWidget {
  final List banners;
  const _BannerStrip({required this.banners});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx, i) {
            final b = banners[i];
            final url = b.imageUrl;
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 300,
                child: SafeNetworkImage(
                  url: url,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemCount: banners.length,
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List categories;
  const _CategoryStrip({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Kategori'),
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemBuilder: (ctx, i) {
                final c = categories[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => context.go(Routes.catalog),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  final List items;
  const _HorizontalProducts({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, i) {
          final p = items[i];
          return SizedBox(
            width: 160,
            child: ProductCard(
              slug: p.slug,
              name: p.name,
              price: p.price,
              salePrice: p.salePrice,
              imageUrl: p.imageUrl,
              brandName: p.brandName,
              rating: p.rating,
              reviewCount: p.reviewCount,
              isBestseller: p.isBestseller,
              isFeatured: p.isFeatured,
              isNew: p.isNewArrival,
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemCount: items.length,
      ),
    );
  }
}
