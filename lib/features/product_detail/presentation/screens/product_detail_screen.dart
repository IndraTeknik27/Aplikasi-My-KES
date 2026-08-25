import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/states.dart';
import '../../../cart/bloc/cart_bloc.dart';
import '../../../catalog/data/catalog_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  int? _selectedVariationId;
  int _imageIndex = 0;

  late Future<ProductDetail> _detailFuture;
  late Future<List<ProductSummary>> _relatedFuture;

  @override
  void initState() {
    super.initState();
    final repo = CatalogRepository();
    _detailFuture = repo.productDetail(widget.slug);
    _relatedFuture = repo.relatedProducts(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ProductDetail>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: SafeArea(child: LoadingIndicator()));
          }
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: ErrorState(
                message: snap.error.toString(),
                onRetry: () => setState(() {
                  _detailFuture = CatalogRepository().productDetail(
                    widget.slug,
                  );
                }),
              ),
            );
          }
          final p = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.go('/cart'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(background: _buildGallery(p)),
              ),
              SliverToBoxAdapter(child: _buildInfo(p)),
              if (p.variations.isNotEmpty)
                SliverToBoxAdapter(child: _buildVariations(p)),
              if (p.description != null && p.description!.isNotEmpty)
                SliverToBoxAdapter(child: _buildDescription(p)),
              if (p.specifications != null && p.specifications!.isNotEmpty)
                SliverToBoxAdapter(child: _buildSpecs(p)),
              SliverToBoxAdapter(child: _buildReviewsTeaser(p)),
              SliverToBoxAdapter(child: _buildRelated(_relatedFuture)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_outlined),
                onPressed: () {},
                tooltip: 'Chat',
              ),
              IconButton(
                icon: const Icon(Icons.favorite_outline),
                onPressed: () {},
                tooltip: 'Wishlist',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Tambah ke Keranjang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(ProductDetail p) {
    if (p.images.isEmpty) {
      return Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 60,
          color: AppColors.textMuted,
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            itemCount: p.images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) =>
                SafeNetworkImage(url: p.images[i].url, fit: BoxFit.contain),
          ),
        ),
        if (p.images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < p.images.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _imageIndex == i
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(ProductDetail p) {
    final priceToShow = p.salePrice ?? p.price;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.brand is Map && (p.brand as Map)['name'] != null)
            Text(
              ((p.brand as Map)['name']).toString().toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (p.rating != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  p.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (p.reviewCount != null)
                  Text(
                    ' (${p.reviewCount} ulasan)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 8),
                if (p.salesCount != null)
                  Text(
                    '· ${p.salesCount} terjual',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(priceToShow),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (p.salePrice != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    Money.format(p.price),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.stockQty != null && p.stockQty! > 0
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  p.stockQty != null && p.stockQty! > 0
                      ? 'Stok: ${p.stockQty}'
                      : 'Stok habis',
                  style: TextStyle(
                    color: p.stockQty != null && p.stockQty! > 0
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariations(ProductDetail p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Varian',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: p.variations
                .map(
                  (v) => ChoiceChip(
                    label: Text(v.name),
                    selected: _selectedVariationId == v.id,
                    onSelected: (sel) {
                      setState(() {
                        _selectedVariationId = sel ? v.id : null;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ProductDetail p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            p.description!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecs(ProductDetail p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spesifikasi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...p.specifications!.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      s.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTeaser(ProductDetail p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(Icons.reviews_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                p.reviewCount != null && p.reviewCount! > 0
                    ? 'Lihat ${p.reviewCount} ulasan pembeli'
                    : 'Belum ada ulasan untuk produk ini',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRelated(Future<List<ProductSummary>> future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Produk Terkait'),
        FutureBuilder<List<ProductSummary>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemBuilder: (ctx, i) => SizedBox(
                  width: 160,
                  child: ProductCard(
                    slug: items[i].slug,
                    name: items[i].name,
                    price: items[i].price,
                    salePrice: items[i].salePrice,
                    imageUrl: items[i].imageUrl,
                    brandName: items[i].brandName,
                    isBestseller: items[i].isBestseller,
                    isNew: items[i].isNewArrival,
                  ),
                ),
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemCount: items.length,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    late ProductDetail p;
    p = await _detailFuture;
    if (!context.mounted) return;
    final variationId = _selectedVariationId;
    if (variationId != null) {
      context.read<CartBloc>().add(
        CartItemAdded(
          itemableType: 'variation',
          itemableId: variationId,
          qty: _qty,
        ),
      );
    } else {
      context.read<CartBloc>().add(
        CartItemAdded(itemableType: 'product', itemableId: p.id, qty: _qty),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ditambahkan ke keranjang'),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
