import 'package:flutter_test/flutter_test.dart';
import 'package:my_expense/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('compactAmount formats small numbers without abbreviation', () {
      expect(Formatters.compactAmount(0), '0');
      expect(Formatters.compactAmount(500), '500');
      expect(Formatters.compactAmount(99999), '99999');
    });

    test('compactAmount abbreviates thousands above 100K', () {
      expect(Formatters.compactAmount(100000), '100.0K');
      expect(Formatters.compactAmount(150000), '150.0K');
    });

    test('compactAmount abbreviates millions', () {
      expect(Formatters.compactAmount(1000000), '1.0M');
      expect(Formatters.compactAmount(2500000), '2.5M');
    });

    test('fullAmount returns integer string for round numbers', () {
      expect(Formatters.fullAmount(1000), '1000');
      expect(Formatters.fullAmount(50000), '50000');
    });

    test('fullAmount returns decimal string for non-round numbers', () {
      expect(Formatters.fullAmount(99.99), '99.99');
      expect(Formatters.fullAmount(1000.50), '1000.50');
    });
  });

  group('WalletHelper', () {
    test('iconFor returns an IconData', () {
      expect(WalletHelper.iconFor('KPay'), isNotNull);
      expect(WalletHelper.iconFor('WavePay'), isNotNull);
      expect(WalletHelper.iconFor('Cash'), isNotNull);
      expect(WalletHelper.iconFor('UnknownWallet'), isNotNull);
    });

    test('colorFor returns a Color', () {
      expect(WalletHelper.colorFor('KPay'), isNotNull);
      expect(WalletHelper.colorFor('WavePay'), isNotNull);
      expect(WalletHelper.colorFor('Cash'), isNotNull);
      expect(WalletHelper.colorFor('UnknownWallet'), isNotNull);
    });

    test('known wallets have distinct colors', () {
      final names = ['KPay', 'WavePay', 'CB Pay', 'AYA Pay', 'Cash', 'KBZ Pay'];
      final colors = names.map(WalletHelper.colorFor).toSet();
      expect(colors.length, names.length);
    });

    test('unknown wallet uses hash fallback', () {
      final color1 = WalletHelper.colorFor('Random1');
      final color2 = WalletHelper.colorFor('Random2');
      expect(color1, isNot(equals(color2)));
    });
  });
}
