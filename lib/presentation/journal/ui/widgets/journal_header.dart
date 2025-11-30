import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';

class JournalHeader extends ConsumerWidget {
  const JournalHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    return SliverAppBar(
      backgroundColor: journalColors.background,
      floating: true,
      expandedHeight: 100,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          "Your Journal",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: journalColors.ink,
          ),
        ),
      ),
    );
  }
}
