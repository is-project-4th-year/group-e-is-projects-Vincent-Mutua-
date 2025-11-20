import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority {
  low,
  medium,
  high,
}

/// Represents a single sub-task within a main task.
class SubTask {
  final String title;
  final bool isCompleted;

  SubTask({
    required this.title,
    this.isCompleted = false,
  });

  /// Converts this [SubTask] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  /// Creates a [SubTask] from a JSON map.
  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

/// Model class for a single task document in Firestore.
class TaskModel {
  final String? id;
  final String uid;
  final String title;
  final bool isCompleted;
  final Timestamp? createdAt;
  final Timestamp? dueDate;
  final String? projectId;
  final String? category;
  final TaskPriority priority;
  final Timestamp? reminderAt;
  final int? notificationId;
  final List<SubTask> subTasks;

  TaskModel({
    this.id,
    required this.uid,
    required this.title,
    this.isCompleted = false,
    this.createdAt,
    this.dueDate,
    this.projectId,
    this.category,
    this.priority = TaskPriority.medium,
    this.reminderAt,
    this.notificationId,
    this.subTasks = const [],
  });

  /// Converts this [TaskModel] to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'title': title,
      'isCompleted': isCompleted,
      // Use serverTimestamp for reliable, non-local time
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'dueDate': dueDate,
      'projectId': projectId,
      'category': category,
      'priority': priority.index, // Store enum as int
      'reminderAt': reminderAt,
      'notificationId': notificationId,
      // Convert list of SubTask objects to a list of maps
      'subTasks': subTasks.map((subtask) => subtask.toJson()).toList(),
    };
  }

  /// Creates a [TaskModel] from a Firestore document snapshot.
  factory TaskModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle subTasks list conversion
    final subTasksList = (data['subTasks'] as List<dynamic>?)
        ?.map((item) => SubTask.fromJson(item as Map<String, dynamic>))
        .toList() ?? [];

    // Safe priority parsing
    TaskPriority priority = TaskPriority.medium;
    if (data['priority'] is int) {
      final index = data['priority'] as int;
      if (index >= 0 && index < TaskPriority.values.length) {
        priority = TaskPriority.values[index];
      }
    } else if (data['priority'] is String) {
      // Handle case where priority was stored as a String "0", "1", "2"
      final index = int.tryParse(data['priority'] as String);
      if (index != null && index >= 0 && index < TaskPriority.values.length) {
        priority = TaskPriority.values[index];
      }
    }

    return TaskModel(
      id: doc.id,
      uid: data['uid'] as String,
      title: data['title'] as String,
      isCompleted: data['isCompleted'] as bool,
      createdAt: data['createdAt'] as Timestamp?,
      dueDate: data['dueDate'] as Timestamp?,
      projectId: data['projectId'] as String?,
      category: data['category'] as String?,
      priority: priority,
      reminderAt: data['reminderAt'] as Timestamp?,
      notificationId: data['notificationId'] as int?,
      subTasks: subTasksList,
    );
  }

  /// Creates a copy of this model with updated fields.
  TaskModel copyWith({
    String? id,
    String? uid,
    String? title,
    bool? isCompleted,
    Timestamp? createdAt,
    Timestamp? dueDate,
    String? projectId,
    String? category,
    TaskPriority? priority,
    Timestamp? reminderAt,
    int? notificationId,
    List<SubTask>? subTasks,
  }) {
    return TaskModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      reminderAt: reminderAt ?? this.reminderAt,
      notificationId: notificationId ?? this.notificationId,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority, reminderAt: $reminderAt)';
  }
}