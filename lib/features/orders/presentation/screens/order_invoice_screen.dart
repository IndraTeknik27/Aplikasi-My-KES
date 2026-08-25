import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/states.dart';
import '../../data/order_repository.dart';
import 'invoice_pdf.dart';

/// Invoice is rendered from JSON returned by `GET /orders/{n}/invoice`.
/// Future enhancement: pipe the JSON to a PDF via the `printing` package
/// so users can share/print. For now we show a clean on-screen view.
class OrderInvoiceScreen extends StatefulWidget {
  final String orderNumber;
  const OrderInvoiceScreen({super.key, required this.orderNumber});

  @override
  State<OrderInvoiceScreen> createState() => _OrderInvoiceScreenState();
}

class _OrderInvoiceScreenState extends State<OrderInvoiceScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderRepository().invoice(widget.orderNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak / Bagikan',
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snap.hasError) {
            return ErrorState(message: snap.error.toString());
          }
          final data = snap.data ?? const {};
          return _InvoiceView(data: data);
        },
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final data = await _future;
    if (!context.mounted) return;
    try {
      await InvoicePdf.printOrShare(
        data,
        jobName: 'Invoice-${data['invoice_number'] ?? ''}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal cetak: $e')));
    }
  }
}

class _InvoiceView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InvoiceView({required this.data});

  @override
  Widget build(BuildContext context) {
    final invNumber = (data['invoice_number'] ?? '-').toString();
    final orderNumber = (data['order_number'] ?? '-').toString();
    final invoiceDate = (data['invoice_date'] ?? '-').toString();
    final company = (data['company'] as Map?) ?? const {};
    final customer = (data['customer'] as Map?) ?? const {};
    final items = (data['items'] as List?) ?? const [];
    final shippingAddress = (data['shipping_address'] as Map?) ?? const {};

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'KARTEKS ENERGY SOLUTION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    invNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (company['address'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Telp: ${company['phone'] ?? '-'}  ·  Email: ${company['email'] ?? '-'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kepada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (customer['name'] ?? '-').toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          (customer['phone'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          (customer['email'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'No. Pesanan',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        orderNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        invoiceDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Items
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Produk',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Subtotal',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((raw) {
                final i = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : const {};
                final name = (i['name'] ?? '').toString();
                final qty = (i['qty'] as num?)?.toInt() ?? 0;
                final subtotal =
                    (i['subtotal_formatted'] ??
                            Money.format(
                              (i['subtotal'] as num?)?.toDouble() ?? 0,
                            ))
                        .toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(name, style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '$qty',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          subtotal,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Totals
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              _row(
                'Subtotal',
                (data['subtotal_formatted'] ??
                        Money.format(
                          (data['subtotal'] as num?)?.toDouble() ?? 0,
                        ))
                    .toString(),
              ),
              if ((data['discount_formatted'] ?? '').toString().isNotEmpty &&
                  (data['discount'] as num? ?? 0) > 0)
                _row(
                  'Diskon',
                  (data['discount_formatted'] ?? '').toString(),
                  color: AppColors.success,
                ),
              _row(
                'Pengiriman',
                (data['shipping_cost_formatted'] ??
                        Money.format(
                          (data['shipping_cost'] as num?)?.toDouble() ?? 0,
                        ))
                    .toString(),
              ),
              _row(
                'Pajak',
                (data['tax_formatted'] ??
                        Money.format((data['tax'] as num?)?.toDouble() ?? 0))
                    .toString(),
              ),
              const Divider(),
              _row(
                'Total',
                (data['total_formatted'] ??
                        Money.format((data['total'] as num?)?.toDouble() ?? 0))
                    .toString(),
                weight: FontWeight.w800,
                size: 15,
              ),
            ],
          ),
        ),
        if (shippingAddress.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
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
                  'Alamat Pengiriman',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  (shippingAddress['recipient'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  (shippingAddress['phone'] ?? '').toString(),
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  (shippingAddress['address_line_1'] ?? '').toString(),
                  style: const TextStyle(fontSize: 11),
                ),
                if ((shippingAddress['address_line_2'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Text(
                    (shippingAddress['address_line_2']).toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                Text(
                  '${shippingAddress['district'] ?? ''}, ${shippingAddress['city'] ?? ''}, ${shippingAddress['province'] ?? ''} ${shippingAddress['postal_code'] ?? ''}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    FontWeight weight = FontWeight.w500,
    double size = 12,
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
