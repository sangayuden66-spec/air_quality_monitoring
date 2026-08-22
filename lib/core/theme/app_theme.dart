import 'package:flutter/material.dart';

class AppThemeColors {
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5EAF3);
  static const Color primary = Color(0xFF2D7EF7);
  static const Color secondary = Color(0xFF8A2BE2);
  static const Color accent = Color(0xFFF5B400);
}

class AppThemeStyles {
  static BoxDecoration cardDecoration({bool emphasized = false}) {
    return BoxDecoration(
      color: AppThemeColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppThemeColors.border),
      boxShadow: [
        BoxShadow(
          color: emphasized ? const Color(0x1A111827) : const Color(0x0F111827),
          blurRadius: emphasized ? 14 : 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppThemeColors.primary, AppThemeColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData lightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppThemeColors.primary,
      onPrimary: Colors.white,
      secondary: AppThemeColors.secondary,
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: AppThemeColors.surface,
      onSurface: AppThemeColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppThemeColors.background,
      cardColor: AppThemeColors.surface,
      dividerColor: const Color(0xFFEDEFF4),
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppThemeColors.surface,
        foregroundColor: AppThemeColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppThemeColors.textPrimary,
        displayColor: AppThemeColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppThemeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppThemeColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemeColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppThemeColors.textPrimary,
          side: const BorderSide(color: AppThemeColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppThemeColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.surface,
        labelStyle: const TextStyle(color: AppThemeColors.textSecondary),
        hintStyle: const TextStyle(color: AppThemeColors.textSecondary),
        prefixIconColor: AppThemeColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppThemeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppThemeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppThemeColors.primary,
            width: 1.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppThemeColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
