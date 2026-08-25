import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/states.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../data/wishlist_repository.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<ProductSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProductSummary>> _load() async {
    final repo = WishlistRepository();
    final raw = await repo.raw();
    return raw.map((e) => ProductSummary.fromJson(e)).toList(growable: false);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: FutureBuilder<List<ProductSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString(), onRetry: _reload);
          }
          final items = snap.data ?? const <ProductSummary>[];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_outline,
              title: 'Wishlist kosong',
              subtitle: 'Tambahkan produk favorit dengan menekan ikon hati.',
              actionLabel: 'Jelajahi Produk',
              onAction: null,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final p = items[i];
                return ProductCard(
                  slug: p.slug,
                  name: p.name,
                  price: p.price,
                  salePrice: p.salePrice,
                  imageUrl: p.imageUrl,
                  brandName: p.brandName,
                  rating: p.rating,
                  reviewCount: p.reviewCount,
                  isBestseller: p.isBestseller,
                  isNew: p.isNewArrival,
                  isFeatured: p.isFeatured,
                  isWishlisted: true,
                  onWishlist: () async {
                    final repo = WishlistRepository();
                    await repo.toggle(p.id);
                    _reload();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
