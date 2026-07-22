import 'package:flutter_test/flutter_test.dart';
import 'package:my_expense/models/wallet.dart';

void main() {
  group('Wallet', () {
    test('creates with default balance 0', () {
      final w = Wallet(name: 'KPay');
      expect(w.name, 'KPay');
      expect(w.balance, 0);
    });

    test('creates with custom balance', () {
      final w = Wallet(name: 'WavePay', balance: 50000);
      expect(w.name, 'WavePay');
      expect(w.balance, 50000);
    });

    test('toMap and fromMap roundtrip', () {
      final w = Wallet(name: 'Cash', balance: 10000);
      final map = w.toMap();
      final restored = Wallet.fromMap(map);
      expect(restored.name, 'Cash');
      expect(restored.balance, 10000);
    });

    test('encodeList and decodeList roundtrip', () {
      final wallets = [
        Wallet(name: 'KPay', balance: 50000),
        Wallet(name: 'WavePay', balance: 30000),
      ];
      final encoded = Wallet.encodeList(wallets);
      final decoded = Wallet.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].name, 'KPay');
      expect(decoded[0].balance, 50000);
      expect(decoded[1].name, 'WavePay');
      expect(decoded[1].balance, 30000);
    });

    test('decodeList handles comma-separated fallback', () {
      final decoded = Wallet.decodeList('KPay,CB Pay');
      expect(decoded.length, 2);
      expect(decoded[0].name, 'KPay');
      expect(decoded[0].balance, 0);
      expect(decoded[1].name, 'CB Pay');
      expect(decoded[1].balance, 0);
    });
  });
}
