import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:is_application/core/theme/app_colors.dart';

// Provider for the ThemeMode (Light, Dark, System)
final appThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// FIX: Convert to a Provider.family to accept the brightness
final appThemeProvider = Provider.family<ThemeData, Brightness>((ref, brightness) {
  // Get the correct color palette by passing the brightness
  final colors = ref.watch(appColorsProvider(brightness));
  
  // 1. BASE TEXT THEME (Inter)
  // This remains the default for UI elements, buttons, and form inputs.
  // Inter is chosen for its high legibility on screens and modern look.
  final baseTextTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  // 2. EDITORIAL TEXT THEME (Serif Integration)
  // We override the "Headline" and "Display" styles to use Playfair Display.
  // This gives your Journal titles that elegant, book-like feel automatically.
  // NOTE: Commenting out to enforce Inter across the app for a clean productivity look.
  // Uncomment if you want to keep the serif headers for the Journal.
  /*
  final textTheme = baseTextTheme.copyWith(
    displayLarge: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.displayLarge),
    displayMedium: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.displayMedium),
    displaySmall: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.displaySmall),
    headlineLarge: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.headlineLarge),
    headlineMedium: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.headlineMedium),
    headlineSmall: GoogleFonts.playfairDisplay(textStyle: baseTextTheme.headlineSmall),
  );
  */
  final textTheme = baseTextTheme;

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

    // --- Text Field Theme (Global Default for Forms/Auth) ---
    // NOTE: We keep borders here for the Auth/Login screens.
    // Inside the JournalEntryScreen, we will locally override this to 'InputBorder.none'.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface, // Use the white/dark surface color
      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)), // More visible placeholders
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
