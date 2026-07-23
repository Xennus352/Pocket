import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';

class BalanceImpactResult {
  final bool hasNoBalance;
  final bool willBeInsufficient;
  final bool isBigChange;
  final double currentBalance;
  final double newBalance;

  const BalanceImpactResult({
    required this.hasNoBalance,
    required this.willBeInsufficient,
    required this.isBigChange,
    required this.currentBalance,
    required this.newBalance,
  });
}

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  UserProvider? _userProvider;

  set userProvider(UserProvider v) => _userProvider = v;

  List<Transaction> _transactions = [];
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _expenseByCategory = {};
  Map<String, double> _incomeByCategory = {};
  int _totalTransactionCount = 0;
  bool _loading = false;
  bool _initialized = false;
  String? _error;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  List<Transaction> get transactions => _transactions;
  double get balance => _balance;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  Map<String, double> get expenseByCategory => _expenseByCategory;
  Map<String, double> get incomeByCategory => _incomeByCategory;
  int get totalTransactionCount => _totalTransactionCount;
  double get tmpi => _balance * 30;
  double get balancePlusTmpi => _balance + tmpi;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;
  bool get isOffline => true;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  String get monthLabel => DateFormat('MMMM yyyy').format(DateTime(_currentYear, _currentMonth));
  double get monthlyExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, t) => sum + t.amount);

  BalanceImpactResult checkBalanceImpact({
    required double amount,
    required TransactionType type,
    required double warningThresholdPercent,
    double walletBalance = 0,
  }) {
    if (type == TransactionType.income) {
      return const BalanceImpactResult(
        hasNoBalance: false,
        willBeInsufficient: false,
        isBigChange: false,
        currentBalance: 0,
        newBalance: 0,
      );
    }
    final balance = walletBalance;
    final hasNoBalance = balance <= 0;
    final newBalance = balance - amount;
    final willBeInsufficient = newBalance < 0;
    final isBigChange = hasNoBalance || (amount >= balance * warningThresholdPercent / 100);
    return BalanceImpactResult(
      hasNoBalance: hasNoBalance,
      willBeInsufficient: willBeInsufficient,
      isBigChange: isBigChange,
      currentBalance: balance,
      newBalance: newBalance,
    );
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      await _db.init();
      _initialized = true;
      await loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _error = null;
    try {
      _transactions = await _db.getTransactionsByMonth(_currentYear, _currentMonth);
      _balance = await _db.getBalance();
      _totalIncome = await _db.getTotalIncome(year: _currentYear, month: _currentMonth);
      _totalExpense = await _db.getTotalExpense(year: _currentYear, month: _currentMonth);
      _expenseByCategory = await _db.getExpenseByCategory(
        DateTime(_currentYear, _currentMonth, 1),
        DateTime(_currentYear, _currentMonth + 1, 1),
      );
      _incomeByCategory = await _db.getIncomeByCategory(
        DateTime(_currentYear, _currentMonth, 1),
        DateTime(_currentYear, _currentMonth + 1, 1),
      );
      _totalTransactionCount = await _db.getTransactionCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Transaction txn) async {
    try {
      await _db.insertTransaction(txn);
      await _applyWalletEffects(txn);
      await loadData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateTransaction(Transaction txn) async {
    try {
      final old = _transactions.firstWhere((t) => t.id == txn.id, orElse: () => txn);
      if (_userProvider != null) {
        await _reverseWalletEffects(old);
        await _applyWalletEffects(txn);
      }
      await _db.updateTransaction(txn);
      await loadData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final txn = _transactions.firstWhere((t) => t.id == id);
      if (_userProvider != null) {
        await _reverseWalletEffects(txn);
      }
      await _db.deleteTransaction(id);
      await loadData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _applyWalletEffects(Transaction txn) async {
    if (_userProvider == null || txn.paymentType == null) return;
    if (txn.paymentType != 'Cash') {
      await _userProvider!.updateWalletBalance(
        txn.paymentType!,
        txn.amount,
        isIncome: txn.type == TransactionType.income,
      );
      await _userProvider!.updateWalletBalance(
        'Cash',
        txn.amount,
        isIncome: txn.type != TransactionType.income,
      );
    } else {
      await _userProvider!.updateWalletBalance(
        txn.paymentType!,
        txn.amount,
        isIncome: txn.type == TransactionType.income,
      );
    }
  }

  Future<void> _reverseWalletEffects(Transaction txn) async {
    if (_userProvider == null || txn.paymentType == null) return;
    if (txn.paymentType != 'Cash') {
      await _userProvider!.updateWalletBalance(
        txn.paymentType!,
        txn.amount,
        isIncome: txn.type != TransactionType.income,
      );
      await _userProvider!.updateWalletBalance(
        'Cash',
        txn.amount,
        isIncome: txn.type == TransactionType.income,
      );
    } else {
      await _userProvider!.updateWalletBalance(
        txn.paymentType!,
        txn.amount,
        isIncome: txn.type != TransactionType.income,
      );
    }
  }



  void previousMonth() {
    if (_currentMonth == 1) {
      _currentYear--;
      _currentMonth = 12;
    } else {
      _currentMonth--;
    }
    loadData();
  }

  void nextMonth() {
    if (_currentMonth == 12) {
      _currentYear++;
      _currentMonth = 1;
    } else {
      _currentMonth++;
    }
    loadData();
  }
}
