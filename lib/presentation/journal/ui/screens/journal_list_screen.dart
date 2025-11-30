import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/core/widgets/aurora_background.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/screens/journal_entry_screen.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_empty_state.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_header.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_list_view.dart';

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
      body: AuroraBackground(
        baseColor: appColors.background,
        accentColor: journalColors.accent,
        child: CustomScrollView(
          slivers: [
            // 1. Elegant Sliver App Bar
            const JournalHeader(),

            // 2. The Content
            journalAsyncValue.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const JournalEmptyState();
                }

                return JournalListView(entries: entries);
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text("Error: $err"))),
            ),
          ],
        ),
      ),
      
      // 3. Floating Action Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140), // Raise above custom nav bar
        child: FloatingActionButton(
          heroTag: 'journal_fab',
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
      ),
    );
  }
}