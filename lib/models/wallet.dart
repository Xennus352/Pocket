import 'dart:convert';

class Wallet {
  String name;
  double balance;

  Wallet({required this.name, this.balance = 0});

  Map<String, dynamic> toMap() => {
        'name': name,
        'balance': balance,
      };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
        name: map['name'] as String,
        balance: (map['balance'] as num?)?.toDouble() ?? 0,
      );

  static String encodeList(List<Wallet> wallets) =>
      jsonEncode(wallets.map((w) => w.toMap()).toList());

  static List<Wallet> decodeList(String encoded) {
    try {
      final list = jsonDecode(encoded) as List;
      return list.map((e) => Wallet.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return encoded.split(',').map((n) => Wallet(name: n.trim())).toList();
    }
  }
}
