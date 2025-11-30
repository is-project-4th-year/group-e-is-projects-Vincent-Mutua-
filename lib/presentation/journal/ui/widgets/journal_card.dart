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
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Journal?'),
              content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(journalControllerProvider.notifier).deleteEntry(entry.id!);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: journalColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: journalColors.ink.withValues(alpha: 0.05), // Softer border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: journalColors.ink.withValues(alpha: 0.03), // Softer shadow
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview (if any)
              if (entry.images.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image.network(
                      entry.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: journalColors.canvas,
                        child: Icon(Icons.broken_image, color: journalColors.ink.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Time + Mood)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: journalColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              color: journalColors.ink.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (entry.mood != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: journalColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: journalColors.ink.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              _getMoodEmoji(entry.mood),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 12),

                    // HERO TITLE
                    if (entry.id != null)
                      Hero(
                        tag: 'journal_title_${entry.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            (entry.title != null && entry.title!.isNotEmpty) 
                                ? entry.title! 
                                : "Untitled Entry",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: journalColors.ink,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      Text(
                        (entry.title != null && entry.title!.isNotEmpty) 
                            ? entry.title! 
                            : "Untitled Entry",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: journalColors.ink,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Content Snippet
                    Text(
                      entry.content,
                      style: TextStyle(
                        color: journalColors.ink.withValues(alpha: 0.6),
                        height: 1.5,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'Happy': return '😊';
      case 'Calm': return '😌';
      case 'Sad': return '😔';
      case 'Stressed': return '😫';
      case 'Energetic': return '⚡';
      case 'Tired': return '😴';
      default: return '';
    }
  }
}
