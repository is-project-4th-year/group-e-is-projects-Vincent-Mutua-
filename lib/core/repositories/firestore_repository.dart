import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/journal_entry_model.dart'; 
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/models/user_model.dart';
import 'package:is_application/presentation/chat/data/chat_message_model.dart';
import 'package:is_application/core/models/routine_model.dart';
import 'package:is_application/core/providers/firebase_providers.dart';

/// The "contract" for our Firestore repository.
abstract class FirestoreRepository {
  // --- User Methods ---
  Future<void> createUserDocument(UserModel user);

  // --- Task Methods ---
  Stream<List<TaskModel>> watchTasks(String uid);
  Future<String> addTask(TaskModel task);
  Future<void> updateTask(String uid, String taskId, Map<String, dynamic> data);
  Future<void> deleteTask(String uid, String taskId);
  
  // --- Journal Methods ---
  Stream<List<JournalEntryModel>> watchJournalEntries(String uid);
  Future<void> addJournalEntry(JournalEntryModel entry);
  Future<void> updateJournalEntry(String entryId, Map<String, dynamic> data);
  Future<void> deleteJournalEntry(String entryId);

  // --- Chat History Methods ---
  Future<void> saveChatMessage(String uid, ChatMessage message);
  Stream<List<ChatMessage>> watchChatMessages(String uid);

  // --- Routine Methods ---
  Stream<List<RoutineModel>> watchRoutines(String uid);
  Future<void> addRoutine(RoutineModel routine);
  Future<void> updateRoutine(String uid, String routineId, RoutineModel routine);
  Future<void> deleteRoutine(String uid, String routineId);
}

// --- The Implementation ---

class FirestoreRepositoryImpl implements FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepositoryImpl(this._firestore);

  /// Reference to the 'users' collection in Firestore.
  CollectionReference get _usersCollection => _firestore.collection('users');

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
      return _usersCollection
          .doc(uid)
          .collection('tasks')
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
      final docRef = await _usersCollection
          .doc(task.uid)
          .collection('tasks')
          .add(task.toJson());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Error adding task: ${e.message}');
    }
  }

  @override
  Future<void> updateTask(String uid, String taskId, Map<String, dynamic> data) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .update(data);
    } on FirebaseException catch (e) {
      throw Exception('Error updating task: ${e.message}');
    }
  }

  @override
  Future<void> deleteTask(String uid, String taskId) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting task: ${e.message}');
    }
  }

  // --- Journal Method Implementations ---

  @override
  Stream<List<JournalEntryModel>> watchJournalEntries(String uid) {
    try {
      return _usersCollection
          .doc(uid)
          .collection('journal') // Renamed from journal_entries
          .snapshots()
          .map((snapshot) {
        final entries = snapshot.docs.map((doc) {
          final data = doc.data();
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
      await _usersCollection
          .doc(entry.uid)
          .collection('journal') // Renamed from journal_entries
          .add(entry.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error adding journal entry: ${e.message}');
    }
  }

  @override
  Future<void> updateJournalEntry(String entryId, Map<String, dynamic> data) async {
    try {
      final query = await _firestore.collectionGroup('journal').where(FieldPath.documentId, isEqualTo: entryId).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(data);
      } else {
        throw Exception('Journal entry not found');
      }
    } on FirebaseException catch (e) {
      throw Exception('Error updating journal entry: ${e.message}');
    }
  }

  @override
  Future<void> deleteJournalEntry(String entryId) async {
    try {
      final query = await _firestore.collectionGroup('journal').where(FieldPath.documentId, isEqualTo: entryId).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      } else {
        throw Exception('Journal entry not found');
      }
    } on FirebaseException catch (e) {
      throw Exception('Error deleting journal entry: ${e.message}');
    }
  }

  // --- Chat History Method Implementations ---

  @override
  Future<void> saveChatMessage(String uid, ChatMessage message) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('chats') // Renamed from chat_history
          .add(message.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error saving chat message: ${e.message}');
    }
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String uid) {
    try {
      return _usersCollection
          .doc(uid)
          .collection('chats') // Renamed from chat_history
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching chat messages: ${e.message}');
    }
  }

  // --- Routine Method Implementations ---

  @override
  Stream<List<RoutineModel>> watchRoutines(String uid) {
    try {
      return _usersCollection
          .doc(uid)
          .collection('routines')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => RoutineModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw Exception('Error watching routines: ${e.message}');
    }
  }

  @override
  Future<void> addRoutine(RoutineModel routine) async {
    try {
      await _usersCollection
          .doc(routine.uid)
          .collection('routines')
          .add(routine.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error adding routine: ${e.message}');
    }
  }

  @override
  Future<void> updateRoutine(String uid, String routineId, RoutineModel routine) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('routines')
          .doc(routineId)
          .update(routine.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Error updating routine: ${e.message}');
    }
  }

  @override
  Future<void> deleteRoutine(String uid, String routineId) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('routines')
          .doc(routineId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Error deleting routine: ${e.message}');
    }
  }
}

// --- The Provider for the Repository ---

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreRepositoryImpl(firestore);
});