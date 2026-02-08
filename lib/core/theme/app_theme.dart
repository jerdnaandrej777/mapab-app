import 'package:flutter/material.dart';

/// App Design System
/// Farben inspiriert von MapAB, angepasst für Flutter Material 3
class AppTheme {
  AppTheme._();

  // Primärfarben
  static const Color primaryColor = Color(0xFF2563EB); // Blau
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Sekundärfarben
  static const Color secondaryColor = Color(0xFF10B981); // Grün
  static const Color accentColor = Color(0xFFF59E0B); // Orange/Gelb

  // Hintergrund
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Schatten
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: textHint),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.18),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
      ),
    );
  }

  // Dark Mode Farben
  static const Color darkBackgroundColor = Color(0xFF0F172A);
  static const Color darkSurfaceColor = Color(0xFF1E293B);
  static const Color darkCardColor = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  // OLED True Black Farben
  static const Color oledBackgroundColor = Color(0xFF000000);
  static const Color oledSurfaceColor = Color(0xFF121212);
  static const Color oledCardColor = Color(0xFF1E1E1E);

  /// Dark Theme - Vollständig implementiert
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkCardColor,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: primaryLight, width: 1.5),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: darkTextHint),
        labelStyle: const TextStyle(color: darkTextSecondary),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor,
        selectedColor: primaryLight.withValues(alpha: 0.3),
        labelStyle: const TextStyle(fontSize: 14, color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          color: darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceColor,
        modalBackgroundColor: darkSurfaceColor,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        textColor: darkTextPrimary,
        iconColor: darkTextSecondary,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: darkTextSecondary,
      ),

      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkTextPrimary),
        headlineMedium: TextStyle(color: darkTextPrimary),
        headlineSmall: TextStyle(color: darkTextPrimary),
        titleLarge: TextStyle(color: darkTextPrimary),
        titleMedium: TextStyle(color: darkTextPrimary),
        titleSmall: TextStyle(color: darkTextPrimary),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(color: darkTextPrimary),
        labelMedium: TextStyle(color: darkTextSecondary),
        labelSmall: TextStyle(color: darkTextHint),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight.withValues(alpha: 0.5);
          }
          return Colors.grey.shade800;
        }),
      ),
    );
  }

  /// OLED Dark Theme - True Black für AMOLED Displays
  static ThemeData get oledDarkTheme {
    final baseDark = darkTheme;
    return baseDark.copyWith(
      scaffoldBackgroundColor: oledBackgroundColor,
      cardColor: oledCardColor,
      appBarTheme: baseDark.appBarTheme.copyWith(
        backgroundColor: oledBackgroundColor,
      ),
      bottomNavigationBarTheme: baseDark.bottomNavigationBarTheme.copyWith(
        backgroundColor: oledBackgroundColor,
      ),
      dialogTheme: baseDark.dialogTheme.copyWith(
        backgroundColor: oledSurfaceColor,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: oledSurfaceColor,
        modalBackgroundColor: oledSurfaceColor,
      ),
    );
  }
}

/// Spacing Konstanten
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border Radius Konstanten
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}
