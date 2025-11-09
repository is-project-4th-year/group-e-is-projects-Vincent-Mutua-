import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that returns the correct [AppColors] based on system brightness.
final appColorsProvider = Provider<AppColors>((ref) {
  // We use 'watch' here, but since this provider is unlikely to change
  // during the app's lifecycle (unless the user changes system theme),
  // it's efficient.
  final brightness = ref.watch(brightnessProvider);
  
  // Return the correct color implementation
  switch (brightness) {
    case Brightness.light:
      return AppColorsLight();
    case Brightness.dark:
      return AppColorsDark();
  }
});

/// A provider that exposes the current system brightness.
/// This is useful for widgets that need to adapt manually.
final brightnessProvider = Provider<Brightness>((ref) {
  // This is a placeholder. In a real app, you might get this
  // from a theme service or directly from MediaQuery.
  // For now, we'll just default to light.
  return Brightness.light;
  // Example for watching system theme:
  // final platformBrightness = View.of(ref.context).platformDispatcher.platformBrightness;
  // return platformBrightness;
});

/// Abstract class defining the color palette for the app.
/// This ensures that both light and dark themes have the same
/// set of colors defined.
abstract class AppColors {
  // --- Primary ---
  Color get primary;
  Color get onPrimary; // Text/icons on top of 'primary'

  // --- Background ---
  Color get background;
  Color get onBackground; // Text/icons on top of 'background'
  Color get surface;      // Cards, dialogs, bottom sheets
  Color get onSurface;    // Text/icons on top of 'surface'

  // --- Utility ---
  Color get border;
  Color get error;
  Color get onError;

  // --- Custom ---
  // Add specific colors from your Figma here
  Color get googleButton;
  Color get onGoogleButton;
  Color get lightGreyFill;
}

/// Concrete implementation of [AppColors] for LIGHT mode.
class AppColorsLight implements AppColors {
  // Define your light theme colors from Figma here
  // Example using Material-style hex codes

  @override
  Color get primary => const Color(0xFF0052D4); // Example: A strong blue

  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  @override
  Color get background => const Color(0xFFFFFFFF);

  @override
  Color get onBackground => const Color(0xFF1B1B1F);

  @override
  Color get surface => const Color(0xFFFDFDFD);

  @override
  Color get onSurface => const Color(0xFF1B1B1F);

  @override
  Color get border => const Color(0xFF72777F);
  
  @override
  Color get error => const Color(0xFFB3261E);
  
  @override
  Color get onError => const Color(0xFFFFFFFF);

  // --- Custom ---
  @override
  Color get googleButton => const Color(0xFF4285F4);
  
  @override
  Color get onGoogleButton => const Color(0xFFFFFFFF);
  
  @override
  Color get lightGreyFill => const Color(0xFFE0E0E0);
}

/// Concrete implementation of [AppColors] for DARK mode.
class AppColorsDark implements AppColors {
  // Define your dark theme colors from Figma here
  // These are often inverted or desaturated versions of light colors.
  
  @override
  Color get primary => const Color(0xFFB0C6FF); // Example: A lighter blue

  @override
  Color get onPrimary => const Color(0xFF002A78);

  @override
  Color get background => const Color(0xFF1B1B1F);

  @override
  Color get onBackground => const Color(0xFFE3E2E6);

  @override
  Color get surface => const Color(0xFF1B1B1F); // Often same as background in dark mode

  @override
  Color get onSurface => const Color(0xFFE3E2E6);

  @override
  Color get border => const Color(0xFF8C9199);
  
  @override
  Color get error => const Color(0xFFF2B8B5);
  
  @override
  Color get onError => const Color(0xFF601410);

  // --- Custom ---
  @override
  Color get googleButton => const Color(0xFF4285F4); // Often stays the same
  
  @override
  Color get onGoogleButton => const Color(0xFFFFFFFF);
  
  @override
  Color get lightGreyFill => const Color(0xFF3A3A3A); // A dark grey
}