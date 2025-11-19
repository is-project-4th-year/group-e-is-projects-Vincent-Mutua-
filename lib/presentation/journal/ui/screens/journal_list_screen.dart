import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/screens/journal_entry_screen.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_card.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    final journalAsyncValue = ref.watch(journalListProvider);

    return Scaffold(
      backgroundColor: journalColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Elegant Sliver App Bar
          SliverAppBar(
            backgroundColor: journalColors.background,
            floating: true,
            expandedHeight: 100,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                "Your Journal",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: journalColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: journalColors.surface,
                  child: Icon(Icons.search, color: journalColors.ink, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
            ],
          ),

          // 2. The Content
          journalAsyncValue.when(
            data: (entries) {
              if (entries.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.create, size: 48, color: journalColors.accent),
                        const SizedBox(height: 16),
                        Text("Start writing your story.", style: TextStyle(color: journalColors.ink.withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              }

              // Sort entries by date (newest first)
              entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              // Group entries by Day
              final groupedEntries = _groupEntriesByDate(entries);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = groupedEntries[index];
                      
                      if (item is String) {
                        // It's a Date Header
                        return Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Text(
                            item.toUpperCase(),
                            style: TextStyle(
                              color: journalColors.ink.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        );
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
                                  pageBuilder: (context, animation, secondaryAnimation) => const JournalEntryScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(0.0, 1.0); // Slide from bottom
                                    const end = Offset.zero;
                                    const curve = Curves.easeOutQuart; // Elegant slow-down curve

                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

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
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text("Error: $err"))),
          ),
        ],
      ),
      
      // 3. Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: journalColors.ink,
        child: Icon(Icons.edit_outlined, color: journalColors.surface),
        onPressed: () {
          ref.read(journalEditorProvider.notifier).reset();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const JournalEntryScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0); // Slide from bottom
                const end = Offset.zero;
                const curve = Curves.easeOutQuart; // Elegant slow-down curve

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

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