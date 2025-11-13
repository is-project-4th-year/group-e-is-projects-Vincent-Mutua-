import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_entry_tile.dart';

// We must define this new route
const String journalEditorRoute = '/journal-editor';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the provider to get the list of entries
    final entriesAsyncValue = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
      ),
      
      // 2. Add the FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new editor screen
          context.push(journalEditorRoute);
        },
        child: const Icon(Icons.add),
      ),
      
      // 3. Handle the loading/error/data states
      body: entriesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        
        error: (error, stack) => Center(
          child: Text('Error loading entries: $error'),
        ),
        
        data: (entries) {
          // If no entries, show a welcome message
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No journal entries yet.\nTap the + button to add your first one!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          // If there are entries, show them in a list
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return JournalEntryTile(entry: entry);
            },
          );
        },
      ),
    );
  }
}