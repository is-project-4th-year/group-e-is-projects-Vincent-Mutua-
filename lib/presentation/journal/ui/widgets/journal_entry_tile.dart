import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
// We'll use this later for formatting the date
// import 'package:intl/intl.dart'; 

class JournalEntryTile extends ConsumerWidget {
  final JournalEntryModel entry;

  const JournalEntryTile({
    super.key,
    required this.entry,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '...';
    // Simple, fast formatting without a new package
    return timestamp.toDate().toLocal().toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(journalControllerProvider.notifier).deleteJournalEntry(entry);
      },
      background: Container(
        color: colors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.delete_outline, color: colors.onError),
      ),
      child: Card(
        // Uses the modern CardTheme from our app_theme.dart
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          onTap: () {
            // TODO: Navigate to a detailed view to read/edit the full entry
          },
          // --- Entry Content Snippet ---
          title: Text(
            entry.content,
            maxLines: 2, // Show a 2-line preview
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          
          // --- Entry Date ---
          subtitle: Text(
            _formatTimestamp(entry.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
          
          // --- AI Emotion Tag (for later) ---
          trailing: entry.emotionTags.isNotEmpty
            ? Icon(Icons.sentiment_satisfied, color: colors.primary)
            : const Icon(Icons.circle_outlined, size: 12),
        ),
      ),
    );
  }
}