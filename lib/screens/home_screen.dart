import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_transition.dart';
import '../widgets/shimmer_loading.dart';
import 'add_transaction_screen.dart';
import 'analytics_screen.dart';
import 'transaction_history_screen.dart';
import 'manage_wallets_screen.dart';
import 'export_data_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, UserProvider>(
      builder: (context, txnProvider, userProvider, _) {
        final currency = userProvider.profile.currency;
        final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
        final loading = txnProvider.loading && !txnProvider.initialized;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addTransaction(context),
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
          body: SafeArea(
            child: ShimmerLoading(
              isLoading: loading,
              child: loading
                  ? _LoadingSkeleton()
                  : RefreshIndicator(
                      onRefresh: () => txnProvider.loadData(),
                      displacement: 60,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        children: [
                          _Header(userProvider: userProvider),
                          const SizedBox(height: 20),
                          GlassWalletCard(
                            balance: txnProvider.balance < 0
                                ? 'Insufficient'
                                : '${fmt.format(txnProvider.balance)} $currency',
                            sources: userProvider.profile.wallets,
                          ),
                          const SizedBox(height: 16),
                          _BudgetProgress(
                            spent: txnProvider.monthlyExpense,
                            budget: userProvider.profile.monthlyBudget,
                            currency: currency,
                          ),
                          const SizedBox(height: 20),
                          _QuickActions(
                            onAddTap: () => _addTransaction(context),
                            onMoreTap: () => _showMoreMenu(context),
                          ),
                          const SizedBox(height: 24),
                          _MonthlyOverview(
                            income: txnProvider.totalIncome,
                            expense: txnProvider.totalExpense,
                            currency: currency,
                          ),
                          const SizedBox(height: 28),
                          _SectionLabel(
                            label: 'Recent Transactions',
                            onSeeAll: txnProvider.transactions.isNotEmpty
                                ? () => _openHistory(context)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (txnProvider.transactions.isEmpty)
                            _EmptyState(onStart: () => _addTransaction(context))
                          else
                            ...txnProvider.transactions.take(10).map(
                                  (txn) => _TransactionTimelineTile(
                                    txn: txn,
                                    currency: currency,
                                    index: txnProvider.transactions.indexOf(txn),
                                  ),
                                ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _addTransaction(BuildContext context) {
    Navigator.push(
      context,
      glassRoute(const AddTransactionScreen()),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      glassRoute(const TransactionHistoryScreen()),
    );
  }

  void _setBalance(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Text('Set Starting Balance',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final amount = double.tryParse(text);
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid positive number'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              try {
                await context.read<UserProvider>().updateStartingBalance(amount);
                await context.read<TransactionProvider>().loadData();
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error setting balance: $e'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting balance set to $amount'),
                  backgroundColor: AppColors.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),
                  _menuItem(
                    ctx,
                    Icons.history_rounded,
                    'Transaction History',
                    'View all records',
                    () {
                      Navigator.pop(ctx);
                      _openHistory(context);
                    },
                  ),
                  _menuItem(
                    ctx,
                    Icons.wallet_rounded,
                    'Manage Wallets',
                    'KPay, WavePay, Cash',
                    () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        glassRoute(const ManageWalletsScreen()),
                      );
                    },
                  ),
                  _menuItem(
                    ctx,
                    Icons.file_download_rounded,
                    'Export Data',
                    'CSV or PDF',
                    () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        glassRoute(const ExportDataScreen()),
                      );
                    },
                  ),
                  _menuItem(
                    ctx,
                    Icons.settings_rounded,
                    'Settings',
                    'Currency, profile, theme',
                    () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        glassRoute(const SettingsScreen()),
                      );
                    },
                  ),
                  _menuItem(
                    ctx,
                    Icons.balance_rounded,
                    'Set Balance',
                    'Adjust starting balance',
                    () {
                      Navigator.pop(ctx);
                      _setBalance(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textSecondary.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                    size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 180, height: 26),
                const SizedBox(height: 8),
                SkeletonLine(width: 100, height: 14),
              ],
            ),
            SkeletonCard(width: 50, height: 50, borderRadius: 18),
          ],
        ),
        const SizedBox(height: 20),
        SkeletonCard(height: 180),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            4,
            (_) => SkeletonCard(width: 72, height: 80, borderRadius: 18),
          ),
        ),
        const SizedBox(height: 24),
        SkeletonCard(height: 180),
        const SizedBox(height: 28),
        SkeletonLine(width: 160, height: 18),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SkeletonCard(height: 64, borderRadius: 16),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final UserProvider userProvider;

  const _Header({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final profile = userProvider.profile;
    final initial =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'J';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${profile.greeting}, ${profile.name}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _editName(context),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.violetHint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: userProvider.profile.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Text('Edit Name',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name cannot be empty'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              userProvider.updateName(name);
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onMoreTap;

  const _QuickActions({required this.onAddTap, required this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GlassActionButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Receive',
          iconColor: AppColors.income,
          color: AppColors.income,
          onTap: () {
            Navigator.push(
              context,
              glassRoute(const AddTransactionScreen(initialType: 'Income')),
            );
          },
        ),
        GlassActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Pay',
          iconColor: AppColors.expense,
          color: AppColors.expense,
          onTap: onAddTap,
        ),
        GlassActionButton(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          iconColor: AppColors.primaryBlue,
          color: AppColors.primaryBlue,
          onTap: () {
            Navigator.push(
              context,
              glassRoute(const AnalyticsScreen()),
            );
          },
        ),
        GlassActionButton(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          iconColor: AppColors.textSecondary,
          color: AppColors.textSecondary,
          onTap: onMoreTap,
        ),
      ],
    );
  }
}

class _MonthlyOverview extends StatelessWidget {
  final double income;
  final double expense;
  final String currency;

  const _MonthlyOverview({
    required this.income,
    required this.expense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final saving = income - expense;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatItem(
                label: 'Income',
                amount: '+${fmt.format(income)} $currency',
                color: AppColors.income,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: 12),
              _StatItem(
                label: 'Expense',
                amount: '-${fmt.format(expense)} $currency',
                color: AppColors.expense,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.3),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                  AppColors.primaryBlue.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: AppColors.income, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    saving < 0 ? 'Insufficient' : '${fmt.format(saving)} $currency',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.8))),
                  Text(amount,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final VoidCallback? onSeeAll;

  const _SectionLabel({required this.label, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See All',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        AppColors.primaryBlue.withValues(alpha: 0.8))),
          ),
      ],
    );
  }
}

class _TransactionTimelineTile extends StatefulWidget {
  final Transaction txn;
  final String currency;
  final int index;

  const _TransactionTimelineTile({
    required this.txn,
    required this.currency,
    required this.index,
  });

  @override
  State<_TransactionTimelineTile> createState() =>
      _TransactionTimelineTileState();
}

class _TransactionTimelineTileState extends State<_TransactionTimelineTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final isIncome = widget.txn.type == TransactionType.income;
    final amount =
        '${isIncome ? '+' : '-'}${fmt.format(widget.txn.amount)} ${widget.currency}';

    final categoryIcons = {
      'Food & Drinks': Icons.restaurant_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Transport': Icons.directions_car_rounded,
      'Entertainment': Icons.movie_rounded,
      'Bills & Utilities': Icons.receipt_rounded,
      'Health': Icons.favorite_rounded,
      'Education': Icons.school_rounded,
      'Salary': Icons.work_rounded,
      'Freelance': Icons.laptop_rounded,
      'Transfer': Icons.swap_horiz_rounded,
      'Other': Icons.more_horiz_rounded,
    };
    final icon = categoryIcons[widget.txn.category] ?? Icons.circle;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 18),
                      decoration: BoxDecoration(
                        color:
                            isIncome ? AppColors.income : AppColors.expense,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isIncome
                                    ? AppColors.income
                                    : AppColors.expense)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.textTertiary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (isIncome
                                      ? AppColors.income
                                      : AppColors.expense)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon,
                                color: isIncome
                                    ? AppColors.income
                                    : AppColors.expense,
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.txn.title,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 1),
                                Text(widget.txn.category,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(amount,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome
                                            ? AppColors.income
                                            : AppColors.expense),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                    DateFormat('MMM d')
                                        .format(widget.txn.date),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textTertiary
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('No transactions yet',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.violetHint],
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Start Tracking',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  final double spent;
  final double budget;
  final String currency;

  const _BudgetProgress({
    required this.spent,
    required this.budget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0).toDouble() : 0.0;
    final remaining = budget - spent;
    final remainingFmt = remaining < 0 ? 'Insufficient' : '${fmt.format(remaining)} $currency';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Monthly Budget',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withValues(alpha: 0.9))),
              const Spacer(),
              Text(
                '${fmt.format(spent)} $currency / ${fmt.format(budget)} $currency',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio >= 1 ? AppColors.expense : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining: $remainingFmt',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: remaining < 0 ? AppColors.expense : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
