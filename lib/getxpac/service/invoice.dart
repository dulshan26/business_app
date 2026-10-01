import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:own/getxpac/sales/sales_model.dart';
import 'package:printing/printing.dart';

class InvoicePdfService {
  // Brand colors matching the docx style
  static const PdfColor primaryNavy = PdfColor.fromInt(0xFF102A43);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFE6EEF5);
  static const PdfColor borderGrey = PdfColor.fromInt(0xFFB8C2CC);

  static Future<Uint8List> generateInvoice({
    required SalesModel sales,
    Uint8List? logoBytes,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final ttf = await PdfGoogleFonts.robotoRegular();
    final boldTtf = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
    );

    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd / MM / yyyy');

    // Safely parse date
    final DateTime createdAtDate = sales.createdAt;
    final String dateString = dateFormat.format(createdAtDate);

    // ─────────────────────────────────────────────────────────────────────────
    // 🧮 CALCULATE SUBTOTAL, SHIPPING, & DISCOUNT
    // ─────────────────────────────────────────────────────────────────────────
    double calculatedItemsTotal = 0.0;

    if (sales.items.isNotEmpty) {
      for (var item in sales.items) {
        final double itemPrice = (item['price'] is num)
            ? (item['price'] as num).toDouble()
            : 0.0;
        final int itemQty = (item['quantity'] is num)
            ? (item['quantity'] as num).toInt()
            : 1;
        calculatedItemsTotal += (itemPrice * itemQty);
      }
    } else {
      calculatedItemsTotal = sales.totalAmount;
    }

    final double grandTotal = sales.totalAmount;
    double shippingFee = 0.0;
    double discountAmount = 0.0;

    // Logic: If grand total is higher, difference is Shipping Fee.
    // If calculated item total is higher, difference is Discount.
    if (grandTotal > calculatedItemsTotal) {
      shippingFee = grandTotal - calculatedItemsTotal;
    } else if (calculatedItemsTotal > grandTotal) {
      discountAmount = calculatedItemsTotal - grandTotal;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER (Logo + INVOICE) ─────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  logoBytes != null
                      ? pw.SizedBox(
                          width: 130,
                          height: 50,
                          child: pw.Image(pw.MemoryImage(logoBytes)),
                        )
                      : pw.Text(
                          'TECHTONIC',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryNavy,
                          ),
                        ),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── DIVIDER LINE ───────────────────────────────────────────
              pw.Container(height: 2, color: primaryNavy),
              pw.SizedBox(height: 12),

              // ── CUSTOMER & INVOICE INFO TABLE ─────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Customer Name:',
                        sales.customerName ?? 'N/A',
                      ),
                      _buildInfoRow('Phone Number:', sales.customerPhone),
                      _buildInfoRow('Date:', dateString),
                      _buildInfoRow('Invoice No:', sales.id ?? 'INV-0000'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRow('Brand:', 'TECHTONIC', alignRight: true),
                      _buildInfoRow(
                        'Payment Status:',
                        sales.status,
                        alignRight: true,
                      ),
                      _buildInfoRow('Warranty:', '12 Months', alignRight: true),
                      _buildInfoRow(
                        'Reference:',
                        sales.id != null ? '#${sales.id}' : '-',
                        alignRight: true,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── ITEMS TABLE ─────────────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(35), // #
                  1: pw.FlexColumnWidth(3.5), // ITEM NAME
                  2: pw.FixedColumnWidth(50), // QTY
                  3: pw.FixedColumnWidth(80), // PRICE
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryNavy),
                    children: [
                      _buildCell(
                        '#',
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildCell(
                        'ITEM NAME',
                        isHeader: true,
                        align: pw.TextAlign.left,
                      ),
                      _buildCell(
                        'QTY',
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildCell(
                        'PRICE (Rs.)',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  // Items (or fallback row if items list is empty)
                  if (sales.items.isNotEmpty)
                    ...sales.items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;

                      final double itemPrice = (item['price'] is num)
                          ? (item['price'] as num).toDouble()
                          : 0.0;
                      final int itemQty = (item['quantity'] is num)
                          ? (item['quantity'] as num).toInt()
                          : 1;

                      return pw.TableRow(
                        children: [
                          _buildCell('$index', align: pw.TextAlign.center),
                          _buildCell(item['name']?.toString() ?? 'Item'),
                          _buildCell('$itemQty', align: pw.TextAlign.center),
                          _buildCell(
                            currencyFormat
                                .format(itemPrice)
                                .replaceAll('Rs.', '')
                                .trim(),
                            align: pw.TextAlign.right,
                          ),
                        ],
                      );
                    })
                  else
                    pw.TableRow(
                      children: [
                        _buildCell('1', align: pw.TextAlign.center),
                        _buildCell('Sales Order Item'),
                        _buildCell('1', align: pw.TextAlign.center),
                        _buildCell(
                          currencyFormat
                              .format(grandTotal)
                              .replaceAll('Rs.', '')
                              .trim(),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── TOTALS TABLE ───────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 220,
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                      children: [
                        _buildTotalRow(
                          'Subtotal',
                          currencyFormat.format(calculatedItemsTotal),
                        ),
                        if (shippingFee > 0)
                          _buildTotalRow(
                            'Shipping',
                            currencyFormat.format(shippingFee),
                          ),
                        if (discountAmount > 0)
                          _buildTotalRow(
                            'Discount',
                            '- ${currencyFormat.format(discountAmount)}',
                          ),
                        _buildTotalRow(
                          'TOTAL',
                          currencyFormat.format(grandTotal),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── NOTES & TERMS ──────────────────────────────────────────
              pw.Text(
                'Notes / Terms',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Please keep this invoice for your records and warranty/service purposes where applicable.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Spacer(),

              // ── SIGNATURE LINES ────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 140,
                        height: 0.8,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signature',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 140,
                        height: 0.8,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Customer Signature',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── FOOTER ─────────────────────────────────────────────────
              pw.Center(
                child: pw.Text(
                  'This is a computer generated invoice. No signature is required.',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper: Text detail row
  static pw.Widget _buildInfoRow(
    String label,
    String value, {
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label ',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryNavy,
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // Helper: Table cell styling
  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  // Helper: Totals row styling
  static pw.TableRow _buildTotalRow(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return pw.TableRow(
      decoration: isTotal ? const pw.BoxDecoration(color: lightBg) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            amount,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
