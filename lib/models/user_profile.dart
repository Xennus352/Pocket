import 'wallet.dart';

class UserProfile {
  String name;
  String currency;
  double startingBalance;
  double monthlyBudget;
  List<Wallet> wallets;
  double warningThresholdPercent;

  UserProfile({
    this.name = 'Captain',
    this.currency = 'MMK',
    this.startingBalance = 0,
    this.monthlyBudget = 1000000,
    List<Wallet>? wallets,
    this.warningThresholdPercent = 20,
  }) : wallets = wallets ?? [Wallet(name: 'KPay'), Wallet(name: 'WavePay'), Wallet(name: 'Cash')];

  List<String> get walletNames => wallets.map((w) => w.name).toList();

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'currency': currency,
        'starting_balance': startingBalance,
        'monthly_budget': monthlyBudget,
        'wallets': Wallet.encodeList(wallets),
        'warning_threshold_percent': warningThresholdPercent,
        'id': 1,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: map['name'] as String? ?? 'Captain',
        currency: map['currency'] as String? ?? 'MMK',
        startingBalance: (map['starting_balance'] as num?)?.toDouble() ?? 0,
        monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 1000000,
        wallets: Wallet.decodeList(map['wallets'] as String? ?? 'KPay,WavePay,Cash'),
        warningThresholdPercent: (map['warning_threshold_percent'] as num?)?.toDouble() ?? 20,
      );
}
