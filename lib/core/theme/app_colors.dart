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
  
  // Category Colors
  final Color categoryWork;
  final Color categoryPersonal;
  final Color categorySchool;

  const TasksPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.categoryWork,
    required this.categoryPersonal,
    required this.categorySchool,
  });
}

/// A dedicated grouping for the Chat Feature colors.
class ChatPalette {
  final Color background; // Main background
  final Color userBubble; // User message background
  final Color botBubble;  // Bot message background
  final Color userText;   // User message text
  final Color botText;    // Bot message text
  final Color inputBar;   // Input area background
  final Color accent;     // Send button / Icons

  const ChatPalette({
    required this.background,
    required this.userBubble,
    required this.botBubble,
    required this.userText,
    required this.botText,
    required this.inputBar,
    required this.accent,
  });
}

/// Abstract class defining the color palette for the app.
abstract class AppColors {
  // --- FEATURE: JOURNAL ---
  // Access this via `colors.journal.background`
  JournalPalette get journal;

  // --- FEATURE: CHAT ---
  ChatPalette get chat;

  // --- FEATURE: FOCUS ---
  FocusPalette get focus;

  // --- FEATURE: TASKS ---
  TasksPalette get tasks;

  // --- Primary (Action & Focus) ---
  Color get primary;       // Main action color
  Color get primaryLight;  // Lighter shade for accents
  Color get primaryDark;   // Darker shade for text/dark mode
  Color get onPrimary;     // Text on primary color
  
  // --- Gradients ---
  LinearGradient get primaryGradient; // Main brand gradient
  LinearGradient get surfaceGradient; // Subtle surface gradient

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
/// ADHD-Friendly: Warm, low-glare backgrounds, distinct but pastel accents.
class AppColorsLight implements AppColors {
  
  // --- JOURNAL PALETTE (Warm, Paper-like) ---
  @override
  JournalPalette get journal => const JournalPalette(
    background: Color(0xFFFFFBF0), // Creamy Paper
    accent:     Color(0xFFD97706), // Warm Amber
    ink:        Color(0xFF292524), // Warm Charcoal
    surface:    Color(0xFFFFFFFF), 
    canvas:     Color(0xFFF5F0E6), 
  );

  // --- CHAT PALETTE (Clean, Modern) ---
  @override
  ChatPalette get chat => const ChatPalette(
    background: Color(0xFFF8FAFC), // Very light slate
    userBubble: Color(0xFF4F46E5), // Premium Indigo
    botBubble:  Color(0xFFFFFFFF), 
    userText:   Color(0xFFFFFFFF), 
    botText:    Color(0xFF1E293B), // Slate 800
    inputBar:   Color(0xFFFFFFFF), 
    accent:     Color(0xFF4F46E5), 
  );

  // --- FOCUS PALETTE (Deep, Immersive) ---
  @override
  FocusPalette get focus => const FocusPalette(
    background: Color(0xFF18181B), // Zinc 900
    timer:      Color(0xFFE4E4E7), // Zinc 200
    accent:     Color(0xFF34D399), // Emerald 400
    card:       Color(0xFF27272A), // Zinc 800
  );

  // --- TASKS PALETTE (Productive, Crisp) ---
  @override
  TasksPalette get tasks => const TasksPalette(
    background: Color(0xFFF9FAFB), // Gray 50
    surface:    Color(0xFFFFFFFF), 
    textPrimary: Color(0xFF111827), // Gray 900
    textSecondary: Color(0xFF6B7280), // Gray 500
    accent:     Color(0xFF6366F1), // Indigo 500
    priorityHigh: Color(0xFFEF4444), // Red 500
    priorityMedium: Color(0xFFF59E0B), // Amber 500
    priorityLow: Color(0xFF3B82F6), // Blue 500
    categoryWork: Color(0xFF818CF8), 
    categoryPersonal: Color(0xFF34D399), 
    categorySchool: Color(0xFFFBBF24), 
  );

  // --- STANDARD APP PALETTE ---
  @override
  Color get primary => const Color(0xFF4F46E5);       // Indigo 600
  @override
  Color get primaryLight => const Color(0xFFE0E7FF);  // Indigo 100
  @override
  Color get primaryDark => const Color(0xFF3730A3);   // Indigo 800
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);     

  @override
  LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)], 
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  LinearGradient get surfaceGradient => const LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)], 
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Color get background => const Color(0xFFF9FAFB);    
  @override
  Color get onBackground => const Color(0xFF111827);  
  @override
  Color get surface => const Color(0xFFFFFFFF);       
  @override
  Color get onSurface => const Color(0xFF111827);     
  @override
  Color get border => const Color(0xFFE5E7EB);        

  @override
  Color get error => const Color(0xFFEF4444);         
  @override
  Color get onError => const Color(0xFFFFFFFF);

  @override
  Color get googleButton => const Color(0xFF4285F4);
}

/// Concrete implementation of [AppColors] for DARK mode
/// ADHD-Friendly: Deep, muted tones. Avoids pure black to reduce contrast strain (halation).
class AppColorsDark implements AppColors {
  
  // --- JOURNAL PALETTE (Cozy, Dark Mode) ---
  @override
  JournalPalette get journal => const JournalPalette(
    background: Color(0xFF1C1917), // Stone 900
    accent:     Color(0xFFF59E0B), // Amber 500
    ink:        Color(0xFFE7E5E4), // Stone 200
    surface:    Color(0xFF292524), // Stone 800
    canvas:     Color(0xFF0C0A09), // Stone 950
  );

  // --- CHAT PALETTE (Sleek, Dark Mode) ---
  @override
  ChatPalette get chat => const ChatPalette(
    background: Color(0xFF111827), // Gray 900
    userBubble: Color(0xFF6366F1), // Indigo 500
    botBubble:  Color(0xFF1F2937), // Gray 800
    userText:   Color(0xFFFFFFFF), 
    botText:    Color(0xFFF3F4F6), // Gray 100
    inputBar:   Color(0xFF1F2937), 
    accent:     Color(0xFF818CF8), // Indigo 400
  );

  // --- FOCUS PALETTE (Deep, Dark Mode) ---
  @override
  FocusPalette get focus => const FocusPalette(
    background: Color(0xFF09090B), // Zinc 950
    timer:      Color(0xFFE4E4E7), // Zinc 200
    accent:     Color(0xFF34D399), // Emerald 400
    card:       Color(0xFF18181B), // Zinc 900
  );

  // --- TASKS PALETTE (Dark Productivity) ---
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
    categoryWork: Color(0xFF6366F1), 
    categoryPersonal: Color(0xFF34D399), 
    categorySchool: Color(0xFFFBBF24), 
  );

  // --- STANDARD APP PALETTE ---
  @override
  Color get primary => const Color(0xFF818CF8);       // Indigo 400
  @override
  Color get primaryLight => const Color(0xFF3730A3);  // Indigo 800
  @override
  Color get primaryDark => const Color(0xFF312E81);   // Indigo 900
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);     

  @override
  LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], 
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  LinearGradient get surfaceGradient => const LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)], 
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Color get background => const Color(0xFF0F172A);    
  @override
  Color get onBackground => const Color(0xFFF1F5F9);  
  @override
  Color get surface => const Color(0xFF1E293B);       
  @override
  Color get onSurface => const Color(0xFFF1F5F9);     
  @override
  Color get border => const Color(0xFF334155);        

  @override
  Color get error => const Color(0xFFF87171);         
  @override
  Color get onError => const Color(0xFFFFFFFF);

  @override
  Color get googleButton => const Color(0xFF4285F4);
}