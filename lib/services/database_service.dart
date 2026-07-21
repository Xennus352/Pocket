import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/customer.dart';
import 'database_service_base.dart';
import 'sqlite_database_service.dart';

class DatabaseService extends DatabaseServiceBase {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  final SqliteDatabaseService _sqlite = SqliteDatabaseService();

  @override
  bool get isRemote => false;

  @override
  Future<void> init() async {
    await _sqlite.init();
  }

  @override
  Future<int> insertTransaction(Transaction txn) async {
    return await _sqlite.insertTransaction(txn);
  }

  @override
  Future<List<Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _sqlite.getTransactions(limit: limit, offset: offset);
  }

  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    return await _sqlite.getTransactionsByMonth(year, month);
  }

  @override
  Future<double> getBalance() async {
    return await _sqlite.getBalance();
  }

  @override
  Future<double> getTotalIncome({int? year, int? month}) async {
    return await _sqlite.getTotalIncome(year: year, month: month);
  }

  @override
  Future<double> getTotalExpense({int? year, int? month}) async {
    return await _sqlite.getTotalExpense(year: year, month: month);
  }

  @override
  Future<Map<String, double>> getExpenseByCategory(DateTime start, DateTime end) async {
    return await _sqlite.getExpenseByCategory(start, end);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _sqlite.deleteTransaction(id);
  }

  @override
  Future<List<Transaction>> getAgentTransactionsByDate(DateTime date) async {
    return await _sqlite.getAgentTransactionsByDate(date);
  }

  @override
  Future<double> getTodayCommission(DateTime date) async {
    return await _sqlite.getTodayCommission(date);
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    return await _sqlite.getUserProfile();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _sqlite.saveUserProfile(profile);
  }

  @override
  Future<List<Customer>> getCustomers() async {
    return await _sqlite.getCustomers();
  }

  @override
  Future<int> saveCustomer(Customer customer) async {
    return await _sqlite.saveCustomer(customer);
  }

  @override
  Future<void> incrementCustomerTxCount(int id) async {
    await _sqlite.incrementCustomerTxCount(id);
  }

  @override
  Future<void> close() async {
    await _sqlite.close();
  }
}
