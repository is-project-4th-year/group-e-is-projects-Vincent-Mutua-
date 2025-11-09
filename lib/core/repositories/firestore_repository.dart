import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/user_model.dart';
import 'package:is_application/core/providers/firebase_providers.dart';

/// The "contract" for our Firestore repository.
abstract class FirestoreRepository {
  /// Creates a new user document in the 'users' collection.
  Future<void> createUserDocument(UserModel user);

  // --- Other methods you will add later ---
  // Future<void> addJournalEntry(String uid, JournalEntryModel entry);
  // Stream<List<TaskModel>> watchTasks(String uid);
}

// --- The Implementation ---

class FirestoreRepositoryImpl implements FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepositoryImpl(this._firestore);

  /// Reference to the 'USERS' collection in Firestore,
  /// based on your project's database schema.
  CollectionReference get _usersCollection => _firestore.collection('USERS');

  @override
  Future<void> createUserDocument(UserModel user) async {
    try {
      // Use .doc(user.uid) to set the document ID to match the auth UID
      // Use .set(user.toJson()) to write the user's data
      await _usersCollection.doc(user.uid).set(user.toJson());
    } on FirebaseException catch (e) {
      // Handle or re-throw specific Firestore exceptions
      throw Exception('Error creating user document: ${e.message}');
    }
  }
}

// --- The Provider for the Repository ---

/// This provider creates and exposes the FirestoreRepository
/// to the rest of the app.
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  // Watch the global firestoreProvider and pass it to our implementation
  final firestore = ref.watch(firestoreProvider);
  return FirestoreRepositoryImpl(firestore);
});