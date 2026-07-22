import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/transaction.dart';
import '../models/customer.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final String? initialAgentType;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'Cash Out',
    this.initialAgentType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _noteController = TextEditingController();
  final _customerController = TextEditingController();
  final _commissionController = TextEditingController();
  String _amount = '';
  late String _type;
  String _wallet = 'KPay';

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.initialAgentType != null) {
      _agentType = widget.initialAgentType!;
      _type = widget.initialAgentType == 'Cash-In' ? 'Cash In' : 'Cash Out';
    }
    _loadCustomers();
  }

  void _loadCustomers() async {
    final customers = await DatabaseService().getCustomers();
    setState(() {
      _customers = customers;
      _filteredCustomers = customers;
    });
  }

  void _onCustomerChanged(String value) {
    setState(() {
      _filteredCustomers = _customers
          .where((c) => c.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  String _agentType = '';
  bool _submitting = false;
  bool _isPaid = true;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];

  bool get _isAgentMode => widget.initialAgentType != null;

  final _agentTypes = [
    ('Cash-In', Icons.add_card_rounded, AgentTransactionType.cashIn),
    ('Cash-Out', Icons.money_off_rounded, AgentTransactionType.cashOut),
    ('Transfer', Icons.swap_horiz_rounded, AgentTransactionType.transfer),
    ('Bill Payment', Icons.receipt_rounded, AgentTransactionType.billPayment),
    ('Top-Up', Icons.phone_iphone_rounded, AgentTransactionType.topUp),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _customerController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userWallets = context.read<UserProvider>().profile.walletNames;
    final currency = context.read<UserProvider>().profile.currency;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppBar(onClose: () => Navigator.pop(context)),
              const SizedBox(height: 20),
              if (_isAgentMode) ...[
                _AgentTypeSelector(
                  types: _agentTypes,
                  selected: _agentType,
                  onChanged: (v) => setState(() => _agentType = v),
                ),
                const SizedBox(height: 20),
              ],
              _AmountInput(
                amount: _amount.isEmpty ? '0' : _amount,
                currency: currency,
                onDigit: (d) => setState(() {
                  if (_amount == '0') _amount = '';
                  _amount += d;
                }),
                onBackspace: () => setState(() {
                  if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
                }),
              ),
              if (!_isAgentMode) ...[
                const SizedBox(height: 24),
                GlassTypeToggle(
                  options: ['Cash In', 'Cash Out'],
                  selected: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ],
              const SizedBox(height: 20),
              _WalletSelector(
                wallets: userWallets,
                selected: _wallet,
                onChanged: (v) => setState(() => _wallet = v),
              ),
              if (_isAgentMode) ...[
                const SizedBox(height: 16),
                _Label('Customer'),
                const SizedBox(height: 10),
                _CustomerField(
                  controller: _customerController,
                  customers: _filteredCustomers,
                  onChanged: _onCustomerChanged,
                ),
                const SizedBox(height: 16),
                _Label('Commission'),
                const SizedBox(height: 10),
                _GlassTextField(
                  controller: _commissionController,
                  hint: 'Commission amount',
                  icon: Icons.monetization_on_rounded,
                  keyboardType: true,
                ),
              ],
              const SizedBox(height: 16),
              _Label('Note'),
              const SizedBox(height: 10),
              _GlassTextField(
                controller: _noteController,
                hint: 'Add a note...',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _Label('Status'),
              const SizedBox(height: 10),
              _PaidToggle(
                isPaid: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
              ),
              const SizedBox(height: 16),
              _DatePicker(),
              const SizedBox(height: 12),
              _PayingWithLabel(wallet: _wallet),
              const SizedBox(height: 16),
              _SubmitButton(
                loading: _submitting,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showBalanceWarning(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Balance Warning', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue Anyway', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String? _validate() {
    if (_amount.isEmpty || _amount == '0') {
      return 'Please enter an amount greater than 0';
    }
    final parsed = double.tryParse(_amount);
    if (parsed == null || parsed < 0) {
      return 'Invalid amount';
    }
    if (parsed > 999999999) {
      return 'Amount is too large';
    }
    if (_isAgentMode && _customerController.text.trim().isEmpty) {
      return 'Please enter a customer name';
    }
    if (_isAgentMode) {
      final commission = double.tryParse(_commissionController.text.trim());
      if (commission != null && commission < 0) {
        return 'Commission cannot be negative';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final amount = double.parse(_amount);
    final txnType = _type == 'Cash In' ? TransactionType.income : TransactionType.expense;

    final txnProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();

    if (txnType == TransactionType.expense) {
      final wallet = userProvider.profile.wallets.where((w) => w.name == _wallet).firstOrNull;
      final walletBalance = wallet?.balance ?? 0;
      final impact = txnProvider.checkBalanceImpact(
        amount: amount,
        type: txnType,
        warningThresholdPercent: userProvider.profile.warningThresholdPercent,
        walletBalance: walletBalance,
      );
      if (impact.hasNoBalance || impact.willBeInsufficient || impact.isBigChange) {
        setState(() => _submitting = false);
        String message;
        if (impact.hasNoBalance) {
          message = '$_wallet balance is 0 or negative (${impact.currentBalance.toStringAsFixed(0)}).';
        } else if (impact.willBeInsufficient) {
          message = 'This expense (${amount.toStringAsFixed(0)}) will leave $_wallet balance negative (${impact.newBalance.toStringAsFixed(0)}).';
        } else {
          message = 'This expense (${amount.toStringAsFixed(0)}) is at least ${userProvider.profile.warningThresholdPercent.toStringAsFixed(0)}% of $_wallet balance (${impact.currentBalance.toStringAsFixed(0)}).';
        }
        final proceed = await _showBalanceWarning(context, message);
        if (!mounted) return;
        if (!proceed) return;
        setState(() => _submitting = true);
      }
    }

    final txn = Transaction(
      title: _isAgentMode ? _agentType : (_noteController.text.trim().isEmpty ? 'Transaction' : _noteController.text.trim()),
      amount: amount,
      type: txnType,
      category: _isAgentMode ? _agentType : 'Other',
      date: DateTime.now(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      agentTxnType: _isAgentMode ? _agentTypes.firstWhere((a) => a.$1 == _agentType).$3 : null,
      commission: _isAgentMode ? (double.tryParse(_commissionController.text.trim()) ?? 0) : 0,
      customerName: _isAgentMode ? _customerController.text.trim().isEmpty ? null : _customerController.text.trim() : null,
      paymentType: _wallet,
      isPaid: _isPaid,
    );

    final success = await txnProvider.addTransaction(txn);

    if (_isAgentMode && success && _customerController.text.trim().isNotEmpty) {
      final name = _customerController.text.trim();
      final exists = _customers.any((c) => c.name.toLowerCase() == name.toLowerCase());
      if (!exists) {
        await DatabaseService().saveCustomer(Customer(name: name));
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save'), backgroundColor: AppColors.expense),
      );
    }
  }
}

class _AgentTypeSelector extends StatelessWidget {
  final List<(String, IconData, AgentTransactionType)> types;
  final String selected;
  final ValueChanged<String> onChanged;

  const _AgentTypeSelector({
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Transaction Type'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((t) {
            final isSelected = selected == t.$1;
            return GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$2, size: 18,
                        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      t.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CustomerField extends StatelessWidget {
  final TextEditingController controller;
  final List<Customer> customers;
  final ValueChanged<String> onChanged;

  const _CustomerField({
    required this.controller,
    required this.customers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Enter customer name...',
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ),
        if (customers.isNotEmpty && controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: customers.length > 5 ? 5 : customers.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.3)),
              itemBuilder: (context, index) {
                final c = customers[index];
                return InkWell(
                  onTap: () {
                    controller.text = c.name;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: c.name.length),
                    );
                    onChanged(c.name);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      c.name,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AppBar extends StatelessWidget {
  final VoidCallback onClose;

  const _AppBar({required this.onClose});

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
            child: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 22),
          ),
        ),
        const Text(
          'New Transaction',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String amount;
  final String currency;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _AmountInput({
    required this.amount,
    required this.currency,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final displayAmount = NumberFormat.currency(symbol: '', decimalDigits: 0)
        .format(int.tryParse(amount) ?? 0);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        children: [
          Text(
            '$displayAmount $currency',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumPad(digit: '1', onTap: () => onDigit('1')),
              _NumPad(digit: '2', onTap: () => onDigit('2')),
              _NumPad(digit: '3', onTap: () => onDigit('3')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumPad(digit: '4', onTap: () => onDigit('4')),
              _NumPad(digit: '5', onTap: () => onDigit('5')),
              _NumPad(digit: '6', onTap: () => onDigit('6')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumPad(digit: '7', onTap: () => onDigit('7')),
              _NumPad(digit: '8', onTap: () => onDigit('8')),
              _NumPad(digit: '9', onTap: () => onDigit('9')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumPad(digit: '00', onTap: () => onDigit('00')),
              _NumPad(digit: '0', onTap: () => onDigit('0')),
              GestureDetector(
                onTap: onBackspace,
                child: Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.backspace_rounded,
                      color: AppColors.textSecondary, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _NumPad({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletSelector extends StatelessWidget {
  final List<String> wallets;
  final String selected;
  final ValueChanged<String> onChanged;

  const _WalletSelector({
    required this.wallets,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final w = wallets[i];
          final isSelected = w == selected;
          final iconColor = isSelected ? AppColors.primaryBlue : AppColors.textSecondary;
          return GestureDetector(
            onTap: () => onChanged(w),
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    WalletHelper.iconFor(w),
                    size: 22,
                    color: iconColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    w,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaidToggle extends StatelessWidget {
  final bool isPaid;
  final ValueChanged<bool> onChanged;

  const _PaidToggle({required this.isPaid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PaidChip(
          label: 'Paid',
          isSelected: isPaid,
          onTap: () => onChanged(true),
          color: AppColors.income,
        ),
        const SizedBox(width: 8),
        _PaidChip(
          label: 'Not Paid',
          isSelected: !isPaid,
          onTap: () => onChanged(false),
          color: AppColors.expense,
        ),
      ],
    );
  }
}

class _PaidChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _PaidChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PayingWithLabel extends StatelessWidget {
  final String wallet;

  const _PayingWithLabel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(WalletHelper.iconFor(wallet), size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            'Paying with: $wallet',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool keyboardType;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType ? const TextInputType.numberWithOptions(decimal: true) : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.8)),
              prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.textTertiary.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.violetHint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.violetHint.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Save Transaction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
