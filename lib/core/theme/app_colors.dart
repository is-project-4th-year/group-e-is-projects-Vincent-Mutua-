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

/// A dedicated grouping for the Focus Feature colors.
class FocusPalette {
  final Color background; // Deep dark background
  final Color timer;      // High contrast timer color
  final Color accent;     // Active state/Buttons
  final Color card;       // Surface for cards

  const FocusPalette({
    required this.background,
    required this.timer,
    required this.accent,
    required this.card,
  });
}

/// A dedicated grouping for the Tasks Feature colors.
class TasksPalette {
  final Color background; // Main background
  final Color surface;    // Cards/Lists
  final Color textPrimary; // Main text
  final Color textSecondary; // Subtitles/Dates
  final Color accent;     // Primary action color (FAB, Checks)
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  const TasksPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
  });
}

/// Abstract class defining the color palette for the app.
abstract class AppColors {
  // --- FEATURE: JOURNAL ---
  // Access this via `colors.journal.background`
  JournalPalette get journal;

  // --- FEATURE: FOCUS ---
  FocusPalette get focus;

  // --- FEATURE: TASKS ---
  TasksPalette get tasks;

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

  // --- FOCUS PALETTE ---
  @override
  FocusPalette get focus => const FocusPalette(
    background: Color(0xFF121212), // Deep Dark Grey
    timer:      Color(0xFFE0E0E0), // Off-White
    accent:     Color(0xFF00E676), // Neon Green
    card:       Color(0xFF1E1E1E), // Dark Card
  );

  // --- TASKS PALETTE ---
  @override
  TasksPalette get tasks => const TasksPalette(
    background: Color(0xFFF8FAFC), // Slate 50 (Clean White/Grey)
    surface:    Color(0xFFFFFFFF), // Pure White
    textPrimary: Color(0xFF1E293B), // Slate 800
    textSecondary: Color(0xFF64748B), // Slate 500
    accent:     Color(0xFF6366F1), // Indigo 500
    priorityHigh: Color(0xFFEF4444), // Red 500
    priorityMedium: Color(0xFFF59E0B), // Amber 500
    priorityLow: Color(0xFF3B82F6), // Blue 500
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
    background: Color.fromARGB(255, 63, 61, 61), 
    accent:     Color(0xFFD4A86A), // Muted Gold/Tan (Keeps the classic feel)
    ink:        Color(0xFFE0E0E0), // High Contrast Light Grey/White Text
    surface:    Color.fromARGB(255, 26, 25, 25), // Slightly lighter grey for toolbars
    canvas:     Color.fromARGB(255, 39, 38, 38), // Pure Black canvas
  );

  // --- FOCUS PALETTE (Same as Light for now, Focus is always dark) ---
  @override
  FocusPalette get focus => const FocusPalette(
    background: Color(0xFF000000), // Pure Black for OLED
    timer:      Color(0xFFFFFFFF), // Pure White
    accent:     Color(0xFF69F0AE), // Slightly softer Neon Green
    card:       Color(0xFF121212), // Very Dark Grey
  );

  // --- TASKS PALETTE ---
  @override
  TasksPalette get tasks => const TasksPalette(
    background: Color(0xFF0F172A), // Slate 900
    surface:    Color(0xFF1E293B), // Slate 800
    textPrimary: Color(0xFFF1F5F9), // Slate 100
    textSecondary: Color(0xFF94A3B8), // Slate 400
    accent:     Color(0xFF818CF8), // Indigo 400
    priorityHigh: Color(0xFFF87171), // Red 400
    priorityMedium: Color(0xFFFBBF24), // Amber 400
    priorityLow: Color(0xFF60A5FA), // Blue 400
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