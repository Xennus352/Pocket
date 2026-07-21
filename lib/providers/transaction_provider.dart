import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Transaction> _transactions = [];
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _expenseByCategory = {};
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
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Transaction txn) async {
    try {
      await _db.insertTransaction(txn);
      await loadData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _db.deleteTransaction(id);
      await loadData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
