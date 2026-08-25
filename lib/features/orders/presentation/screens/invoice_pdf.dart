import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/formatters.dart';

/// Renders the invoice JSON returned by `GET /orders/{n}/invoice` into a
/// shareable PDF document using the `printing` + `pdf` packages.
///
/// Backend shape (from OrderController::invoice):
/// ```
/// {
///   invoice_number, order_number, invoice_date,
///   company: { name, address, phone, email, website },
///   customer: { name, email, phone },
///   shipping_address, billing_address,        // plain address maps
///   items: [{ name, sku, qty, price, price_formatted, subtotal,
///             subtotal_formatted }],
///   subtotal, subtotal_formatted,
///   discount, discount_formatted,
///   tax, tax_formatted,
///   shipping_cost, shipping_cost_formatted,
///   total, total_formatted,
///   coupon_code?
/// }
/// ```
class InvoicePdf {
  InvoicePdf._(this.data);

  final Map<String, dynamic> data;

  static Future<InvoicePdf> load(String orderNumber) async {
    // We already fetch the invoice JSON in OrderInvoiceScreen; passing it
    // through avoids a second network round-trip. If you want a fresh copy,
    // hit OrderRepository().invoice(orderNumber) instead.
    // This helper is currently unused but kept for future screens that
    // want to generate a PDF without going through the screen.
    return InvoicePdf._({});
  }

  /// Build a printable PDF byte stream for the invoice data.
  Future<Uint8List> buildPdf() async {
    final doc = pw.Document();

    final company =
        (data['company'] as Map?)?.cast<String, dynamic>() ?? const {};
    final customer =
        (data['customer'] as Map?)?.cast<String, dynamic>() ?? const {};
    final items = (data['items'] as List?)?.cast<Map>() ?? const [];
    final shipping =
        (data['shipping_address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final id = (data['invoice_number'] ?? '-').toString();
    final orderNum = (data['order_number'] ?? '-').toString();
    final date = _parseDate(data['invoice_date']);
    final currency = 'Rp';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(company, id),
              pw.SizedBox(height: 24),
              _addressBlock(customer, shipping),
              pw.SizedBox(height: 20),
              _metaBlock(orderNum, date),
              pw.SizedBox(height: 20),
              _itemsTable(items, currency),
              pw.SizedBox(height: 16),
              _totals(),
              if ((data['coupon_code'] ?? '').toString().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'Kupon: ${data['coupon_code']}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              pw.SizedBox(height: 32),
              _footer(company),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Show the system print/share sheet for the invoice PDF. Use this from a
  /// screen on tap of "Cetak / Bagikan".
  static Future<void> printOrShare(
    Map<String, dynamic> data, {
    String jobName = 'Invoice',
  }) async {
    final pdfBytes = await InvoicePdf._(data).buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: jobName);
  }

  // -- Layout helpers --

  pw.Widget _header(Map company, String invoiceNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              (company['name'] ?? 'KARTEKS Energy Solution').toString(),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              (company['address'] ?? '').toString(),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Text(
              'Telp: ${company['phone'] ?? '-'}   '
              'Email: ${company['email'] ?? '-'}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(invoiceNumber, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  pw.Widget _addressBlock(Map customer, Map shipping) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _label('Ditagihkan kepada'),
              pw.SizedBox(height: 4),
              pw.Text(
                (customer['name'] ?? '-').toString(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                (customer['phone'] ?? '').toString(),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                (customer['email'] ?? '').toString(),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _label('Dikirim ke'),
              pw.SizedBox(height: 4),
              pw.Text(
                (shipping['recipient'] ?? customer['name'] ?? '-').toString(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                (shipping['address_line_1'] ?? '').toString(),
                style: const pw.TextStyle(fontSize: 9),
              ),
              if ((shipping['address_line_2'] ?? '').toString().isNotEmpty)
                pw.Text(
                  (shipping['address_line_2']).toString(),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.Text(
                '${shipping['district'] ?? ''}, ${shipping['city'] ?? ''}, '
                '${shipping['province'] ?? ''} ${shipping['postal_code'] ?? ''}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _metaBlock(String orderNumber, DateTime? date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _kv('No. Pesanan', orderNumber),
          _kv('Tanggal', _fmtDate(date)),
          _kv('Mata uang', 'IDR'),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(List items, String currency) {
    final headers = ['Produk', 'Qty', 'Harga', 'Subtotal'];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...items.map((row) {
          final m = row.cast<String, dynamic>();
          return pw.TableRow(
            children: [
              _cell((m['name'] ?? '').toString(), align: pw.TextAlign.left),
              _cell('${m['qty'] ?? 0}', align: pw.TextAlign.right),
              _cell(_money(m['price']), align: pw.TextAlign.right),
              _cell(_money(m['subtotal']), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _totals() {
    final subtotal = _money(data['subtotal']);
    final discount = _money(data['discount']);
    final tax = _money(data['tax']);
    final shipping = _money(data['shipping_cost']);
    final total = _money(data['total']);

    pw.Widget row(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: bold ? 12 : 10,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: bold ? 12 : 10,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 240,
        child: pw.Column(
          children: [
            row('Subtotal', subtotal),
            if (_toDouble(data['discount']) > 0) row('Diskon', '- $discount'),
            row('Pengiriman', shipping),
            row('Pajak', tax),
            pw.Divider(),
            row('Total', total, bold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _footer(Map company) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          'Terima kasih telah berbelanja di KARTEKS Energy Solution.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        if ((company['website'] ?? '').toString().isNotEmpty)
          pw.Text(
            (company['website']).toString(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
      ],
    );
  }

  pw.Widget _label(String text) => pw.Text(
    text.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey600,
    ),
  );

  pw.Widget _kv(String key, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          key,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: align,
      ),
    );
  }

  String _money(Object? raw) {
    if (raw == null) return '-';
    if (raw is num) return Money.format(raw.toDouble());
    if (raw is String) return Money.format(double.tryParse(raw) ?? 0);
    return raw.toString();
  }

  double _toDouble(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  }
}
