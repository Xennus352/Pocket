import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../models/wallet.dart';
import '../providers/user_provider.dart';
import '../utils/formatters.dart';
import '../widgets/responsive.dart';

class ManageWalletsScreen extends StatefulWidget {
  const ManageWalletsScreen({super.key});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  final _fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);

  void _addWallet() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Text('Add Wallet',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Wallet name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Initial amount (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
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
              if (nameController.text.trim().isNotEmpty) {
                final userProvider = context.read<UserProvider>();
                if (userProvider.profile.wallets.length >= 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Only 10 wallet can create'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(ctx);
                  return;
                }
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                final wallets = List<Wallet>.from(userProvider.profile.wallets)
                  ..add(Wallet(name: nameController.text.trim(), balance: amount));
                userProvider.updateWallets(wallets);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteWallet(String walletName) {
    final userProvider = context.read<UserProvider>();
    final wallets = List<Wallet>.from(userProvider.profile.wallets)
      ..removeWhere((w) => w.name == walletName);
    userProvider.updateWallets(wallets);
  }

  void _editBalance(Wallet wallet) {
    final controller = TextEditingController(text: wallet.balance.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: Text('Set ${wallet.name} Balance',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Balance',
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
              final amount = double.tryParse(controller.text.trim());
              if (amount != null) {
                final userProvider = context.read<UserProvider>();
                for (final w in userProvider.profile.wallets) {
                  if (w.name == wallet.name) {
                    w.balance = amount;
                    break;
                  }
                }
                userProvider.updateWallets(userProvider.profile.wallets);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final wallets = userProvider.profile.wallets;

    return Scaffold(
      body: SafeArea(
        child: Responsive(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _AppBar(
              title: 'Manage Wallets',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
            Text(
              '${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            ...wallets.map((w) => _WalletTile(
                  wallet: w,
                  fmt: _fmt,
                  onDelete: wallets.length > 1 ? () => _deleteWallet(w.name) : null,
                  onTap: () => _editBalance(w),
                )),
            const SizedBox(height: 20),
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _addWallet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text('Add Wallet',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
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

class _WalletTile extends StatelessWidget {
  final Wallet wallet;
  final NumberFormat fmt;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _WalletTile({
    required this.wallet,
    required this.fmt,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = WalletHelper.colorFor(wallet.name);
    final icon = WalletHelper.iconFor(wallet.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wallet.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('${fmt.format(wallet.balance)} MMK',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: AppColors.expense, size: 18),
                      ),
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
