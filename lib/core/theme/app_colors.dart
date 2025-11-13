import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FIX: Convert to a Provider.family
// This allows our ThemeProvider to tell this provider
// whether to build light or dark colors.
final appColorsProvider = Provider.family<AppColors, Brightness>((ref, brightness) {
  switch (brightness) {
    case Brightness.light:
      return AppColorsLight();
    case Brightness.dark:
      return AppColorsDark();
  }
});

// We no longer need the separate 'brightnessProvider'

/// Abstract class defining the color palette for the app.
abstract class AppColors {
  // --- Primary (Action & Focus) ---
  Color get primary;       // Main action color
  Color get primaryLight;  // Lighter shade for accents
  Color get primaryDark;   // Darker shade for text/dark mode
  Color get onPrimary;     // Text on primary color

  // --- Background/Hierarchy ---
  Color get background;    // Light blue background
  Color get surface;       // White cards/fields
  Color get onBackground;  // Text on background
  Color get onSurface;     // Text on surface
  Color get border;        // Border for text fields

  // --- Utility/Status ---
  Color get error;
  Color get onError;

  // --- Custom/Auth ---
  Color get googleButton;
}

/// Concrete implementation of [AppColors] for LIGHT mode
class AppColorsLight implements AppColors {
  // Your Palette:
  @override
  Color get primary => const Color(0xFF3B82F6);       // Strong Blue
  @override
  Color get primaryLight => const Color(0xFF60A5FA);  // Lighter Blue
  @override
  Color get primaryDark => const Color(0xFF1E3A8A);   // Dark Navy Blue
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);     // White text

  // Background/Hierarchy
  @override
  Color get background => const Color(0xFFEBF8FF);   // Very Light Blue
  @override
  Color get onBackground => const Color(0xFF1E3A8A); // Dark Navy text
  @override
  Color get surface => const Color(0xFFFFFFFF);     // White cards
  @override
  Color get onSurface => const Color(0xFF1E3A8A);  // Dark Navy text
  @override
  Color get border => const Color(0xFF60A5FA).withAlpha(128); // Accent border

  // Utility
  @override
  Color get error => const Color(0xFFD32F2F);
  @override
  Color get onError => const Color(0xFFFFFFFF);

  // Custom
  @override
  Color get googleButton => const Color(0xFF4285F4);
}

/// Concrete implementation of [AppColors] for DARK mode
class AppColorsDark implements AppColors {
  // Your Palette (re-interpreted for dark mode)
  @override
  Color get primary => const Color(0xFF60A5FA);       // Light Blue (main action)
  @override
  Color get primaryLight => const Color(0xFFEBF8FF);  // Lightest Blue
  @override
  Color get primaryDark => const Color(0xFF3B82F6);   // Mid Blue
  @override
  Color get onPrimary => const Color(0xFF1E3A8A);     // Dark Navy text

  // Background/Hierarchy
  @override
  Color get background => const Color(0xFF1E3A8A);   // Dark Navy background
  @override
  Color get onBackground => const Color(0xFFEBF8FF); // Lightest Blue text
  @override
  Color get surface => const Color(0xFF294b9b); // Slightly lighter navy for cards
  @override
  Color get onSurface => const Color(0xFFEBF8FF);    // Lightest Blue text
  @override
  Color get border => const Color(0xFF3B82F6);       // Mid Blue border

  // Utility
  @override
  Color get error => const Color(0xFFEF5350);
  @override
  Color get onError => const Color(0xFF1E3A8A);

  // Custom
  @override
  Color get googleButton => const Color(0xFF4285F4);
}