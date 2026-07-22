import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/customer.dart';

abstract class DatabaseServiceBase {
  Future<void> init();
  Future<int> insertTransaction(Transaction txn);
  Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0});
  Future<List<Transaction>> getTransactionsByMonth(int year, int month);
  Future<List<Transaction>> getAgentTransactionsByDate(DateTime date);
  Future<double> getBalance();
  Future<double> getTotalIncome({int? year, int? month});
  Future<double> getTotalExpense({int? year, int? month});
  Future<double> getTodayCommission(DateTime date);
  Future<Map<String, double>> getExpenseByCategory(DateTime start, DateTime end);
  Future<Map<String, double>> getIncomeByCategory(DateTime start, DateTime end);
  Future<int> getTransactionCount();
  Future<void> updateTransaction(Transaction txn);
  Future<void> deleteTransaction(int id);
  Future<void> close();
  bool get isRemote;

  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);

  Future<List<Customer>> getCustomers();
  Future<int> saveCustomer(Customer customer);
  Future<void> incrementCustomerTxCount(int id);
}
