import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Light + dark [ThemeData] built from the Figma design tokens.
/// Headings use Outfit (Bold/ExtraBold), body/UI text uses Figtree —
/// matching the two font families used throughout every mobile frame.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme({required Color primary, required Color secondary}) {
    final base = GoogleFonts.figtreeTextTheme();
    final outfit = GoogleFonts.outfitTextTheme();
    return base.copyWith(
      displayLarge: outfit.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: primary),
      displayMedium: outfit.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: primary),
      headlineLarge: outfit.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: primary, fontSize: 28),
      headlineMedium: outfit.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: primary, fontSize: 24),
      headlineSmall: outfit.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: primary, fontSize: 18),
      titleLarge: outfit.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: primary, fontSize: 16),
      titleMedium: outfit.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: primary, fontSize: 15),
      titleSmall: outfit.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: primary, fontSize: 14),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontSize: 15),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, fontSize: 14),
      bodySmall: base.bodySmall?.copyWith(color: secondary, fontSize: 12),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: primary, fontSize: 15),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: secondary, fontSize: 13),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: secondary, fontSize: 11),
    );
  }

  static ThemeData get light {
    const primary = AppColors.lightTextPrimary;
    const secondary = AppColors.lightTextSecondary;
    final colorScheme = ColorScheme.light(
      primary: AppColors.lightAccent,
      onPrimary: AppColors.white,
      secondary: AppColors.lightAccent,
      surface: AppColors.lightSurface,
      onSurface: primary,
      error: const Color(0xFFD64545),
      outline: AppColors.lightBorder,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      textTheme: _textTheme(primary: primary, secondary: secondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSearchFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.lightAccent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    const primary = AppColors.darkTextPrimary;
    const secondary = AppColors.darkTextSecondary;
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkAccent,
      onPrimary: AppColors.darkTextPrimary,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkSurface,
      onSurface: primary,
      error: const Color(0xFFE57373),
      outline: AppColors.darkBorder,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      textTheme: _textTheme(primary: primary, secondary: secondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkNeutralTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkAccent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccent,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
