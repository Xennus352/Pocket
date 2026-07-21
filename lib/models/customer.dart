class Customer {
  final int? id;
  final String name;
  final String phone;
  final String walletType;
  final int transactionCount;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.walletType = 'KPay',
    this.transactionCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'wallet_type': walletType,
        'transaction_count': transactionCount,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        walletType: map['wallet_type'] as String? ?? 'KPay',
        transactionCount: (map['transaction_count'] as int?) ?? 0,
      );
}
