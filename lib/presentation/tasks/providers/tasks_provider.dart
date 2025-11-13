import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/core/providers/firebase_providers.dart';

// --- 1. The Tasks Stream Provider ---
/// This is the primary provider your UI will watch.
///
// ignore: unintended_html_in_doc_comment
/// It provides a real-time stream (AsyncValue<List<TaskModel>>)
/// of the user's tasks, filtered by their UID.
/// It automatically re-runs when the user's auth state changes.
final tasksProvider = StreamProvider<List<TaskModel>>((ref) {
  // Get the current user
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]); // Return an empty stream if logged out
  }
  
  // Watch the repository's task stream
  final firestoreRepository = ref.watch(firestoreRepositoryProvider);
  return firestoreRepository.watchTasks(user.uid);
});


// --- 2. The Tasks Controller Provider ---
/// This is the "controller" your UI will call to perform actions.
///
/// We use an AsyncNotifier to manage asynchronous operations
/// (like adding/deleting) and handle loading/error states.
final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, void>(() {
  return TasksController();
});

/// The controller class itself
class TasksController extends AsyncNotifier<void> {
  // We don't need a "build" method as we're not returning a state
  @override
  Future<void> build() async {
    // This is required, but we won't use it
    return;
  }

  /// Adds a new task to Firestore.
  Future<void> addTask(String title) async {
    // Get the repository and user ID
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    // Set state to loading
    state = const AsyncValue.loading();

    // Create the new task model
    final newTask = TaskModel(
      uid: user.uid,
      title: title,
      // `createdAt` is set by the server (in the model)
    );

    // Call the repository
    state = await AsyncValue.guard(() {
      return firestoreRepository.addTask(newTask);
    });
  }

  /// Toggles the completion status of a task.
  Future<void> toggleTaskCompletion(TaskModel task) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    if (task.id == null) {
      throw Exception("Task has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return firestoreRepository.updateTask(task.id!, {
        'isCompleted': !task.isCompleted,
      });
    });
  }

  /// Deletes a task from Firestore.
  Future<void> deleteTask(TaskModel task) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    if (task.id == null) {
      throw Exception("Task has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return firestoreRepository.deleteTask(task.id!);
    });
  }
}