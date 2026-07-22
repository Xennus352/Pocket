import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/colors.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedType = 'Expense';

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, UserProvider>(
      builder: (context, provider, userProvider, _) {
        final currency = userProvider.profile.currency;
        final categoryMap = _selectedType == 'Expense'
            ? provider.expenseByCategory
            : provider.incomeByCategory;
        final total = categoryMap.values.fold(0.0, (a, b) => a + b);

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _Header(),
                const SizedBox(height: 20),
                _TypeToggle(
                  selected: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(height: 16),
                _SpendingChart(
                  categoryMap: categoryMap,
                  total: total,
                  currency: currency,
                ),
                const SizedBox(height: 20),
                _StatsRow(
                  income: provider.totalIncome,
                  expense: provider.totalExpense,
                  currency: currency,
                ),
                const SizedBox(height: 12),
                _TransactionCountTile(count: provider.totalTransactionCount),
                const SizedBox(height: 24),
                _SectionLabel('Category Analysis'),
                const SizedBox(height: 12),
                _CategoryBreakdown(
                  categoryMap: categoryMap,
                  total: total,
                  currency: currency,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionCountTile extends StatelessWidget {
  final int count;

  const _TransactionCountTile({required this.count});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Total Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const Spacer(),
          Text(
            Formatters.compactAmount(count.toDouble()),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('Expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == 'Expense' ? AppColors.expense.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 16, color: selected == 'Expense' ? AppColors.expense : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Expense', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected == 'Expense' ? AppColors.expense : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged('Receive'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == 'Receive' ? AppColors.income.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_down_rounded, size: 16, color: selected == 'Receive' ? AppColors.income : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Receive', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected == 'Receive' ? AppColors.income : AppColors.textSecondary)),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        canPop
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 24),
                ),
              )
            : const SizedBox(width: 44),
        const Text(
          'Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final Map<String, double> categoryMap;
  final double total;
  final String currency;

  const _SpendingChart({required this.categoryMap, required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      gradient: [
        AppColors.darkNavy.withValues(alpha: 0.85),
        AppColors.darkNavySoft.withValues(alpha: 0.7),
      ],
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkNavy.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${Formatters.compactAmount(total)} $currency',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.income,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: categoryMap.isEmpty
                ? Center(
                    child: Text(
                      'No data this month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : _BarChartWidget(
                    categoryMap: categoryMap,
                    total: total,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<String, double> categoryMap;
  final double total;

  const _BarChartWidget({
    required this.categoryMap,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final bucketed = _bucketCategories(categoryMap, total);
    final entries = bucketed.entries.toList();

    final maxValue = entries.isNotEmpty ? entries.first.value : 1.0;

    final chartColors = [
      AppColors.primaryBlue,
      AppColors.violetHint,
      AppColors.lightCyan,
      AppColors.skyBlue,
      AppColors.violetLight,
      AppColors.income,
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = entries[group.x.toInt()].key;
              final amount = entries[group.x.toInt()].value;
              return BarTooltipItem(
                '$category\n${Formatters.compactAmount(amount)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < entries.length) {
                  final label = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 6 ? '${label.substring(0, 6)}...' : label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: data.value,
                color: chartColors[idx % chartColors.length],
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  colors: [
                    chartColors[idx % chartColors.length],
                    chartColors[idx % chartColors.length].withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double income;
  final double expense;
  final String currency;

  const _StatsRow({required this.income, required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.trending_down_rounded, color: AppColors.income, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${Formatters.compactAmount(income)} $currency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: AppColors.expense, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${Formatters.compactAmount(expense)} $currency',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

Map<String, double> _bucketCategories(Map<String, double> categoryMap, double total) {
  final sorted = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final major = <MapEntry<String, double>>[];
  double othersSum = 0;
  for (final e in sorted) {
    final pct = total > 0 ? e.value / total * 100 : 0;
    if (pct < 1) {
      othersSum += e.value;
    } else {
      major.add(e);
    }
  }
  if (othersSum > 0) {
    major.add(MapEntry('Everything else', othersSum));
  }
  return {for (final e in major) e.key: e.value};
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryMap;
  final double total;
  final String currency;

  const _CategoryBreakdown({
    required this.categoryMap,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryMap.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(40),
        borderRadius: 20,
        child: Center(
          child: Text(
            'No data to analyze',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final bucketed = _bucketCategories(categoryMap, total);
    final entries = bucketed.entries.toList();

    final chartColors = [
      AppColors.primaryBlue,
      AppColors.violetHint,
      AppColors.lightCyan,
      AppColors.skyBlue,
      AppColors.violetLight,
      AppColors.income,
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = entry.value;
                  final percentage = total > 0 ? (data.value / total * 100) : 0.0;
                  final isOthers = data.key == 'Everything else';
                  return PieChartSectionData(
                    color: isOthers ? AppColors.textTertiary : chartColors[idx % chartColors.length],
                    value: data.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 55,
                  );
                }).toList(),
                centerSpaceRadius: 35,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final data = entry.value;
            final percentage = total > 0 ? (data.value / total * 100) : 0.0;
            final isOthers = data.key == 'Everything else';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isOthers ? AppColors.textTertiary : chartColors[idx % chartColors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            data.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              fontStyle: isOthers ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${Formatters.compactAmount(data.value)} $currency',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: (isOthers ? AppColors.textTertiary : chartColors[idx % chartColors.length]).withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                        isOthers ? AppColors.textTertiary : chartColors[idx % chartColors.length],
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
