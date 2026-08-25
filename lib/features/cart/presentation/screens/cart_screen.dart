import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/states.dart';
import '../../bloc/cart_bloc.dart';
import '../../data/cart_repository.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: BlocConsumer<CartBloc, CartState>(
        listenWhen: (p, c) =>
            p.lastMessage != c.lastMessage || p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.lastMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.lastMessage!)));
          }
          if (state.errorMessage != null && state.lastMessage == null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == CartStatus.loading && state.cart.isEmpty) {
            return const LoadingIndicator();
          }
          if (state.cart.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjangmu kosong',
              subtitle: 'Yuk, mulai belanja produk energy solution.',
              actionLabel: 'Mulai Belanja',
              onAction: () => context.go(Routes.catalog),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CartBloc>().add(const CartLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                if (state.cart.customerId == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: InlineBanner(
                      message: 'Login untuk menyimpan keranjang ke akun Anda.',
                      icon: Icons.info_outline,
                      background: AppColors.primary.withValues(alpha: 0.08),
                      foreground: AppColors.primary,
                    ),
                  ),
                ...state.cart.items.map(
                  (it) => Column(
                    children: [
                      ProductTile(
                        slug: it.slug ?? '',
                        name: it.name ?? 'Produk',
                        imageUrl: it.imageUrl,
                        price: it.price,
                        priceLabel: Money.format(it.subtotal),
                        quantity: it.qty,
                        showQtyControls: true,
                        onQtyChange: (v) => context.read<CartBloc>().add(
                          CartItemUpdated(it.id, v),
                        ),
                        onRemove: () => _confirmRemove(it),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _CouponSection(state: state),
                const SizedBox(height: AppSpacing.lg),
                _Summary(state: state),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LoadingButton(
                onPressed: state.mutationInProgress
                    ? null
                    : () => context.push(Routes.checkout),
                child: Text('Checkout  •  ${Money.format(state.cart.total)}'),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(CartItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus dari keranjang?'),
        content: Text('"${item.name ?? 'Produk ini'}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      context.read<CartBloc>().add(CartItemRemoved(item.id));
    }
  }
}

class _CouponSection extends StatefulWidget {
  final CartState state;
  const _CouponSection({required this.state});

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.state.cart;
    if (cart.hasCoupon) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kupon diterapkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      cart.couponCode!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.success),
                onPressed: () =>
                    context.read<CartBloc>().add(const CartCouponRemoved()),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Kode kupon',
                prefixIcon: Icon(Icons.local_offer_outlined),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: widget.state.mutationInProgress
                ? null
                : () {
                    if (_ctl.text.trim().isEmpty) return;
                    context.read<CartBloc>().add(
                      CartCouponApplied(_ctl.text.trim()),
                    );
                  },
            child: const Text('Pakai'),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CartState state;
  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = state.cart;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _row('Subtotal (${c.itemCount} item)', Money.format(c.subtotal)),
          const SizedBox(height: 6),
          if (c.discount > 0)
            _row(
              'Diskon',
              '- ${Money.format(c.discount)}',
              color: AppColors.success,
            ),
          if (c.discount > 0) const SizedBox(height: 6),
          _row('Pengiriman', Money.format(c.shippingCost)),
          const SizedBox(height: 6),
          _row('Pajak', Money.format(c.tax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          _row(
            'Total',
            Money.format(c.total),
            weight: FontWeight.w800,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    FontWeight weight = FontWeight.w500,
    double size = 13,
    Color? color,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontSize: size,
              fontWeight: weight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: size,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }
}
