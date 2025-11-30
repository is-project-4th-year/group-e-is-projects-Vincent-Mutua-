import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';

class JournalEmptyState extends ConsumerWidget {
  const JournalEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: journalColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: journalColors.ink.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.auto_stories_outlined, size: 48, color: journalColors.accent),
            ),
            const SizedBox(height: 24),
            Text(
              "Your Story Begins Here",
              style: TextStyle(
                color: journalColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the + button to write your first entry.",
              style: TextStyle(color: journalColors.ink.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
