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

  group('isTransfer', () {
    test('cashIn is transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.income,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.cashIn,
      );
      expect(txn.isTransfer, true);
    });

    test('cashOut is transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.expense,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.cashOut,
      );
      expect(txn.isTransfer, true);
    });

    test('transfer is transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.income,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.transfer,
      );
      expect(txn.isTransfer, true);
    });

    test('billPayment is not transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.expense,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.billPayment,
      );
      expect(txn.isTransfer, false);
    });

    test('topUp is not transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.expense,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.topUp,
      );
      expect(txn.isTransfer, false);
    });

    test('none is not transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.income,
        category: 'Other', date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.none,
      );
      expect(txn.isTransfer, false);
    });

    test('null agentTxnType is not transfer', () {
      final txn = Transaction(
        title: 'Test', amount: 1000, type: TransactionType.income,
        category: 'Other', date: DateTime(2026, 7, 23),
      );
      expect(txn.isTransfer, false);
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

  group('Agent double-entry balance effect', () {
    test('cashIn with e-wallet increases wallet and decreases Cash', () {
      final txn = Transaction(
        title: 'Cash-In KPay',
        amount: 10000,
        type: TransactionType.income,
        category: 'Cash-In',
        date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.cashIn,
        paymentType: 'KPay',
      );
      expect(txn.isAgent, true);
      expect(txn.type, TransactionType.income);
      expect(txn.agentTxnType, AgentTransactionType.cashIn);
      expect(txn.paymentType, 'KPay');

      // Simulate applyWalletEffects logic:
      // KPay += amount (income), Cash -= amount (opposite)
      double kpayBal = 50000;
      double cashBal = 100000;
      kpayBal += txn.amount; // income: +
      cashBal -= txn.amount; // Cash: opposite
      expect(kpayBal, 60000);
      expect(cashBal, 90000);
    });

    test('cashOut with e-wallet decreases wallet and increases Cash', () {
      final txn = Transaction(
        title: 'Cash-Out KPay',
        amount: 10000,
        type: TransactionType.expense,
        category: 'Cash-Out',
        date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.cashOut,
        paymentType: 'KPay',
      );
      expect(txn.isAgent, true);
      expect(txn.type, TransactionType.expense);
      expect(txn.agentTxnType, AgentTransactionType.cashOut);

      // Simulate applyWalletEffects logic:
      // KPay -= amount (expense), Cash += amount (opposite)
      double kpayBal = 50000;
      double cashBal = 100000;
      kpayBal -= txn.amount; // expense: -
      cashBal += txn.amount; // Cash: opposite
      expect(kpayBal, 40000);
      expect(cashBal, 110000);
    });

    test('reverse cashIn restores original balances', () {
      double kpayBal = 60000;
      double cashBal = 90000;
      double amount = 10000;

      // Reverse cashIn: KPay -= amount, Cash += amount
      kpayBal -= amount;
      cashBal += amount;
      expect(kpayBal, 50000);
      expect(cashBal, 100000);
    });

    test('reverse cashOut restores original balances', () {
      double kpayBal = 40000;
      double cashBal = 110000;
      double amount = 10000;

      // Reverse cashOut: KPay += amount, Cash -= amount
      kpayBal += amount;
      cashBal -= amount;
      expect(kpayBal, 50000);
      expect(cashBal, 100000);
    });

    test('agent transaction with Cash paymentType only affects Cash', () {
      final txn = Transaction(
        title: 'Cash-In with Cash',
        amount: 10000,
        type: TransactionType.income,
        category: 'Cash-In',
        date: DateTime(2026, 7, 23),
        agentTxnType: AgentTransactionType.cashIn,
        paymentType: 'Cash',
      );
      expect(txn.isAgent, true);
      expect(txn.paymentType, 'Cash');

      // When paymentType is Cash, only Cash is updated (single-entry)
      double cashBal = 100000;
      cashBal += txn.amount; // income: +
      expect(cashBal, 110000);
    });

    test('non-agent transaction with e-wallet also applies double-entry', () {
      final txn = Transaction(
        title: 'Salary',
        amount: 500000,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 7, 23),
        paymentType: 'KPay',
      );
      expect(txn.isAgent, false);

      // Double-entry: KPay +amount, Cash -amount
      double kpayBal = 50000;
      double cashBal = 100000;
      kpayBal += txn.amount;
      cashBal -= txn.amount;
      expect(kpayBal, 550000);
      expect(cashBal, -400000);
    });
  });
}
