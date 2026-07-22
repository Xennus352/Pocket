import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialCurrency;

  const SettingsScreen({super.key, this.initialCurrency});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  String _appVersion = '2.0.1';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static const _currencies = ['MMK', 'USD', 'THB', 'SGD'];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;
    _nameController.text = profile.name;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _AppBar(
              title: 'Settings',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Profile'),
            const SizedBox(height: 12),
            _buildNameTile(context, profile.name, userProvider),
            const SizedBox(height: 12),
            _buildCurrencyTile(context, profile.currency, userProvider),
            const SizedBox(height: 12),
            _buildBudgetTile(context, userProvider),
            const SizedBox(height: 12),
            _buildWarningThresholdTile(context, userProvider),
            const SizedBox(height: 28),
            _SectionTitle(title: 'About'),
            const SizedBox(height: 12),
            _buildInfoTile('Version', _appVersion),
            const SizedBox(height: 12),
            _buildInfoTile('Database', 'SQLite'),
            const SizedBox(height: 12),
            _buildInfoTile('Developed By', 'SMK'),
          ],
        ),
      ),
    );
  }

  Widget _buildNameTile(BuildContext context, String name, UserProvider userProvider) {
    return _SettingsTile(
      icon: Icons.person_rounded,
      title: 'Name',
      subtitle: name,
      onTap: () => _editName(context, userProvider),
    );
  }

  Widget _buildCurrencyTile(BuildContext context, String currency, UserProvider userProvider) {
    return _SettingsTile(
      icon: Icons.attach_money_rounded,
      title: 'Currency',
      subtitle: currency,
      onTap: () => _selectCurrency(context, userProvider),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return _SettingsTile(
      icon: Icons.info_outline_rounded,
      title: title,
      subtitle: value,
      onTap: null,
    );
  }

  Widget _buildBudgetTile(BuildContext context, UserProvider userProvider) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return _SettingsTile(
      icon: Icons.pie_chart_rounded,
      title: 'Monthly Budget',
      subtitle: '${fmt.format(userProvider.profile.monthlyBudget)} ${userProvider.profile.currency}',
      onTap: () => _editBudget(context, userProvider),
    );
  }

  Widget _buildWarningThresholdTile(BuildContext context, UserProvider userProvider) {
    return _SettingsTile(
      icon: Icons.warning_amber_rounded,
      title: 'Big-change Sensitivity',
      subtitle: '${userProvider.profile.warningThresholdPercent.toStringAsFixed(0)}% of balance',
      onTap: () => _editWarningThreshold(context, userProvider),
    );
  }

  void _editWarningThreshold(BuildContext context, UserProvider userProvider) {
    final current = userProvider.profile.warningThresholdPercent;
    double value = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          title: const Text('Big-change Sensitivity',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'When an expense exceeds this % of your balance, a warning will appear.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              Slider(
                value: value,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${value.toStringAsFixed(0)}%',
                onChanged: (v) => setDialogState(() => value = v),
              ),
              const Text('1% — 100%', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                userProvider.updateWarningThreshold(value);
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, UserProvider userProvider) {
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

  void _editBudget(BuildContext context, UserProvider userProvider) {
    final controller = TextEditingController(text: userProvider.profile.monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        title: const Text('Set Monthly Budget',
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
                hintText: '1000000',
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
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final amount = double.tryParse(text);
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid budget amount'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              userProvider.updateMonthlyBudget(amount);
              Navigator.pop(ctx);
            },
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _selectCurrency(BuildContext context, UserProvider userProvider) {
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
                  const Text('Select Currency',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),
                  ..._currencies.map((c) => _CurrencyOption(
                        currency: c,
                        isSelected: c == userProvider.profile.currency,
                        onTap: () {
                          userProvider.updateCurrency(c);
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            ),
          ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            letterSpacing: 0.5));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
                        const SizedBox(height: 1),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final String currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : AppColors.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(currency,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 14),
                Text(currency,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary)),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryBlue, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
