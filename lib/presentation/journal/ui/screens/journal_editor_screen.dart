import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      final content = _controller.text.trim();
      
      // Call the controller to save the entry
      await ref.read(journalControllerProvider.notifier).addJournalEntry(content);

      // Close the editor screen
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the controller's state for loading
    final journalState = ref.watch(journalControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Entry'),
        actions: [
          // Save Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: journalState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: _saveEntry,
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            maxLines: null, // Allows the field to expand
            expands: true, // Fills the entire screen
            decoration: const InputDecoration(
              hintText: 'Start writing your thoughts...',
              // Use a flat, borderless input for a clean editor
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Your entry cannot be empty.';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}