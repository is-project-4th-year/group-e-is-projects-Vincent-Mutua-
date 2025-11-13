import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 1. Import flutter_svg
import 'package:is_application/core/theme/app_colors.dart';

class SocialAuthButton extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final String iconPath; // 2. Add this parameter

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.iconPath, // 3. Make it required
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));

    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        // 4. Use SvgPicture.asset with the iconPath
        icon: SvgPicture.asset(
          iconPath,
          height: 24, // Set a standard size
          width: 24,
        ),
        label: Text(text),
        style: TextButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.onBackground,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}