import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../widgets/responsive.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, UserProvider>(
      builder: (context, provider, userProvider, _) {
        final currency = userProvider.profile.currency;
        final now = DateTime.now();
        final todayTxns = provider.transactions.where((t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day
        ).toList();
        final trueIncome = todayTxns
            .where((t) => t.type == TransactionType.income && !t.isTransfer)
            .fold<double>(0, (s, t) => s + t.amount);
        final trueExpense = todayTxns
            .where((t) => t.type == TransactionType.expense && !t.isTransfer)
            .fold<double>(0, (s, t) => s + t.amount);
        final dailyNet = trueIncome - trueExpense;
        final totalFlow = trueIncome + trueExpense;
        final incomeRatio = totalFlow > 0 ? trueIncome / totalFlow : 0.5;

        final walletDeltas = _computeWalletDeltas(
          wallets: userProvider.profile.wallets,
          transactions: todayTxns,
        );

        return Scaffold(
          body: SafeArea(
            child: Responsive(child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _Header(now: now, net: dailyNet, income: trueIncome, expense: trueExpense, currency: currency, walletDeltas: walletDeltas),
                const SizedBox(height: 20),
                _FlowBar(incomeRatio: incomeRatio, fmt: NumberFormat.currency(symbol: '', decimalDigits: 0), currency: currency),
                const SizedBox(height: 20),
                _WalletGrid(wallets: userProvider.profile.wallets, transactions: todayTxns, currency: currency),
                const SizedBox(height: 20),
                _TodayTxnsList(transactions: todayTxns, currency: currency),
              ],
            )),
          ),
        );
      },
    );
  }
}

Map<String, double> _computeWalletDeltas({
  required List<Wallet> wallets,
  required List<Transaction> transactions,
}) {
  final deltas = <String, double>{};
  for (final w in wallets) {
    double delta = 0;
    delta += transactions
        .where((t) => t.paymentType == w.name && t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    delta -= transactions
        .where((t) => t.paymentType == w.name && t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    deltas[w.name] = delta;
  }
  return deltas;
}

class _Header extends StatelessWidget {
  final DateTime now;
  final double net;
  final double income;
  final double expense;
  final String currency;
  final Map<String, double> walletDeltas;

  const _Header({required this.now, required this.net, required this.income, required this.expense, required this.currency, required this.walletDeltas});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final dayName = DateFormat('EEEE').format(now);
    final dateStr = DateFormat('MMM d').format(now);
    final isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkNavy.withValues(alpha: 0.9),
            AppColors.darkNavySoft.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(dayName, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${fmt.format(net)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(currency, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              _miniChip(Icons.arrow_downward_rounded, fmt.format(income), AppColors.income),
              const SizedBox(width: 8),
              _miniChip(Icons.arrow_upward_rounded, fmt.format(expense), AppColors.expense),
            ],
          ),
          if (walletDeltas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: walletDeltas.entries.map((e) {
                final color = e.value >= 0 ? AppColors.income : AppColors.expense;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${e.key}: ${e.value >= 0 ? '+' : ''}${fmt.format(e.value)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FlowBar extends StatelessWidget {
  final double incomeRatio;
  final NumberFormat fmt;
  final String currency;

  const _FlowBar({required this.incomeRatio, required this.fmt, required this.currency});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text('Income vs Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Flexible(
                    flex: (incomeRatio * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.income.withValues(alpha: 0.6), AppColors.income],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: ((1 - incomeRatio) * 100).round().clamp(1, 100),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.expense, AppColors.expense.withValues(alpha: 0.6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _flowLegend(Icons.arrow_downward_rounded, 'Income', '${(incomeRatio * 100).round()}%', AppColors.income),
              _flowLegend(Icons.arrow_upward_rounded, 'Expense', '${((1 - incomeRatio) * 100).round()}%', AppColors.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowLegend(IconData icon, String label, String pct, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.7))),
        const SizedBox(width: 4),
        Text(pct, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _WalletGrid extends StatelessWidget {
  final List<Wallet> wallets;
  final List<Transaction> transactions;
  final String currency;

  const _WalletGrid({required this.wallets, required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);

    if (wallets.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 20,
        child: Center(child: Text('No wallets', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text('Wallets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary.withValues(alpha: 0.9))),
          ],
        ),
        const SizedBox(height: 12),
        ...wallets.map((w) {
          final cashIn = transactions
              .where((t) => t.paymentType == w.name && t.type == TransactionType.income)
              .fold<double>(0, (s, t) => s + t.amount);
          final cashOut = transactions
              .where((t) => t.paymentType == w.name && t.type == TransactionType.expense)
              .fold<double>(0, (s, t) => s + t.amount);
          final color = WalletHelper.colorFor(w.name);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(WalletHelper.iconFor(w.name), size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Balance: ${fmt.format(w.balance)} $currency',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  if (cashIn > 0 || cashOut > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (cashIn > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 10, color: AppColors.income),
                              const SizedBox(width: 2),
                              Text('+${fmt.format(cashIn)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.income)),
                            ],
                          ),
                        if (cashOut > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: 10, color: AppColors.expense),
                              const SizedBox(width: 2),
                              Text('-${fmt.format(cashOut)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.expense)),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TodayTxnsList extends StatelessWidget {
  final List<Transaction> transactions;
  final String currency;

  const _TodayTxnsList({required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text('Today\'s Transactions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary.withValues(alpha: 0.9))),
            const Spacer(),
            Text('${transactions.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            borderRadius: 20,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No transactions today', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ...transactions.reversed.take(10).map((txn) {
            final isIncome = txn.type == TransactionType.income;
            final color = isIncome ? AppColors.income : AppColors.expense;
            final displayTitle = txn.title;
            final icon = txn.isTransfer ? Icons.swap_horiz_rounded
                : (isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderRadius: 14,
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (txn.paymentType != null)
                            Text(txn.paymentType!, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${fmt.format(txn.amount)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
