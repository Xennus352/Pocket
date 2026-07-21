import 'package:flutter_test/flutter_test.dart';
import 'package:my_expense/models/transaction.dart';

void main() {
  test('Transaction model creates correctly', () {
    final txn = Transaction(
      title: 'Test',
      amount: 100.0,
      type: TransactionType.expense,
      category: 'Food & Drinks',
      date: DateTime(2024, 1, 1),
    );
    expect(txn.title, 'Test');
    expect(txn.amount, 100.0);
    expect(txn.type, TransactionType.expense);
  });

  test('Category data has expense categories', () {
    expect(CategoryData.expenseCategories.length, greaterThan(0));
    expect(CategoryData.incomeCategories.length, greaterThan(0));
  });

  test('Find category by name', () {
    final cat = CategoryData.findByName('Salary');
    expect(cat, isNotNull);
    expect(cat!.type, TransactionType.income);
  });
}
