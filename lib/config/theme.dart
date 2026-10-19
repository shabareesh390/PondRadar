import 'package:flutter/material.dart';

/// Design tokens: colors, spacing, and sizing rules.
/// Kept flat with high contrast for outdoor visibility in sunlight.
class AppTokens {
  // Brand & neutral colors
  static const Color primary = Color(0xFF0F6E56);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E5E3);
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textSecondary = Color(0xFF5B6360);

  // Risk levels - always paired with an icon and label
  static const Color riskLow = Color(0xFF2E7D32);
  static const Color riskMedium = Color(0xFFB26A00);
  static const Color riskHigh = Color(0xFFC62828);

  // Spacing (8-pt grid)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Sizing & tap targets
  static const double cardRadius = 12.0;
  static const double controlRadius = 8.0;
  static const double buttonHeight = 52.0;
  static const double minTouchTarget = 48.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTokens.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppTokens.primary,
        onPrimary: AppTokens.onPrimary,
        secondary: AppTokens.primary,
        onSecondary: AppTokens.onPrimary,
        error: AppTokens.riskHigh,
        onError: AppTokens.onPrimary,
        surface: AppTokens.surface,
        onSurface: AppTokens.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppTokens.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppTokens.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppTokens.textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTokens.onPrimary,
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.surface,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
          height: 1.5,
        ),
        iconTheme: IconThemeData(color: AppTokens.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppTokens.border, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.cardRadius)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primary,
          side: const BorderSide(color: AppTokens.primary, width: 1.5),
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          borderSide: const BorderSide(color: AppTokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          borderSide: const BorderSide(color: AppTokens.riskHigh, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          borderSide: const BorderSide(color: AppTokens.riskHigh, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppTokens.textSecondary,
          fontSize: 15,
        ),
        hintStyle: const TextStyle(
          color: AppTokens.textSecondary,
          fontSize: 15,
        ),
        suffixStyle: const TextStyle(
          color: AppTokens.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        indicatorColor: AppTokens.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.primary);
          }
          return const IconThemeData(color: AppTokens.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.primary,
              height: 1.5,
            );
          }
          return const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTokens.textSecondary,
            height: 1.5,
          );
        }),
      ),
    );
  }
}
