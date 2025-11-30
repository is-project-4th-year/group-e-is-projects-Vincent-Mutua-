import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';

class FeatureTile extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We'll use our theme colors
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));

    return Card(
      // Use the 'surface' color from your theme (or lightGreyFill)
      color: colors.surface,
      elevation: 0, // A modern, flat design
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 16.0,
        ),
        onTap: onTap, // The navigation action
        
        // The Icon on the left
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32.0,
            color: colors.primary, // Use your app's primary color
          ),
        ),
        
        // The Title
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
        ),
        
        // The Subtitle
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        
        // A trailing arrow to show it's tappable
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colors.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
