import 'package:flutter/material.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => isDark ? AppColors.background : const Color(0xFFF2F2F7);
  Color get surfaceColor => isDark ? AppColors.surface : Colors.white;
  Color get cardColor => isDark ? AppColors.cardDark : Colors.white;
  Color get textColor => isDark ? AppColors.white : Colors.black;
  Color get textSecColor => isDark ? AppColors.textSecondary : const Color(0xFF3A3A3C);
  Color get textMutedColor => isDark ? AppColors.textMuted : const Color(0xFF8E8E93);
  Color get divColor => isDark ? AppColors.divider : const Color(0xFFD1D1D6);
  Color get primarySurfColor => isDark ? AppColors.primarySurface : const Color(0xFFECF5CC);
  Color get inputBgColor => isDark ? AppColors.inputBg : const Color(0xFFEAEAEF);
}

class AppColors {
  // ── Accent — neon lime (matches Apple Fitness aesthetic) ──────────────────
  static const Color primary        = Color(0xFFBEFF0A);  // neon lime
  static const Color primaryLight   = Color(0xFFD5FF5C);  // lighter lime
  static const Color primaryDark    = Color(0xFF8CBB00);  // deeper lime
  static const Color primarySurface = Color(0xFF1C2800);  // very dark lime tint

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFF000000);  // pure black
  static const Color surface    = Color(0xFF1C1C1E);  // iOS dark surface
  static const Color cardBg     = Color(0xFFFFFFFF);
  static const Color cardDark   = Color(0xFF2C2C2E);  // iOS dark card

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);  // iOS secondary
  static const Color textDark      = Color(0xFF1A1A1A);
  static const Color textMuted     = Color(0xFF636366);  // iOS muted

  // ── Inputs ────────────────────────────────────────────────────────────────
  static const Color inputBg     = Color(0xFF2C2C2E);
  static const Color inputBorder = Color(0xFF48484A);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);  // iOS green
  static const Color error   = Color.fromARGB(255, 224, 90, 0);  // iOS red
  static const Color warning = Color(0xFFFFD60A);  // iOS yellow
  static const Color star    = Color(0xFFFFD60A);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color divider     = Color(0xFF38383A);
  static const Color overlay     = Color(0x80000000);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient buildingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
  );

  // Lime gradient — used on primary action buttons & FABs
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCFFF3A), Color(0xFF8CBB00)],
  );
}
