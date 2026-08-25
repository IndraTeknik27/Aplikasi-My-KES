import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/states.dart';
import '../../../orders/data/order_repository.dart';
import '../../data/payment_repository.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String orderNumber;
  const PaymentStatusScreen({super.key, required this.orderNumber});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final order = await OrderRepository().detail(widget.orderNumber);
    Payment? payment;
    try {
      payment = await PaymentRepository().status(widget.orderNumber);
    } catch (_) {
      /* no payment yet */
    }
    return {'order': order, 'payment': payment};
  }

  Future<void> _refresh() async {
    setState(() {
      _future = PaymentRepository().refresh(widget.orderNumber).then((
        payment,
      ) async {
        final order = await OrderRepository().detail(widget.orderNumber);
        return {'order': order, 'payment': payment};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pembayaran'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snap.hasError) {
            return ErrorState(
              message: snap.error.toString(),
              onRetry: _refresh,
            );
          }
          final data = snap.data ?? const {};
          final order = data['order'] as Order?;
          final payment = data['payment'] as Payment?;
          if (order == null) {
            return const ErrorState(message: 'Pesanan tidak ditemukan.');
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Hero(order: order, payment: payment),
              const SizedBox(height: AppSpacing.lg),
              _Detail(order: order, payment: payment),
              const SizedBox(height: AppSpacing.lg),
              if (!order.isPaid)
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cek Status Pembayaran'),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.orders),
                icon: const Icon(Icons.list_alt),
                label: const Text('Lihat Semua Pesanan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Order order;
  final Payment? payment;
  const _Hero({required this.order, this.payment});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (order.isPaid) {
      color = AppColors.success;
      icon = Icons.check_circle;
      title = 'Pembayaran Berhasil';
      subtitle = 'Pesanan Anda sedang diproses.';
    } else if (order.isCancelled) {
      color = AppColors.error;
      icon = Icons.cancel;
      title = 'Pesanan Dibatalkan';
      subtitle = 'Pesanan telah dibatalkan.';
    } else {
      color = AppColors.warning;
      icon = Icons.hourglass_top;
      title = 'Menunggu Pembayaran';
      subtitle =
          'Selesaikan pembayaran Anda sebelum batas waktu yang ditentukan.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 56),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No. Pesanan: ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  order.orderNumber,
                  style: const TextStyle(
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
}

class _Detail extends StatelessWidget {
  final Order order;
  final Payment? payment;
  const _Detail({required this.order, this.payment});

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
          if (payment != null) ...[
            _kv(
              'Metode',
              (payment?.paymentType ?? payment?.gateway ?? '-').toString(),
            ),
            _kv('Status', payment?.status ?? '-'),
            if (payment?.transactionId != null)
              _kv('ID Transaksi', payment!.transactionId!),
            if (payment?.vaNumber != null) _kv('VA', payment!.vaNumber!),
            if (payment?.grossAmount != null)
              _kv('Jumlah', Money.format(payment!.grossAmount)),
            if (payment?.paidAt != null)
              _kv('Dibayar', DateFormatter.dateTime(payment!.paidAt)),
            if (payment?.expiredAt != null)
              _kv('Kadaluarsa', DateFormatter.dateTime(payment!.expiredAt)),
          ] else
            _kv('Status', order.status),
          const Divider(),
          _kv(
            'Total',
            Money.format(order.total),
            weight: FontWeight.w800,
            size: 14,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Lihat Invoice'),
              onPressed: () =>
                  context.push('/orders/${order.orderNumber}/invoice'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(
    String key,
    String value, {
    FontWeight weight = FontWeight.w500,
    double size = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: size,
                fontWeight: weight,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
