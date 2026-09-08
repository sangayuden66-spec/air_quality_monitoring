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

class AppThemeState {
  static ThemeMode currentThemeMode = ThemeMode.light;

  static bool get isDarkMode => currentThemeMode == ThemeMode.dark;
}

class AppThemeStyles {
  static BoxDecoration cardDecoration({bool emphasized = false}) {
    final isDark = AppThemeState.isDarkMode;
    return BoxDecoration(
      color: isDark ? const Color(0xFF0B0B0B) : AppThemeColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? const Color(0xFF262626) : AppThemeColors.border,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0x99000000)
              : emphasized
              ? const Color(0x1A111827)
              : const Color(0x0F111827),
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

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      secondary: Color(0xFF8B5CF6),
      onSecondary: Colors.white,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: Color(0xFF0B0B0B),
      onSurface: Color(0xFFF5F5F5),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF0B0B0B),
      dividerColor: const Color(0xFF262626),
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFFF8FAFC),
        displayColor: const Color(0xFFF8FAFC),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0B0B0B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF262626)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121212),
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIconColor: const Color(0xFFCBD5E1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262626)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262626)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppThemeColors.primary,
            width: 1.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
