import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final String? id; // Track the ID for updates
  final String title;
  final String content;
  final List<TextFormatRange> formats; // Stored formatting
  final List<String> imageUrls; // URLs from Firestore
  final List<XFile> localImages; // Newly picked images
  
  // Active Toggles (for the UI buttons)
  final bool isBoldActive;
  final bool isItalicActive;
  final bool isUnderlineActive;

  const JournalEditorState({
    this.id,
    this.title = '',
    this.content = '',
    this.formats = const [],
    this.imageUrls = const [],
    this.localImages = const [],
    this.isBoldActive = false,
    this.isItalicActive = false,
    this.isUnderlineActive = false,
  });

  JournalEditorState copyWith({
    String? id,
    String? title,
    String? content,
    List<TextFormatRange>? formats,
    List<String>? imageUrls,
    List<XFile>? localImages,
    bool? isBoldActive,
    bool? isItalicActive,
    bool? isUnderlineActive,
  }) {
    return JournalEditorState(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      formats: formats ?? this.formats,
      imageUrls: imageUrls ?? this.imageUrls,
      localImages: localImages ?? this.localImages,
      isBoldActive: isBoldActive ?? this.isBoldActive,
      isItalicActive: isItalicActive ?? this.isItalicActive,
      isUnderlineActive: isUnderlineActive ?? this.isUnderlineActive,
    );
  }
}

class JournalEditorNotifier extends Notifier<JournalEditorState> {
  @override
  JournalEditorState build() {
    return const JournalEditorState();
  }

  void updateTitle(String newTitle) => state = state.copyWith(title: newTitle);
  void updateContent(String newContent) => state = state.copyWith(content: newContent);

  void addLocalImage(XFile image) {
    state = state.copyWith(localImages: [...state.localImages, image]);
  }

  void addLocalImages(List<XFile> images) {
    state = state.copyWith(localImages: [...state.localImages, ...images]);
  }

  void removeLocalImage(XFile image) {
    state = state.copyWith(localImages: state.localImages.where((i) => i != image).toList());
  }

  void removeImageUrl(String url) {
    state = state.copyWith(imageUrls: state.imageUrls.where((u) => u != url).toList());
  }

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
      id: entry.id, // Capture the ID
      title: entry.title ?? '',
      content: entry.content,
      formats: entry.formatting, // Load the saved highlights/bolds
      imageUrls: entry.images,
    );
  }
  
  void reset() => state = const JournalEditorState();
}

final journalEditorProvider = 
    NotifierProvider<JournalEditorNotifier, JournalEditorState>(
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
    
    if (editorState.content.isEmpty && editorState.title.isEmpty && editorState.localImages.isEmpty && editorState.imageUrls.isEmpty) return;

    state = const AsyncValue.loading();

    final repository = ref.read(firestoreRepositoryProvider);
    
    // Upload Images
    final storage = FirebaseStorage.instance;
    final List<String> uploadedUrls = [...editorState.imageUrls];

    try {
      for (var image in editorState.localImages) {
        final ref = storage.ref().child('journal_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
        print("Uploading image: ${image.path}"); // Debug log
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        print("Uploaded URL: $url"); // Debug log
        uploadedUrls.add(url);
      }
    } catch (e) {
      // Handle upload error (maybe show snackbar?)
      print("Error uploading images: $e");
      // Proceed with saving text even if images fail? Or throw?
      // For now, we'll proceed but maybe without the failed images.
    }

    // Check if we are updating or creating
    if (editorState.id != null) {
      // UPDATE EXISTING
      final updateData = {
        'title': editorState.title,
        'content': editorState.content,
        'formatting': editorState.formats.map((e) => e.toMap()).toList(),
        'images': uploadedUrls,
        // We don't update createdAt usually, or we might update 'updatedAt'
      };
      
      state = await AsyncValue.guard(() async {
        await repository.updateJournalEntry(editorState.id!, updateData);
        ref.read(journalEditorProvider.notifier).reset();
      });
    } else {
      // CREATE NEW
      final newEntry = JournalEntryModel(
        uid: user.uid,
        title: editorState.title,
        content: editorState.content,
        createdAt: DateTime.now(),
        formatting: editorState.formats, 
        images: uploadedUrls,
      );

      state = await AsyncValue.guard(() async {
        await repository.addJournalEntry(newEntry);
        ref.read(journalEditorProvider.notifier).reset();
      });
    }
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncValue.loading();
    final repository = ref.read(firestoreRepositoryProvider);
    state = await AsyncValue.guard(() => repository.deleteJournalEntry(entryId));
  }
}