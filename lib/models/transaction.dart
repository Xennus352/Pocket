class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final AgentTransactionType? agentTxnType;
  final double commission;
  final String? customerName;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.agentTxnType,
    this.commission = 0,
    this.customerName,
  });

  bool get isAgent => agentTxnType != null && agentTxnType != AgentTransactionType.none;

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'agent_txn_type': agentTxnType?.name,
        'commission': commission,
        'customer_name': customerName,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final rawType = map['agent_txn_type'] as String?;
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      category: map['category'] as String,
      date: map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      agentTxnType: rawType != null
          ? AgentTransactionType.values.firstWhere((e) => e.name == rawType)
          : null,
      commission: (map['commission'] as num?)?.toDouble() ?? 0,
      customerName: map['customer_name'] as String?,
    );
  }
}

enum TransactionType { income, expense }

enum AgentTransactionType {
  cashIn,
  cashOut,
  transfer,
  billPayment,
  topUp,
  none;

  String get label {
    switch (this) {
      case cashIn:
        return 'Cash-In';
      case cashOut:
        return 'Cash-Out';
      case transfer:
        return 'Transfer';
      case billPayment:
        return 'Bill Payment';
      case topUp:
        return 'Top-Up';
      case none:
        return 'None';
    }
  }
}

class CategoryInfo {
  final String name;
  final int iconCodePoint;
  final TransactionType type;

  const CategoryInfo({required this.name, required this.iconCodePoint, required this.type});
}

class CategoryData {
  static const expenseCategories = [
    CategoryInfo(name: 'Food & Drinks', iconCodePoint: 0xe56c, type: TransactionType.expense),
    CategoryInfo(name: 'Shopping', iconCodePoint: 0xe8cc, type: TransactionType.expense),
    CategoryInfo(name: 'Transport', iconCodePoint: 0xe531, type: TransactionType.expense),
    CategoryInfo(name: 'Entertainment', iconCodePoint: 0xe042, type: TransactionType.expense),
    CategoryInfo(name: 'Bills & Utilities', iconCodePoint: 0xe8b8, type: TransactionType.expense),
    CategoryInfo(name: 'Health', iconCodePoint: 0xe8e8, type: TransactionType.expense),
    CategoryInfo(name: 'Education', iconCodePoint: 0xe80c, type: TransactionType.expense),
    CategoryInfo(name: 'Travel', iconCodePoint: 0xe53a, type: TransactionType.expense),
    CategoryInfo(name: 'Groceries', iconCodePoint: 0xe8d8, type: TransactionType.expense),
    CategoryInfo(name: 'Other', iconCodePoint: 0xe2c6, type: TransactionType.expense),
  ];

  static const incomeCategories = [
    CategoryInfo(name: 'Salary', iconCodePoint: 0xf0d0, type: TransactionType.income),
    CategoryInfo(name: 'Freelance', iconCodePoint: 0xe30c, type: TransactionType.income),
    CategoryInfo(name: 'Investment', iconCodePoint: 0xe8d4, type: TransactionType.income),
    CategoryInfo(name: 'Gifts', iconCodePoint: 0xe639, type: TransactionType.income),
    CategoryInfo(name: 'Other', iconCodePoint: 0xe2c6, type: TransactionType.income),
  ];

  static List<CategoryInfo> getCategories(TransactionType type) =>
      type == TransactionType.expense ? expenseCategories : incomeCategories;

  static CategoryInfo? findByName(String name) {
    for (final c in [...expenseCategories, ...incomeCategories]) {
      if (c.name == name) return c;
    }
    return null;
  }
}
