import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/payments/midtrans_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/states.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../cart/bloc/cart_bloc.dart';
import '../../../profile/data/address_repository.dart';
import '../../data/checkout_repository.dart';
import '../../data/payment_repository.dart';

/// Single screen handling: select address → choose shipping → place order →
/// open Midtrans Snap.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _checkoutRepo = CheckoutRepository();
  final _paymentRepo = PaymentRepository();
  final _addressRepo = AddressRepository();

  Map<String, dynamic>? _preview;
  List<Address> _addresses = [];
  Address? _selectedAddress;
  String _selectedCourier = 'jne';
  String _selectedService = 'REG';
  String _couponCode = '';
  String _paymentMethod = 'midtrans';
  bool _loading = true;
  bool _cartLoading = true;
  bool _placing = false;
  String? _error;
  CartState? _cartState;

  @override
  void initState() {
    super.initState();
    // Ensure cart is loaded before fetching preview
    context.read<CartBloc>().add(const CartLoadRequested());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthBloc>().state;
      if (auth is! AuthAuthenticated) {
        setState(() {
          _loading = false;
          _error = 'Silakan login untuk checkout.';
        });
        return;
      }
      _addresses = await _addressRepo.list();
      _selectedAddress = _addresses.isEmpty
          ? null
          : _addresses.firstWhere(
              (a) => a.isPrimary,
              orElse: () => _addresses.first,
            );
      await _refreshPreview();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshPreview() async {
    try {
      final res = await _checkoutRepo.preview(
        shippingAddressId: _selectedAddress?.id,
        shippingCourier: _selectedCourier,
        couponCode: _couponCode.isEmpty ? null : _couponCode,
      );
      if (mounted && res.isNotEmpty) {
        setState(() => _preview = res);
      }
    } catch (e) {
      // Silently ignore preview errors — user can still see cart items via CartBloc
      debugPrint('[Checkout] Preview error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          _cartState = state;
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            _cartState = cartState;
            return _loading
              ? const LoadingIndicator()
              : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : _buildContent();
        },
      ),
    ),
    bottomNavigationBar: _buildBottomBar(),
    );
  }


  bool get _hasItems {
    if (_preview != null && (_preview!['items'] as List?)?.isNotEmpty == true) return true;
    final cartState = context.read<CartBloc>().state;
    return cartState.cart.items.isNotEmpty;
  }

  double get _cartTotal {
    if (_preview != null) {
      return _toDouble(_preview!['total']) ?? 0;
    }
    return context.read<CartBloc>().state.cart.total;
  }

  Widget _buildContent() {
    // _preview can be null if API preview failed — fallback to CartBloc data
    final p = _preview;
    final hasCartItems = (_cartState ?? context.read<CartBloc>().state).cart.items.isNotEmpty;
    if (p == null && !hasCartItems) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            const Text('Tidak ada item di keranjang.'),
          ],
        ),
      );
    }
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => b is AuthUnauthenticated,
      listener: (_, _) => context.go(Routes.login),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Section(
            title: 'Alamat Pengiriman',
            trailing: TextButton(
              onPressed: () async {
                await context.push(Routes.addresses);
                await _load();
              },
              child: const Text('Kelola'),
            ),
            child: _addresses.isEmpty
                ? _buildAddressEmpty()
                : RadioGroup<Address>(
                    groupValue: _selectedAddress,
                    onChanged: (sel) async {
                      setState(() => _selectedAddress = sel);
                      await _refreshPreview();
                    },
                    child: Column(
                      children: _addresses
                          .map(
                            (a) => RadioListTile<Address>(
                              value: a,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${a.recipient}  ·  ${a.phone}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                a.fullAddress ??
                                    '${a.addressLine1}, ${a.district}, ${a.city}, ${a.province} ${a.postalCode}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_selectedAddress != null &&
              (_selectedAddress!.senderName != null ||
                  _selectedAddress!.senderAddress != null))
            _buildSenderAddressSection(),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Metode Pengiriman',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  children: ['jne', 'pos', 'tiki', 'sicepat', 'jnt']
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c.toUpperCase()),
                          selected: _selectedCourier == c,
                          onSelected: (_) async {
                            setState(() {
                              _selectedCourier = c;
                              _selectedService = 'REG';
                            });
                            await _refreshPreview();
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children:
                      const [
                            _ServiceChip('REG', 'Regular'),
                            _ServiceChip('YES', 'Yakin Esok Sampai'),
                            _ServiceChip('OKE', 'Ongkos Kirim Ekonomis'),
                          ]
                          .map(
                            (c) => ChoiceChip(
                              label: Text('${c.code} · ${c.label}'),
                              selected: _selectedService == c.code,
                              onSelected: (_) async {
                                setState(() => _selectedService = c.code);
                                await _refreshPreview();
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(title: 'Item Pesanan', child: _buildItems(_preview)),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Pembayaran',
            child: RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (v) =>
                  setState(() => _paymentMethod = v ?? 'midtrans'),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'midtrans',
                    title: Text('Midtrans (Snap)'),
                    subtitle: Text(
                      'Virtual Account, E-Wallet, QRIS, Kartu Kredit',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'bank_transfer',
                    title: Text('Transfer Bank Manual'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Kupon',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => _couponCode = v.trim().toUpperCase(),
                    decoration: const InputDecoration(
                      hintText: 'Kode kupon',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _refreshPreview,
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTotals(_preview),
        ],
      ),
    );
  }

  Widget _buildItems(Map<String, dynamic>? p) {
    // Use CartBloc items when preview is not available
    if (p == null || (p['items'] as List?)?.isEmpty != false) {
      final cartItems = (_cartState ?? context.read<CartBloc>().state).cart.items;
      if (cartItems.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text('Tidak ada item'),
        );
      }
      return Column(
        children: cartItems.map<Widget>((item) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.name ?? 'Produk',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('× ${item.qty}',
                style: const TextStyle(fontSize: 12)),
            trailing: Text(
              Money.format(item.subtotal),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      );
    }

    final items = (p['items'] as List?) ?? const [];
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text('Tidak ada item'),
      );
    }
    return Column(
      children: items.map<Widget>((raw) {
        final i = raw is Map ? Map<String, dynamic>.from(raw) : const {};
        final name = (i['name'] ?? 'Produk').toString();
        final qty = (i['qty'] as num?)?.toInt() ?? 1;
        final subtotal = _toDouble(i['subtotal']) ?? 0;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('× $qty', style: const TextStyle(fontSize: 12)),
          trailing: Text(
            Money.format(subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotals(Map<String, dynamic>? p) {
    double subtotal = 0, discount = 0, tax = 0, shipping = 0, total = 0;

    if (p != null && p.isNotEmpty) {
      subtotal = _toDouble(p['subtotal']) ?? 0;
      discount = _toDouble(p['discount']) ?? 0;
      tax = _toDouble(p['tax']) ?? 0;
      shipping = _toDouble(p['shipping_cost']) ?? 0;
      total = _toDouble(p['total']) ?? 0;
    } else {
      final cart = (_cartState ?? context.read<CartBloc>().state).cart;
      subtotal = cart.subtotal;
      discount = cart.discount;
      tax = cart.tax;
      shipping = cart.shippingCost;
      total = cart.total;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _row('Subtotal', Money.format(subtotal)),
          if (discount > 0)
            _row(
              'Diskon',
              '- ${Money.format(discount)}',
              color: AppColors.success,
            ),
          _row('Pengiriman', Money.format(shipping)),
          _row('Pajak', Money.format(tax)),
          const Divider(),
          _row('Total', Money.format(total), weight: FontWeight.w800, size: 16),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (!_hasItems) return null;
    final total = _cartTotal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LoadingButton(
          onPressed: _placing ? null : () => _placeOrder(),
          loading: _placing,
          child: Text('Bayar Sekarang  •  ${Money.format(total)}'),
        ),
      ),
    );
  }

  Widget _buildAddressEmpty() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const Text('Belum ada alamat tersimpan.'),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              await context.push(Routes.addresses);
              await _load();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Tambah Alamat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderAddressSection() {
    final addr = _selectedAddress!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Alamat Pengirim',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            addr.senderName ?? 'E-Clont Solusi Energi',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (addr.senderPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              addr.senderPhone!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (addr.senderAddress != null) ...[
            const SizedBox(height: 2),
            Text(
              addr.senderAddress!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (addr.senderNotes != null && addr.senderNotes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Catatan: ${addr.senderNotes}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk checkout.')),
      );
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alamat pengiriman terlebih dahulu.'),
        ),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final user = authState.user;
      final place = await _checkoutRepo.placeOrder({
        'shipping_address_id': _selectedAddress!.id,
        'shipping_courier': _selectedCourier,
        'shipping_service': _selectedService,
        'shipping_cost': _toDouble(_preview?['shipping_cost']) ?? 0,
        'payment_method': _paymentMethod,
        'customer_name': user.name,
        'customer_email': user.email,
        'customer_phone': user.phone ?? '081234567890',
        if (_couponCode.isNotEmpty) 'coupon_code': _couponCode,
        'billing_same_as_shipping': true,
      });
      final orderNumber = (place['order_number'] ?? '').toString();
      if (orderNumber.isEmpty) {
        throw Exception('Order tidak memiliki nomor.');
      }

      if (_paymentMethod == 'midtrans') {
        try {
          final payment = await _paymentRepo.initiate(orderNumber);
          final redirect = payment.redirectUrl;
          if (redirect != null && redirect.isNotEmpty) {
            await _openMidtransWeb(redirect, orderNumber);
            return;
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuka pembayaran: $e')),
          );
        }
      }

      if (!mounted) return;
      context.go('${Routes.paymentStatus}/$orderNumber');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _openMidtransWeb(String url, String orderNumber) async {
    // Open Midtrans Snap via the [MidtransService] shim. When the native
    // SDK is enabled (after MidtransAppConfig.initSdk has been wired in
    // main.dart), it renders the Snap sheet directly on top of the app
    // and returns a structured result. With useNativeSdk=false, the
    // webview fallback is used and we forward to the payment-status
    // screen on return so the user can refresh.
    HapticFeedback.lightImpact();
    await MidtransService.openRedirect(url);
    if (!mounted) return;
    context.go('${Routes.paymentStatus}/$orderNumber');
  }

  Widget _row(
    String label,
    String value, {
    FontWeight weight = FontWeight.w500,
    double size = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _ServiceChip {
  final String code;
  final String label;
  const _ServiceChip(this.code, this.label);
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
