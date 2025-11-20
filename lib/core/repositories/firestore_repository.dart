import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/journal_entry_model.dart'; 
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/models/user_model.dart';
import 'package:is_application/core/providers/firebase_providers.dart';

/// The "contract" for our Firestore repository.
abstract class FirestoreRepository {
  // --- User Methods ---
  Future<void> createUserDocument(UserModel user);

  // --- Task Methods ---
  Stream<List<TaskModel>> watchTasks(String uid);
  Future<String> addTask(TaskModel task);
  Future<void> updateTask(String taskId, Map<String, dynamic> data);
  Future<void> deleteTask(String taskId);
  
  // --- Journal Methods ---
  Stream<List<JournalEntryModel>> watchJournalEntries(String uid);
  Future<void> addJournalEntry(JournalEntryModel entry);
  Future<void> updateJournalEntry(String entryId, Map<String, dynamic> data);
  Future<void> deleteJournalEntry(String entryId);
}

// --- The Implementation ---

class FirestoreRepositoryImpl implements FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepositoryImpl(this._firestore);

  /// Reference to the 'USERS' collection in Firestore.
  CollectionReference get _usersCollection => _firestore.collection('USERS');

  /// Reference to the 'TASKS' collection in Firestore.
  CollectionReference get _tasksCollection => _firestore.collection('TASKS');

  /// Reference to the 'JOURNAL' collection in Firestore.
  CollectionReference get _journalCollection => _firestore.collection('JOURNAL');

  // --- User Method Implementation ---
  @override
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Error creating user document: ${e.message}');
    }
  }

  // --- Task Method Implementations ---

  @override
  Stream<List<TaskModel>> watchTasks(String uid) {
    try {
      return _tasksCollection
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TaskModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching tasks: ${e.message}');
    }
  }

  @override
  Future<String> addTask(TaskModel task) async {
    try {
      final docRef = await _tasksCollection.add(task.toJson());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Error adding task: ${e.message}');
    }
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      await _tasksCollection.doc(taskId).update(data);
    } on FirebaseException catch (e) {
      throw Exception('Error updating task: ${e.message}');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting task: ${e.message}');
    }
  }

  // --- 4. NEW: Journal Method Implementations (FIXED) ---

  @override
  Stream<List<JournalEntryModel>> watchJournalEntries(String uid) {
    try {
      return _journalCollection
          .where('uid', isEqualTo: uid)
          // NOTE: We sort in memory to avoid needing a composite index on (uid, createdAt)
          // .orderBy('createdAt', descending: true) 
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return JournalEntryModel.fromMap(data, doc.id);
        }).toList();

        // Sort by Date (Newest First)
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return entries;
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching journal entries: ${e.message}');
    }
  }

  @override
  Future<void> addJournalEntry(JournalEntryModel entry) async {
    try {
      // FIXED: Changed .toJson() to .toMap()
      await _journalCollection.add(entry.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error adding journal entry: ${e.message}');
    }
  }

  @override
  Future<void> updateJournalEntry(String entryId, Map<String, dynamic> data) async {
    try {
      await _journalCollection.doc(entryId).update(data);
    } on FirebaseException catch (e) {
      throw Exception('Error updating journal entry: ${e.message}');
    }
  }

  @override
  Future<void> deleteJournalEntry(String entryId) async {
    try {
      await _journalCollection.doc(entryId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting journal entry: ${e.message}');
    }
  }
}

// --- The Provider for the Repository ---

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreRepositoryImpl(firestore);
});