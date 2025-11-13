import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:is_application/core/theme/app_colors.dart';

// FIX: Convert to a Provider.family to accept the brightness
final appThemeProvider = Provider.family<ThemeData, Brightness>((ref, brightness) {
  // Get the correct color palette by passing the brightness
  final colors = ref.watch(appColorsProvider(brightness));
  
  final textTheme = GoogleFonts.inclusiveSansTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.primaryLight,
    onSecondary: colors.onPrimary,
    surface: colors.surface,
    onSurface: colors.onSurface,
    error: colors.error,
    onError: colors.onError,
  );

  return ThemeData.from(
    colorScheme: colorScheme,
    textTheme: textTheme,
  ).copyWith(
    scaffoldBackgroundColor: colors.background,

    // --- Modern App Bar ---
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.onBackground,
      elevation: 0,
    ),

    // --- Button Themes ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),

    // --- Text Field Theme (Updated for new palette) ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface, // Use the white/dark surface color
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 20.0,
      ),
      // Use a subtle border by default
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colors.border, width: 1.5),
      ),
      // Use the primaryLight color for focus
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colors.primaryLight, width: 2.5),
      ),
    ),
  );
});