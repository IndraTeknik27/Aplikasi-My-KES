import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/formatters.dart';
import 'common.dart';
import 'states.dart';

/// Reusable product card.
/// - Horizontal variant for lists
/// - Compact variant for grids
class ProductCard extends StatelessWidget {
  final String slug;
  final String name;
  final double price;
  final double? salePrice;
  final String? imageUrl;
  final String? brandName;
  final String? categoryName;
  final double? rating;
  final int? reviewCount;
  final bool isBestseller;
  final bool isNew;
  final bool isFeatured;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.slug,
    required this.name,
    required this.price,
    this.salePrice,
    this.imageUrl,
    this.brandName,
    this.categoryName,
    this.rating,
    this.reviewCount,
    this.isBestseller = false,
    this.isNew = false,
    this.isFeatured = false,
    this.onTap,
    this.onWishlist,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap ?? () => context.push('/product/$slug'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SafeNetworkImage(
                      url: imageUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                  if (isBestseller || isNew || isFeatured)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isBestseller)
                            const StatusChip(
                              label: 'BEST SELLER',
                              color: AppColors.secondary,
                            ),
                          if (isNew) ...[
                            const SizedBox(height: 4),
                            const StatusChip(
                              label: 'BARU',
                              color: AppColors.primary,
                            ),
                          ],
                          if (isFeatured) ...[
                            const SizedBox(height: 4),
                            const StatusChip(
                              label: 'FEATURED',
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (onWishlist != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted
                                ? AppColors.secondary
                                : Colors.white,
                            size: 18,
                          ),
                          onPressed: onWishlist,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brandName != null)
                    Text(
                      brandName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (rating != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1) +
                                (reviewCount != null ? ' ($reviewCount)' : ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (salePrice != null) ...[
                        Flexible(
                          child: Text(
                            Money.format(salePrice),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          Money.format(salePrice ?? price),
                          style: TextStyle(
                            fontSize: salePrice != null ? 11 : 14,
                            color: salePrice != null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontWeight: salePrice != null
                                ? FontWeight.w400
                                : FontWeight.w800,
                            decoration: salePrice != null
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal card for use in cart, wishlist, recent orders, etc.
class ProductTile extends StatelessWidget {
  final String slug;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final double? price;
  final String? priceLabel;
  final int? quantity;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? trailing;
  final bool showQtyControls;
  final ValueChanged<int>? onQtyChange;

  const ProductTile({
    super.key,
    required this.slug,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.price,
    this.priceLabel,
    this.quantity,
    this.onTap,
    this.onRemove,
    this.trailing,
    this.showQtyControls = false,
    this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.push('/product/$slug'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeNetworkImage(
              url: imageUrl,
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        priceLabel ??
                            (price != null ? Money.format(price) : ''),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (quantity != null && !showQtyControls)
                        Text(
                          '×$quantity',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (showQtyControls) ...[
                    const SizedBox(height: 6),
                    _QtyStepper(value: quantity ?? 1, onChanged: onQtyChange),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Hapus',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  const _QtyStepper({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(
            icon: Icons.remove,
            onTap: value > 1 ? () => onChanged?.call(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _qtyBtn(icon: Icons.add, onTap: () => onChanged?.call(value + 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Builder for a `Skeleton` product card placeholder.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 1, child: Skeleton(radius: 0)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 32, height: 8),
                SizedBox(height: 6),
                Skeleton(height: 10),
                SizedBox(height: 4),
                Skeleton(width: 80, height: 10),
                SizedBox(height: 8),
                Skeleton(width: 100, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
