import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color skyBlue = Color(0xFF7EC8E3);
  static const Color iceBlue = Color(0xFFE8F4FD);
  static const Color lightCyan = Color(0xFFB8E2F2);
  static const Color violetHint = Color(0xFF8B8FE8);
  static const Color violetLight = Color(0xFFC4C6F0);
  static const Color darkNavy = Color(0xFF0A1628);
  static const Color darkNavySoft = Color(0xFF1A2A44);
  static const Color whiteGlass = Color(0xCCFFFFFF);
  static const Color whitePure = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0x4DFFFFFF);
  static const Color glassShadow = Color(0x1A000000);
  static const Color glassOverlay = Color(0x0DFFFFFF);

  static const Color income = Color(0xFF34C759);
  static const Color expense = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);

  static const Color bgStart = Color(0xFFE8F0FE);
  static const Color bgEnd = Color(0xFFF0E8FF);
  static const Color cardGlassStart = Color(0xCCFFFFFF);
  static const Color cardGlassEnd = Color(0x99FFFFFF);
  static const Color walletGradStart = Color(0xFF4A90D9);
  static const Color walletGradEnd = Color(0xFF7C5CBF);

  static const List<Color> glassGradient = [
    Color(0xE8FFFFFF),
    Color(0xB3FFFFFF),
  ];

  static const List<Color> walletGradient = [
    Color(0xFF5B7FFF),
    Color(0xFF8B5CF6),
  ];

  static const Color primaryBlue = Color(0xFF5B7FFF);
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static Color dynamicBgStart(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117)
          : bgStart;

  static Color dynamicBgEnd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117)
          : bgEnd;

  static Color dynamicTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE8EDF5)
          : textPrimary;

  static Color dynamicTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9CA3AF)
          : textSecondary;

  static Color dynamicTextTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6B7280)
          : textTertiary;

  static Color dynamicGlassBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xCC1A1F2E)
          : whiteGlass;

  static Color dynamicGlassBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x4D6B7280)
          : glassBorder;
}
