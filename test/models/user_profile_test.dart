import 'package:flutter_test/flutter_test.dart';
import 'package:my_expense/models/user_profile.dart';
import 'package:my_expense/models/wallet.dart';

void main() {
  group('UserProfile', () {
    test('creates with defaults', () {
      final profile = UserProfile();
      expect(profile.currency, 'MMK');
      expect(profile.wallets.length, 3);
      expect(profile.walletNames.length, 3);
      expect(profile.warningThresholdPercent, 20);
    });

    test('walletNames returns names list', () {
      final profile = UserProfile(
        wallets: [
          Wallet(name: 'KPay', balance: 50000),
          Wallet(name: 'WavePay', balance: 30000),
        ],
      );
      expect(profile.walletNames, ['KPay', 'WavePay']);
    });

    test('toMap and fromMap roundtrip', () {
      final profile = UserProfile(
        currency: 'USD',
        monthlyBudget: 2000,
        startingBalance: 10000,
        wallets: [
          Wallet(name: 'Cash', balance: 5000),
        ],
        warningThresholdPercent: 15,
      );
      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored.currency, 'USD');
      expect(restored.monthlyBudget, 2000);
      expect(restored.startingBalance, 10000);
      expect(restored.wallets.length, 1);
      expect(restored.wallets[0].name, 'Cash');
      expect(restored.wallets[0].balance, 5000);
      expect(restored.warningThresholdPercent, 15);
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{};
      final profile = UserProfile.fromMap(map);
      expect(profile.currency, 'MMK');
      expect(profile.wallets.length, 3);
      expect(profile.warningThresholdPercent, 20);
    });
  });
}
