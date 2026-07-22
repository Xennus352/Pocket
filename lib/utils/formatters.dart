import 'package:flutter/material.dart';

class Formatters {
  Formatters._();

  static const double _compactThreshold = 100000;

  static String compactAmount(double value) {
    if (value.abs() < _compactThreshold) {
      return _formatAmount(value);
    }
    if (value.abs() >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  static String fullAmount(double value) {
    return _formatAmount(value);
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class WalletHelper {
  WalletHelper._();

  static const _walletIconMap = <String, IconData>{
    'KPay': Icons.phone_iphone_rounded,
    'WavePay': Icons.waves_rounded,
    'Cash': Icons.monetization_on_rounded,
    'AyaPay': Icons.account_balance_rounded,
    'Mytel Pay': Icons.sim_card_rounded,
    'Mytel': Icons.sim_card_rounded,
    'CB Pay': Icons.credit_card_rounded,
    'KBZ Pay': Icons.account_balance_wallet_rounded,
    'UAB Pay': Icons.account_balance_rounded,
    'TrueMoney': Icons.money_rounded,
    'OK\$': Icons.money_rounded,
  };

  static const _fallbackIcons = <IconData>[
    Icons.account_balance_wallet_rounded,
    Icons.payment_rounded,
    Icons.credit_card_rounded,
    Icons.mobile_friendly_rounded,
    Icons.smartphone_rounded,
    Icons.card_giftcard_rounded,
    Icons.savings_rounded,
  ];

  static const _walletColorMap = <String, Color>{
    'KPay': Color(0xFF007AFF),
    'WavePay': Color(0xFF00A651),
    'Cash': Color(0xFFFF9500),
    'AyaPay': Color(0xFF6B21A8),
    'Mytel Pay': Color(0xFFDC2626),
    'Mytel': Color(0xFFDC2626),
    'CB Pay': Color(0xFF2563EB),
    'KBZ Pay': Color(0xFFBE123C),
    'UAB Pay': Color(0xFF0D9488),
    'TrueMoney': Color(0xFFD97706),
    'OK\$': Color(0xFF059669),
  };

  static const _fallbackColors = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFF1D4ED8),
  ];

  static IconData iconFor(String wallet) {
    return _walletIconMap[wallet] ?? _fallbackIcons[wallet.hashCode.abs() % _fallbackIcons.length];
  }

  static Color colorFor(String wallet) {
    return _walletColorMap[wallet] ?? _fallbackColors[wallet.hashCode.abs() % _fallbackColors.length];
  }
}
