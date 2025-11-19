import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider that returns the correct color implementation based on Brightness
final appColorsProvider = Provider.family<AppColors, Brightness>((ref, brightness) {
  switch (brightness) {
    case Brightness.light:
      return AppColorsLight();
    case Brightness.dark:
      return AppColorsDark();
  }
});

/// A dedicated grouping for the Journal Feature colors.
/// This helps separate the "Medical/Blue" app theme from the "Warm/Paper" journal theme.
class JournalPalette {
  final Color background; // The main paper background
  final Color accent;     // Highlights, active states, and buttons
  final Color ink;        // The text color
  final Color surface;    // Floating toolbars/menus
  final Color canvas;     // Secondary backgrounds (bottom bars)

  const JournalPalette({
    required this.background,
    required this.accent,
    required this.ink,
    required this.surface,
    required this.canvas,
  });
}

/// Abstract class defining the color palette for the app.
abstract class AppColors {
  // --- FEATURE: JOURNAL ---
  // Access this via `colors.journal.background`
  JournalPalette get journal;

  // --- Primary (Action & Focus) ---
  Color get primary;       // Main action color
  Color get primaryLight;  // Lighter shade for accents
  Color get primaryDark;   // Darker shade for text/dark mode
  Color get onPrimary;     // Text on primary color

  // --- Background/Hierarchy ---
  Color get background;    // General App background
  Color get surface;       // General App cards/fields
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
  
  // --- JOURNAL PALETTE (Your Custom Colors) ---
  @override
  JournalPalette get journal => const JournalPalette(
    background: Color(0xFFFFF7EC), // Warm Cream Paper
    accent:     Color(0xFFF0CEA0), // Tan/Orange Highlight
    ink:        Color(0xFF0F0F0F), // Near Black Text
    surface:    Color(0xFFFFFFFF), // Pure White (Toolbars)
    canvas:     Color(0xFFF5F5F5), // Light Grey (Bottom areas)
  );

  // --- STANDARD APP PALETTE (The Existing Blue Theme) ---
  @override
  Color get primary => const Color(0xFF3B82F6);       // Strong Blue
  @override
  Color get primaryLight => const Color(0xFF60A5FA);  // Lighter Blue
  @override
  Color get primaryDark => const Color(0xFF1E3A8A);   // Dark Navy Blue
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);     // White text

  @override
  Color get background => const Color(0xFFEBF8FF);    // Very Light Blue
  @override
  Color get onBackground => const Color(0xFF1E3A8A);  // Dark Navy text
  @override
  Color get surface => const Color(0xFFFFFFFF);       // White cards
  @override
  Color get onSurface => const Color(0xFF1E3A8A);     // Dark Navy text
  @override
  Color get border => const Color(0xFF60A5FA).withAlpha(128); 

  @override
  Color get error => const Color(0xFFD32F2F);
  @override
  Color get onError => const Color(0xFFFFFFFF);

  @override
  Color get googleButton => const Color(0xFF4285F4);
}

/// Concrete implementation of [AppColors] for DARK mode
class AppColorsDark implements AppColors {
  
  // --- JOURNAL PALETTE (Dark Mode Interpretation) ---
  // Since a bright cream paper will hurt eyes in dark mode, 
  // we invert the logic to Dark Grey paper + Cream text.
  @override
  JournalPalette get journal => const JournalPalette(
    background: Color(0xFF1A1A1A), // Dark Grey Paper
    accent:     Color(0xFFD4A86A), // Muted Gold/Tan
    ink:        Color(0xFFFFF7EC), // Cream Text (Readable on dark)
    surface:    Color(0xFF2C2C2E), // Dark Surface for toolbars
    canvas:     Color(0xFF0F0F0F), // Near Black canvas
  );

  // --- STANDARD APP PALETTE (The Existing Dark Theme) ---
  @override
  Color get primary => const Color(0xFF60A5FA);       
  @override
  Color get primaryLight => const Color(0xFFEBF8FF);  
  @override
  Color get primaryDark => const Color(0xFF3B82F6);   
  @override
  Color get onPrimary => const Color(0xFF1E3A8A);     

  @override
  Color get background => const Color(0xFF1E3A8A);   
  @override
  Color get onBackground => const Color(0xFFEBF8FF); 
  @override
  Color get surface => const Color(0xFF294b9b); 
  @override
  Color get onSurface => const Color(0xFFEBF8FF);    
  @override
  Color get border => const Color(0xFF3B82F6);       

  @override
  Color get error => const Color(0xFFEF5350);
  @override
  Color get onError => const Color(0xFF1E3A8A);

  @override
  Color get googleButton => const Color(0xFF4285F4);
}