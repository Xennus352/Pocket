import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/colors.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final txnProvider = context.read<TransactionProvider>();
      final userProvider = context.read<UserProvider>();
      final allTxns = await DatabaseService().getTransactions(limit: 10000);
      final currency = userProvider.profile.currency;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text('Transaction Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 8),
            pw.Text('Total: ${allTxns.length} transaction${allTxns.length == 1 ? '' : 's'}',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              headers: ['Date', 'Title', 'Type', 'Amount', 'Category', 'Note'],
              data: allTxns.reversed.map((txn) {
                return [
                  DateFormat('yyyy-MM-dd').format(txn.date),
                  txn.title,
                  txn.type == TransactionType.income ? 'Cash In' : 'Cash Out',
                  '${txn.type == TransactionType.income ? '+' : '-'}${NumberFormat.currency(symbol: '', decimalDigits: 0).format(txn.amount)} $currency',
                  txn.category,
                  txn.note ?? '',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 32),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _summaryRow('Total Income',
                        '+${NumberFormat.currency(symbol: '', decimalDigits: 0).format(txnProvider.totalIncome)} $currency'),
                    pw.SizedBox(height: 4),
                    _summaryRow('Total Expense',
                        '-${NumberFormat.currency(symbol: '', decimalDigits: 0).format(txnProvider.totalExpense)} $currency'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _summaryRow('Balance',
                        '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(txnProvider.balance)} $currency'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Pocket_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Pocket Transaction Report',
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: $fileName'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _exporting = false);
    }
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text('$label: ',
            style: const pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800)),
        pw.Text(value,
            style: const pw.TextStyle(
                fontSize: 11, color: PdfColors.grey800)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final count = txnProvider.transactions.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _AppBar(
              title: 'Export Data',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xCC1A1F2E)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0x4D6B7280)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.violetHint],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text('Export Transactions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE8EDF5)
                                  : AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        count == 0
                            ? 'No transactions to export'
                            : '$count transaction${count == 1 ? '' : 's'} will be exported as PDF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.textSecondary.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: count > 0 && !_exporting ? _exportPdf : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryBlue,
                                    AppColors.violetHint,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _exporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.file_download_rounded,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Save PDF',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFormatCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF Format',
              description:
                  'Includes date, title, type, amount, category, note, and summary with income, expense, and balance.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xCC1A1F2E)
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0x4D6B7280)
              : Colors.white.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8EDF5)
                            : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : AppColors.textSecondary.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _AppBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x331A1F2E)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0x4D6B7280)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: isDark
                    ? const Color(0xFFE8EDF5)
                    : AppColors.textPrimary,
                size: 22),
          ),
        ),
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE8EDF5)
                    : AppColors.textPrimary)),
        const SizedBox(width: 44),
      ],
    );
  }
}
