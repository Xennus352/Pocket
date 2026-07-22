import 'package:flutter_test/flutter_test.dart';
import 'package:my_expense/models/transaction.dart';

void main() {
  group('Transaction', () {
    test('creates expense transaction', () {
      final txn = Transaction(
        title: 'Lunch',
        amount: 5000,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        date: DateTime(2026, 7, 22),
      );
      expect(txn.title, 'Lunch');
      expect(txn.amount, 5000);
      expect(txn.type, TransactionType.expense);
      expect(txn.category, 'Food & Drinks');
      expect(txn.commission, 0);
      expect(txn.isPaid, true);
      expect(txn.edited, false);
    });

    test('creates income transaction with paymentType', () {
      final txn = Transaction(
        title: 'Salary',
        amount: 500000,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 7, 22),
        paymentType: 'KPay',
      );
      expect(txn.paymentType, 'KPay');
      expect(txn.isAgent, false);
    });

    test('isAgent returns true for agent transactions', () {
      final txn = Transaction(
        title: 'Top Up',
        amount: 10000,
        type: TransactionType.expense,
        category: 'Other',
        date: DateTime(2026, 7, 22),
        agentTxnType: AgentTransactionType.topUp,
      );
      expect(txn.isAgent, true);
    });

    test('toMap and fromMap roundtrip', () {
      final txn = Transaction(
        title: 'Electric Bill',
        amount: 25000,
        type: TransactionType.expense,
        category: 'Bills & Utilities',
        date: DateTime(2026, 7, 22),
        note: 'July bill',
        paymentType: 'KPay',
        isPaid: true,
        edited: false,
      );
      final map = txn.toMap();
      map['id'] = 1;
      final restored = Transaction.fromMap(map);
      expect(restored.title, 'Electric Bill');
      expect(restored.amount, 25000);
      expect(restored.type, TransactionType.expense);
      expect(restored.paymentType, 'KPay');
      expect(restored.note, 'July bill');
    });
  });

  group('CategoryData', () {
    test('has expense categories', () {
      expect(CategoryData.expenseCategories.length, greaterThan(0));
    });

    test('has income categories', () {
      expect(CategoryData.incomeCategories.length, greaterThan(0));
    });

    test('findByName returns matching category', () {
      final cat = CategoryData.findByName('Salary');
      expect(cat, isNotNull);
      expect(cat!.name, 'Salary');
      expect(cat.type, TransactionType.income);
    });

    test('findByName returns null for unknown', () {
      expect(CategoryData.findByName('NonExistent'), isNull);
    });
  });

  group('AgentTransactionType', () {
    test('none label is None', () {
      expect(AgentTransactionType.none.label, 'None');
    });

    test('all types have labels', () {
      for (final type in AgentTransactionType.values) {
        expect(type.label.isNotEmpty, true);
      }
    });
  });

  group('TransactionType', () {
    test('has income and expense', () {
      expect(TransactionType.values.length, 2);
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
    });
  });
}
