import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';

class JournalDateHeader extends ConsumerWidget {
  final String dateText;

  const JournalDateHeader({super.key, required this.dateText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        dateText.toUpperCase(),
        style: TextStyle(
          color: journalColors.ink.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}
