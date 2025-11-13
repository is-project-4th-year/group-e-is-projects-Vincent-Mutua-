import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/journal_entry_model.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';

// --- 1. The Journal Entries Stream Provider ---
/// This is the primary provider your UI will watch.
///
// ignore: unintended_html_in_doc_comment
/// It provides a real-time stream (AsyncValue<List<JournalEntryModel>>)
/// of the user's journal entries, filtered by their UID.
final journalEntriesProvider = StreamProvider<List<JournalEntryModel>>((ref) {
  // Get the current user
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]); // Return an empty stream if logged out
  }
  
  // Watch the repository's journal stream
  final firestoreRepository = ref.watch(firestoreRepositoryProvider);
  return firestoreRepository.watchJournalEntries(user.uid);
});

// --- 2. The Journal Controller Provider ---
/// This is the "controller" your UI will call to perform actions.
///
/// We use an AsyncNotifier to manage asynchronous operations
/// (like adding/deleting) and handle loading/error states.
final journalControllerProvider =
    AsyncNotifierProvider<JournalController, void>(() {
  return JournalController();
});

/// The controller class itself
class JournalController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state needed
  }

  /// Adds a new journal entry to Firestore.
  /// (This is where we'll trigger the AI logic later).
  Future<void> addJournalEntry(String content) async {
    // Get the repository and user ID
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    // Set state to loading
    state = const AsyncValue.loading();

    // Create the new entry model
    final newEntry = JournalEntryModel(
      uid: user.uid,
      content: content,
      // `timestamp` is set by the server (in the model)
    );

    // Call the repository
    state = await AsyncValue.guard(() {
      return firestoreRepository.addJournalEntry(newEntry);
      
      // TODO (when we work back):
      // After awaiting the add, trigger a cloud function
      // to process newEntry.id for AI analysis.
    });
  }

  /// Deletes a journal entry from Firestore.
  Future<void> deleteJournalEntry(JournalEntryModel entry) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    if (entry.id == null) {
      throw Exception("Entry has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return firestoreRepository.deleteJournalEntry(entry.id!);
    });
  }
}