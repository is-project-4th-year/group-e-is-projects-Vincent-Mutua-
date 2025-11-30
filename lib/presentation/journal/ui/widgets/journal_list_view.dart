import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/screens/journal_entry_screen.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_card.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_date_header.dart';

class JournalListView extends ConsumerWidget {
  final List<JournalEntryModel> entries;

  const JournalListView({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort entries by date (newest first)
    // Note: It's better to sort a copy or ensure the list is mutable if we sort in place, 
    // but here we assume we can sort the passed list or it's already sorted. 
    // To be safe, let's sort a copy.
    final sortedEntries = List<JournalEntryModel>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Group entries by Day
    final groupedEntries = _groupEntriesByDate(sortedEntries);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = groupedEntries[index];

            if (item is String) {
              // It's a Date Header
              return JournalDateHeader(dateText: item);
            } else if (item is JournalEntryModel) {
              // It's a Card
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: JournalCard(
                  entry: item,
                  onTap: () {
                    ref.read(journalEditorProvider.notifier).loadExistingEntry(item);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const JournalEntryScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0); // Slide from bottom
                          const end = Offset.zero;
                          const curve = Curves.easeOutQuart; // Elegant slow-down curve

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
          childCount: groupedEntries.length,
        ),
      ),
    );
  }

  // Helper to interleave Date Headers into the list
  List<dynamic> _groupEntriesByDate(List<JournalEntryModel> entries) {
    final List<dynamic> grouped = [];
    String? lastDate;

    for (var entry in entries) {
      final dateKey = _getDateKey(entry.createdAt);
      if (lastDate != dateKey) {
        grouped.add(dateKey);
        lastDate = dateKey;
      }
      grouped.add(entry);
    }
    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateCheck = DateTime(date.year, date.month, date.day);

    if (dateCheck == today) return "Today";
    if (dateCheck == yesterday) return "Yesterday";
    return DateFormat('MMMM d').format(date);
  }
}
