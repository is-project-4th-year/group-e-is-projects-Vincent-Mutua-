import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';

class JournalCard extends ConsumerWidget {
  final JournalEntryModel entry;
  final VoidCallback onTap;

  const JournalCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    // Date Formatting
    final timeStr = DateFormat('h:mm a').format(entry.createdAt);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // Call the controller to delete
        ref.read(journalControllerProvider.notifier).deleteEntry(entry.id!);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: appColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: appColors.onError),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: journalColors.surface,
            borderRadius: BorderRadius.circular(20),
            // Softer, more diffused shadow for a "floating" feel
            boxShadow: [
              BoxShadow(
                color: journalColors.ink.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Time + Decor)
              Row(
                children: [
                  Icon(Icons.access_time, 
                       size: 14, color: journalColors.ink.withOpacity(0.4)),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: journalColors.ink.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // HERO TITLE: This tag must match the one in the Screen
              Hero(
                tag: 'journal_title_${entry.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    (entry.title != null && entry.title!.isNotEmpty) 
                        ? entry.title! 
                        : "Untitled",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: journalColors.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Content Snippet
              Text(
                entry.content,
                style: TextStyle(
                  color: journalColors.ink.withOpacity(0.6),
                  height: 1.5,
                  fontSize: 15,
                  fontFamily: 'InclusiveSans', // Ensure body font is readable
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}