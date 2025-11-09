import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:is_application/core/theme/app_colors.dart';

/// This is the single source of truth for your app's theme.
///
/// It watches the [appColorsProvider] and [brightnessProvider].
/// When the system theme changes (light/dark), this provider will
/// automatically rebuild, providing the new, correct theme.
final appThemeProvider = Provider<ThemeData>((ref) {
  // Get the correct color palette (light or dark)
  final colors = ref.watch(appColorsProvider);
  
  // Get the current brightness
  final brightness = ref.watch(brightnessProvider);

  // Get the base text theme from Google Fonts
  final textTheme = GoogleFonts.inclusiveSansTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  // Create the master ColorScheme
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.primary, // You can make this different
    onSecondary: colors.onPrimary, // You can make this different
    surface: colors.surface,
    onSurface: colors.onSurface,
    error: colors.error,
    onError: colors.onError,
  );

  // Use ThemeData.from to create a theme from our ColorScheme
  // and then .copyWith to override specific widget themes.
  return ThemeData.from(
    colorScheme: colorScheme,
    textTheme: textTheme,
  ).copyWith(
    // --- App Bar Theme ---
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.onBackground,
      elevation: 0,
    ),

    // --- Text Form Field Theme ---
    // This styles all TextFormField/TextFields in the app
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.lightGreyFill,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 20.0,
      ),
      // Use a border with BorderSide.none to remove the underline
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    ),

    // --- Elevated Button Theme ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
});