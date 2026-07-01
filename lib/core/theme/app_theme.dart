import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taftaf/core/constants/app_colors.dart';

const _poppins = 'Poppins';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      fontFamily: _poppins,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onSurface: Colors.black,
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: _poppins, fontSize: 34, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5),
        displayMedium: TextStyle(fontFamily: _poppins, fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: -0.3),
        headlineLarge: TextStyle(fontFamily: _poppins, fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
        headlineMedium:TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
        titleLarge:    TextStyle(fontFamily: _poppins, fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        titleMedium:   TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        bodyLarge:     TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
        bodyMedium:    TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.normal, color: Color(0xFF3A3A3C)),
        bodySmall:     TextStyle(fontFamily: _poppins, fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF8E8E93)),
        labelLarge:    TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w700,   color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          fontFamily: _poppins,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEAEAEF),
        hintStyle: const TextStyle(fontFamily: _poppins, color: Color(0xFF8E8E93), fontSize: 14),
        labelStyle: const TextStyle(fontFamily: _poppins, color: Color(0xFF3A3A3C), fontSize: 11, letterSpacing: 1.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAEAEF),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF8E8E93),
        showUnselectedLabels: false,
        showSelectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFD1D1D6), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(fontFamily: _poppins, color: Colors.black, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: _poppins,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.black,    // dark text/icons on lime backgrounds
        onSecondary: AppColors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: _poppins, fontSize: 34, fontWeight: FontWeight.w800,   color: AppColors.textPrimary,   letterSpacing: -0.5),
        displayMedium: TextStyle(fontFamily: _poppins, fontSize: 28, fontWeight: FontWeight.w700,   color: AppColors.textPrimary,   letterSpacing: -0.3),
        headlineLarge: TextStyle(fontFamily: _poppins, fontSize: 24, fontWeight: FontWeight.w700,   color: AppColors.textPrimary),
        headlineMedium:TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
        titleLarge:    TextStyle(fontFamily: _poppins, fontSize: 18, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
        titleMedium:   TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w500,   color: AppColors.textPrimary),
        bodyLarge:     TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
        bodyMedium:    TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
        bodySmall:     TextStyle(fontFamily: _poppins, fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textMuted),
        labelLarge:    TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w700,   color: AppColors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _poppins,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,   // dark text on lime
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontFamily: _poppins,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontFamily: _poppins,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: const TextStyle(fontFamily: _poppins, color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(fontFamily: _poppins, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: const TextStyle(fontFamily: _poppins, color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
