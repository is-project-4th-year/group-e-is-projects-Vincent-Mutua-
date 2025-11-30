import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/services/notification_service.dart';

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
  Future<void> addTask({
    required String title,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? reminderAt,
    String? category,
    List<SubTask> subTasks = const [],
    int? color,
    String? icon,
    int? durationMinutes,
    String? recurrenceRule,
  }) async {
    // Get the repository and user ID
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }

    // Set state to loading
    state = const AsyncValue.loading();

    // Call the repository
    state = await AsyncValue.guard(() async {
      // Create the new task model
      final newTask = TaskModel(
        uid: user.uid,
        title: title,
        priority: priority,
        dueDate: dueDate != null ? Timestamp.fromDate(dueDate) : null,
        startDate: startDate != null ? Timestamp.fromDate(startDate) : null,
        reminderAt: reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
        category: category,
        subTasks: subTasks,
        color: color,
        icon: icon,
        durationMinutes: durationMinutes,
        recurrenceRule: recurrenceRule,
        // `createdAt` is set by the server (in the model)
      );

      final taskId = await firestoreRepository.addTask(newTask);

      // Schedule notification if reminder is set
      if (reminderAt != null) {
        final notificationId = taskId.hashCode;
        await notificationService.scheduleNotification(
          id: notificationId,
          title: 'Task Reminder',
          body: title,
          scheduledDate: reminderAt,
        );

        // Update task with notification ID
        await firestoreRepository.updateTask(user.uid, taskId, {
          'notificationId': notificationId,
        });
      }
    });
  }

  /// Toggles the completion status of a task.
  Future<void> toggleTaskCompletion(TaskModel task) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    
    if (task.id == null) {
      throw Exception("Task has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newStatus = !task.isCompleted;
      await firestoreRepository.updateTask(task.uid, task.id!, {
        'isCompleted': newStatus,
        'completedAt': newStatus ? FieldValue.serverTimestamp() : null,
      });

      // Cancel notification if completed
      if (newStatus && task.notificationId != null) {
        await notificationService.cancelNotification(task.notificationId!);
      } 
      // Reschedule if uncompleted and has reminder
      else if (!newStatus && task.reminderAt != null && task.notificationId != null) {
         // Check if reminder is still in future
         if (task.reminderAt!.toDate().isAfter(DateTime.now())) {
            await notificationService.scheduleNotification(
              id: task.notificationId!,
              title: 'Task Reminder',
              body: task.title,
              scheduledDate: task.reminderAt!.toDate(),
            );
         }
      }
    });
  }

  /// Deletes a task from Firestore.
  Future<void> deleteTask(TaskModel task) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    if (task.id == null) {
      throw Exception("Task has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await firestoreRepository.deleteTask(task.uid, task.id!);
      
      if (task.notificationId != null) {
        await notificationService.cancelNotification(task.notificationId!);
      }
    });
  }

  /// Updates an existing task.
  Future<void> updateTask(TaskModel task) async {
    final firestoreRepository = ref.read(firestoreRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    if (task.id == null) {
      throw Exception("Task has no ID");
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // We convert the model to JSON, but we exclude fields that shouldn't be updated manually
      // like 'uid' or 'createdAt' if we wanted to be strict, but toJson is fine for now.
      await firestoreRepository.updateTask(task.uid, task.id!, task.toJson());

      // Handle Notification Logic
      if (task.isCompleted && task.notificationId != null) {
        await notificationService.cancelNotification(task.notificationId!);
      } else if (!task.isCompleted && task.reminderAt != null) {
        final notificationId = task.notificationId ?? task.id.hashCode;
        
        // Ensure ID is saved if it wasn't there
        if (task.notificationId == null) {
             await firestoreRepository.updateTask(task.uid, task.id!, {
                'notificationId': notificationId,
             });
        }

        await notificationService.scheduleNotification(
          id: notificationId,
          title: 'Task Reminder',
          body: task.title,
          scheduledDate: task.reminderAt!.toDate(),
        );
      } else if (task.reminderAt == null && task.notificationId != null) {
          await notificationService.cancelNotification(task.notificationId!);
      }
    });
  }

  /// Generates subtasks for a given task title using an external AI service.
  Future<List<SubTask>> generateSubtasks(String taskTitle) async {
   
    const String baseUrl = 'https://cathern-disembodied-nondomestically.ngrok-free.dev'; 
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/break_down_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "data": {
            "taskTitle": taskTitle
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subtaskStrings = List<String>.from(data['data']['subtasks']);
        
        // Convert strings to SubTask objects
        return subtaskStrings.map((title) => SubTask(
          id: DateTime.now().millisecondsSinceEpoch.toString() + title.hashCode.toString(),
          title: title,
          isCompleted: false,
        )).toList();
      } else {
        throw Exception('Failed to generate subtasks: ${response.statusCode}');
      }
    } catch (e) {
      print("AI Error: $e");
      // Fallback for demo/offline
      return [
        SubTask(id: '1', title: 'Start small (AI Offline)', isCompleted: false),
        SubTask(id: '2', title: 'Check connection', isCompleted: false),
      ];
    }
  }
}