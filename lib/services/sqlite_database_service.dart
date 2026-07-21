import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/customer.dart';
import 'database_service_base.dart';

class SqliteDatabaseService extends DatabaseServiceBase {
  Database? _db;

  Database _ensureDb() {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  bool get isRemote => false;

  @override
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'my_expense.db'),
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            agent_txn_type TEXT,
            commission REAL NOT NULL DEFAULT 0,
            customer_name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE user_settings (
            id INTEGER PRIMARY KEY DEFAULT 1,
            name TEXT NOT NULL DEFAULT 'Captain',
            currency TEXT NOT NULL DEFAULT 'MMK',
            starting_balance REAL NOT NULL DEFAULT 0,
            monthly_budget REAL NOT NULL DEFAULT 1000000,
            wallets TEXT NOT NULL DEFAULT 'KPay,WavePay,Cash'
          )
        ''');
        await db.insert('user_settings', {
          'id': 1,
          'name': 'Captain',
          'currency': 'MMK',
          'starting_balance': 0,
          'monthly_budget': 1000000,
          'wallets': 'KPay,WavePay,Cash',
        });
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            wallet_type TEXT NOT NULL DEFAULT 'KPay',
            transaction_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
              id INTEGER PRIMARY KEY DEFAULT 1,
              name TEXT NOT NULL DEFAULT 'Captain',
              currency TEXT NOT NULL DEFAULT 'MMK',
              starting_balance REAL NOT NULL DEFAULT 0,
              wallets TEXT NOT NULL DEFAULT 'KPay,WavePay,Cash'
            )
          ''');
          await db.insert('user_settings', {
            'id': 1,
            'name': 'Captain',
            'currency': 'MMK',
            'starting_balance': 0,
            'wallets': 'KPay,WavePay,Cash',
          });
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE transactions ADD COLUMN agent_txn_type TEXT
          ''');
          await db.execute('''
            ALTER TABLE transactions ADD COLUMN commission REAL NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE transactions ADD COLUMN customer_name TEXT
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              phone TEXT NOT NULL DEFAULT '',
              wallet_type TEXT NOT NULL DEFAULT 'KPay',
              transaction_count INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            ALTER TABLE user_settings ADD COLUMN monthly_budget REAL NOT NULL DEFAULT 1000000
          ''');
        }
      },
    );
  }

  @override
  Future<int> insertTransaction(Transaction txn) async {
    final id = await _ensureDb().insert('transactions', {
      'title': txn.title,
      'amount': txn.amount,
      'type': txn.type.name,
      'category': txn.category,
      'date': txn.date.toIso8601String(),
      'note': txn.note,
      'agent_txn_type': txn.agentTxnType?.name,
      'commission': txn.commission,
      'customer_name': txn.customerName,
    });
    return id;
  }

  @override
  Future<List<Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await _ensureDb().query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Transaction.fromMap(row)).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final results = await _ensureDb().query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return results.map((row) => Transaction.fromMap(row)).toList();
  }

  @override
  Future<List<Transaction>> getAgentTransactionsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day + 1).toIso8601String();
    final results = await _ensureDb().query(
      'transactions',
      where: 'agent_txn_type IS NOT NULL AND agent_txn_type != ? AND date >= ? AND date < ?',
      whereArgs: ['none', start, end],
      orderBy: 'date DESC',
    );
    return results.map((row) => Transaction.fromMap(row)).toList();
  }

  @override
  Future<double> getBalance() async {
    final txnResult = await _ensureDb().rawQuery(
      '''SELECT COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0)
                - COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as balance
         FROM transactions''',
    );
    final txnBalance = (txnResult.first['balance'] as num?)?.toDouble() ?? 0;
    final profile = await getUserProfile();
    final startingBalance = profile?.startingBalance ?? 0;
    return startingBalance + txnBalance;
  }

  @override
  Future<double> getTotalIncome({int? year, int? month}) async {
    if (year != null && month != null) {
      final start = DateTime(year, month, 1).toIso8601String();
      final end = DateTime(year, month + 1, 1).toIso8601String();
      final result = await _ensureDb().rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND date >= ? AND date < ?",
        [start, end],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    final result = await _ensureDb().rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<double> getTotalExpense({int? year, int? month}) async {
    if (year != null && month != null) {
      final start = DateTime(year, month, 1).toIso8601String();
      final end = DateTime(year, month + 1, 1).toIso8601String();
      final result = await _ensureDb().rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND date >= ? AND date < ?",
        [start, end],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    final result = await _ensureDb().rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<double> getTodayCommission(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day + 1).toIso8601String();
    final result = await _ensureDb().rawQuery(
      '''SELECT COALESCE(SUM(commission), 0) as total FROM transactions
         WHERE date >= ? AND date < ? AND commission > 0''',
      [start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<Map<String, double>> getExpenseByCategory(DateTime start, DateTime end) async {
    final results = await _ensureDb().rawQuery(
      '''SELECT category, SUM(amount) as total
         FROM transactions
         WHERE type = 'expense' AND date >= ? AND date < ?
         GROUP BY category ORDER BY total DESC''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return {for (final row in results) row['category'] as String: (row['total'] as num).toDouble()};
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _ensureDb().delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    final results = await _ensureDb().query('user_settings', where: 'id = 1');
    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _ensureDb().insert('user_settings', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Customer>> getCustomers() async {
    final results = await _ensureDb().query('customers', orderBy: 'transaction_count DESC');
    return results.map((row) => Customer.fromMap(row)).toList();
  }

  @override
  Future<int> saveCustomer(Customer customer) async {
    final id = await _ensureDb().insert('customers', customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  @override
  Future<void> incrementCustomerTxCount(int id) async {
    await _ensureDb().rawUpdate(
      'UPDATE customers SET transaction_count = transaction_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteTransactionsOlderThan(DateTime cutoff) async {
    await _ensureDb().delete(
      'transactions',
      where: 'date < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
  }
}
