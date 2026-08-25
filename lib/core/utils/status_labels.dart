/// Maps raw values (order statuses, payment states, etc.) into user-friendly
/// Indonesian labels and theme colors. Keeping the mapping centralized means
/// every screen shows the same wording for a given state.
class StatusLabels {
  StatusLabels._();

  static const Map<String, String> orderStatus = {
    'pending': 'Menunggu Pembayaran',
    'awaiting_payment': 'Menunggu Pembayaran',
    'paid': 'Sudah Dibayar',
    'processing': 'Diproses',
    'shipped': 'Dikirim',
    'delivered': 'Selesai',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    'expired': 'Kedaluwarsa',
    'failed': 'Gagal',
    'refunded': 'Dikembalikan',
  };

  static const Map<String, String> paymentStatus = {
    'pending': 'Belum Dibayar',
    'settlement': 'Lunas',
    'capture': 'Lunas',
    'deny': 'Ditolak',
    'cancel': 'Dibatalkan',
    'expire': 'Kedaluwarsa',
    'refund': 'Dikembalikan',
    'failure': 'Gagal',
    'success': 'Berhasil',
  };

  /// Used by checkout preview, e.g. "BCA Virtual Account"
  static const Map<String, String> paymentMethod = {
    'bank_transfer': 'Transfer Bank',
    'credit_card': 'Kartu Kredit',
    'echannel': 'Mandiri Bill',
    'gopay': 'GoPay',
    'shopeepay': 'ShopeePay',
    'qris': 'QRIS',
    'cstore': 'Indomaret',
  };
}
