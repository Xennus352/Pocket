import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatters.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> txns) {
    var filtered = txns;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            (t.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_filterType == 'Income') {
      filtered = filtered.where((t) => t.type == TransactionType.income).toList();
    } else if (_filterType == 'Expense') {
      filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = context.watch<TransactionProvider>();
    final userProvider = context.watch<UserProvider>();
    final currency = userProvider.profile.currency;
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final allTxns = txnProvider.transactions;
    final filtered = _filterTransactions(allTxns);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _AppBar(
                title: 'Transactions',
                onClose: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FilterChips(
                selected: _filterType,
                onChanged: (v) => setState(() => _filterType = v),
              ),
            ),
            const SizedBox(height: 8),
            if (txnProvider.loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No matching transactions'
                            : 'No transactions yet',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final txn = filtered[index];
                    return _HistoryTile(
                      key: ValueKey(txn.id),
                      txn: txn,
                      currency: currency,
                      fmt: fmt,
                    );
                  },
                ),
              ),
          ],
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 22),
          ),
        ),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle:
              TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  static const _options = ['All', 'Income', 'Expense'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSelected = selected == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Transaction txn;
  final String currency;
  final NumberFormat fmt;

  const _HistoryTile({
    super.key,
    required this.txn,
    required this.currency,
    required this.fmt,
  });

  void _togglePaid(BuildContext context) {
    final updated = Transaction(
      id: txn.id,
      title: txn.title,
      amount: txn.amount,
      type: txn.type,
      category: txn.category,
      date: txn.date,
      note: txn.note,
      agentTxnType: txn.agentTxnType,
      commission: txn.commission,
      customerName: txn.customerName,
      paymentType: txn.paymentType,
      isPaid: !txn.isPaid,
      edited: true,
    );
    context.read<TransactionProvider>().updateTransaction(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == TransactionType.income;
    final amount =
        '${isIncome ? '+' : '-'}${fmt.format(txn.amount)} $currency';

    final paymentIcon = WalletHelper.iconFor(txn.paymentType ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: () => _togglePaid(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (isIncome ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(paymentIcon,
                        color: isIncome ? AppColors.income : AppColors.expense,
                        size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(txn.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            if (txn.paymentType != null)
                              Flexible(
                                child: Text(
                                  txn.paymentType!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: (txn.isPaid ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                txn.isPaid ? 'Paid' : 'Not Paid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: txn.isPaid ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ),
                            if (txn.edited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textTertiary.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amount,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense)),
                      if (txn.commission > 0)
                        Text('Comm: ${fmt.format(txn.commission)} $currency',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary
                                    .withValues(alpha: 0.8))),
                      Text(
                          DateFormat('MMM d, yyyy').format(txn.date),
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary
                                  .withValues(alpha: 0.8))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
