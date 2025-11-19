import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:is_application/presentation/journal/data/models/text_format_range.dart';


final journalListProvider = StreamProvider.autoDispose<List<JournalEntryModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]); 
  
  final repository = ref.watch(firestoreRepositoryProvider);
  return repository.watchJournalEntries(user.uid);
});


class JournalEditorState {
  final String title;
  final String content;
  final List<TextFormatRange> formats; // Stored formatting
  
  // Active Toggles (for the UI buttons)
  final bool isBoldActive;
  final bool isItalicActive;
  final bool isUnderlineActive;

  const JournalEditorState({
    this.title = '',
    this.content = '',
    this.formats = const [],
    this.isBoldActive = false,
    this.isItalicActive = false,
    this.isUnderlineActive = false,
  });

  JournalEditorState copyWith({
    String? title,
    String? content,
    List<TextFormatRange>? formats,
    bool? isBoldActive,
    bool? isItalicActive,
    bool? isUnderlineActive,
  }) {
    return JournalEditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      formats: formats ?? this.formats,
      isBoldActive: isBoldActive ?? this.isBoldActive,
      isItalicActive: isItalicActive ?? this.isItalicActive,
      isUnderlineActive: isUnderlineActive ?? this.isUnderlineActive,
    );
  }
}

class JournalEditorNotifier extends AutoDisposeNotifier<JournalEditorState> {
  @override
  JournalEditorState build() {
    return const JournalEditorState();
  }

  void updateTitle(String newTitle) => state = state.copyWith(title: newTitle);
  void updateContent(String newContent) => state = state.copyWith(content: newContent);

  // --- THE CORE FORMATTING LOGIC ---
  
  /// Applies a format to the currently selected text range
  void applyFormat(TextSelection selection, FormatType type) {
    if (!selection.isValid || selection.isCollapsed) {
      // If nothing selected, just toggle the button state for future typing
      _toggleButtonState(type);
      return;
    }

    // Create a new range based on selection
    final newRange = TextFormatRange(
      start: selection.start,
      end: selection.end,
      type: type,
    );

    // Add to list (In a real app, you'd merge overlapping ranges here)
    final updatedFormats = [...state.formats, newRange];
    
    state = state.copyWith(formats: updatedFormats);
  }

  void _toggleButtonState(FormatType type) {
    switch (type) {
      case FormatType.bold: state = state.copyWith(isBoldActive: !state.isBoldActive); break;
      case FormatType.italic: state = state.copyWith(isItalicActive: !state.isItalicActive); break;
      case FormatType.underline: state = state.copyWith(isUnderlineActive: !state.isUnderlineActive); break;
      default: break;
    }
  }

  /// Call this when opening an existing entry to edit
  void loadExistingEntry(JournalEntryModel entry) {
    state = JournalEditorState(
      title: entry.title ?? '',
      content: entry.content,
      formats: entry.formatting, // Load the saved highlights/bolds
    );
  }
  
  void reset() => state = const JournalEditorState();
}

final journalEditorProvider = 
    NotifierProvider.autoDispose<JournalEditorNotifier, JournalEditorState>(
  () => JournalEditorNotifier(),
);

final journalControllerProvider = AsyncNotifierProvider<JournalController, void>(() {
  return JournalController();
});

class JournalController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial async work needed
  }

  Future<void> saveEntry() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not logged in");

    final editorState = ref.read(journalEditorProvider);
    
    if (editorState.content.isEmpty && editorState.title.isEmpty) return;

    state = const AsyncValue.loading();

    final repository = ref.read(firestoreRepositoryProvider);
    
    final newEntry = JournalEntryModel(
      uid: user.uid,
      title: editorState.title,
      content: editorState.content,
      createdAt: DateTime.now(),
      // HERE IS THE MAGIC:
      // We pass the formatting ranges from the UI state to the Model
      formatting: editorState.formats, 
    );

    state = await AsyncValue.guard(() async {
      await repository.addJournalEntry(newEntry);
      ref.read(journalEditorProvider.notifier).reset();
    });
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncValue.loading();
    final repository = ref.read(firestoreRepositoryProvider);
    state = await AsyncValue.guard(() => repository.deleteJournalEntry(entryId));
  }
}