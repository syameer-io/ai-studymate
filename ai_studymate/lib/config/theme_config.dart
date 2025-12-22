import 'package:flutter/material.dart';

/// Theme configuration for the app
///
/// Defines colors, text styles, and visual appearance.
/// Based on the design specifications in the project plan.

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C63FF);      // Purple - main brand color
  static const Color secondary = Color(0xFF2EC4B6);    // Teal - accent color
  static const Color accent = Color(0xFFFF6B6B);       // Coral - highlights

  // Background colors
  static const Color background = Color(0xFFF8F9FA);   // Light gray background
  static const Color surface = Color(0xFFFFFFFF);      // White card surfaces
  static const Color surfaceVariant = Color(0xFFF0F0F0);

  // Text colors
  static const Color textPrimary = Color(0xFF2D3436);  // Dark gray for main text
  static const Color textSecondary = Color(0xFF636E72); // Medium gray for secondary
  static const Color textLight = Color(0xFF95A5A6);    // Light gray for hints

  // Status colors
  static const Color success = Color(0xFF00B894);      // Green for success
  static const Color warning = Color(0xFFFDCB6E);      // Yellow for warnings
  static const Color error = Color(0xFFE74C3C);        // Red for errors
  static const Color info = Color(0xFF74B9FF);         // Blue for info

  // Flashcard difficulty colors
  static const Color easy = Color(0xFF00B894);
  static const Color medium = Color(0xFFFDCB6E);
  static const Color hard = Color(0xFFE74C3C);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.background,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
