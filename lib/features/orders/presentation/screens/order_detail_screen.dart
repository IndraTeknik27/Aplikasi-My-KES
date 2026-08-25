import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/status_labels.dart';
import '../../../../shared/widgets/states.dart';
import '../../data/order_repository.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderNumber;
  const OrderDetailScreen({super.key, required this.orderNumber});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderRepository().detail(widget.orderNumber);
  }

  Future<void> _reload() async {
    setState(() {
      _future = OrderRepository().detail(widget.orderNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: FutureBuilder<Order>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString(), onRetry: _reload);
          }
          final order = snap.data;
          if (order == null) {
            return const ErrorState(message: 'Pesanan tidak ditemukan.');
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Header(order: order),
              const SizedBox(height: AppSpacing.md),
              if (order.timestamps.shippedAt != null ||
                  order.timestamps.deliveredAt != null ||
                  order.shippingTrackingNumber != null)
                _TrackingCard(order: order),
              const SizedBox(height: AppSpacing.md),
              _ItemsCard(order: order),
              const SizedBox(height: AppSpacing.md),
              _SummaryCard(order: order),
              const SizedBox(height: AppSpacing.md),
              _Actions(order: order, onChanged: _reload),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Order order;
  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  StatusLabels.orderStatus[order.status] ?? order.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dibuat ${DateFormatter.dateTime(order.createdAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'completed':
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
      case 'expired':
      case 'failed':
        return AppColors.statusCancelled;
      case 'shipped':
      case 'ready_to_ship':
        return AppColors.statusShipped;
      default:
        return AppColors.statusPending;
    }
  }
}

class _TrackingCard extends StatelessWidget {
  final Order order;
  const _TrackingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Pelacakan',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (order.shippingCourier != null)
            _kv(
              'Kurir',
              '${order.shippingCourier!.toUpperCase()} · ${order.shippingService ?? ''}',
            ),
          if (order.shippingTrackingNumber != null)
            _kv('No. Resi', order.shippingTrackingNumber!),
          if (order.timestamps.paidAt != null)
            _kv('Dibayar', DateFormatter.dateTime(order.timestamps.paidAt)),
          if (order.timestamps.shippedAt != null)
            _kv('Dikirim', DateFormatter.dateTime(order.timestamps.shippedAt)),
          if (order.timestamps.deliveredAt != null)
            _kv(
              'Diterima',
              DateFormatter.dateTime(order.timestamps.deliveredAt),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${it.qty}x',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name ?? 'Produk',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${Money.format(it.price)} × ${it.qty}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Money.format(it.subtotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
}

class _SummaryCard extends StatelessWidget {
  final Order order;
  const _SummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _row('Subtotal', Money.format(order.subtotal)),
          if (order.discount > 0)
            _row(
              'Diskon',
              '- ${Money.format(order.discount)}',
              color: AppColors.success,
            ),
          _row('Pengiriman', Money.format(order.shippingCost)),
          _row('Pajak', Money.format(order.tax)),
          const Divider(),
          _row(
            'Total',
            Money.format(order.total),
            weight: FontWeight.w800,
            size: 15,
          ),
          if (order.shippingAddress is Map) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            _addressBlock(),
          ],
        ],
      ),
    );
  }

  Widget _addressBlock() {
    final sa = order.shippingAddress as Map?;
    if (sa == null) return const SizedBox.shrink();
    final parts = <String>[
      (sa['recipient'] ?? '').toString(),
      (sa['phone'] ?? '').toString(),
      (sa['address_line_1'] ?? '').toString(),
      if ((sa['address_line_2'] ?? '').toString().isNotEmpty)
        (sa['address_line_2']).toString(),
      '${sa['district'] ?? ''}, ${sa['city'] ?? ''}, ${sa['province'] ?? ''} ${sa['postal_code'] ?? ''}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .where((p) => p.trim().isNotEmpty)
          .map(
            (p) => Text(
              p,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _row(
    String label,
    String value, {
    FontWeight weight = FontWeight.w500,
    double size = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final Order order;
  final Future<void> Function() onChanged;
  const _Actions({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final canCancel = !order.isPaid && !order.isCancelled && !order.isCompleted;
    final canConfirm = order.status == 'shipped' || order.status == 'delivered';
    return Column(
      children: [
        if (canCancel)
          OutlinedButton.icon(
            onPressed: () => _confirmCancel(context),
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            label: const Text(
              'Batalkan Pesanan',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        if (canConfirm)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelivery(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Diterima'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push('/orders/${order.orderNumber}/invoice'),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Lihat Invoice'),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final reason = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Batalkan pesanan?'),
          content: TextField(
            controller: reason,
            decoration: const InputDecoration(
              labelText: 'Alasan pembatalan',
              hintText: 'Minimal 5 karakter',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Batalkan'),
            ),
          ],
        ),
      );
      if (ok == true && reason.text.trim().length >= 5) {
        try {
          await OrderRepository().cancel(
            order.orderNumber,
            reason: reason.text.trim(),
          );
          await onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
    } finally {
      reason.dispose();
    }
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi diterima?'),
        content: const Text('Pastikan pesanan sudah sampai di tangan Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Belum'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Sudah'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await OrderRepository().confirmDelivery(order.orderNumber);
        await onChanged();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}
