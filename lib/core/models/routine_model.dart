import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineActivity {
  final String title;
  final int durationMinutes;
  final String? icon;
  final int? color;

  RoutineActivity({
    required this.title,
    required this.durationMinutes,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'durationMinutes': durationMinutes,
      'icon': icon,
      'color': color,
    };
  }

  factory RoutineActivity.fromMap(Map<String, dynamic> map) {
    return RoutineActivity(
      title: map['title'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      icon: map['icon'],
      color: map['color'],
    );
  }
}

class RoutineModel {
  final String? id;
  final String uid;
  final String title;
  final String? category;
  final String? icon;
  final int? color;
  final String? startTime; // Format: "HH:mm"
  final List<String> recurrence; // e.g., ["Mon", "Tue"] or ["Daily"]
  final List<RoutineActivity> activities;

  RoutineModel({
    this.id,
    required this.uid,
    required this.title,
    this.category,
    this.icon,
    this.color,
    this.startTime,
    this.recurrence = const [],
    this.activities = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'category': category,
      'icon': icon,
      'color': color,
      'startTime': startTime,
      'recurrence': recurrence,
      'activities': activities.map((e) => e.toMap()).toList(),
    };
  }

  factory RoutineModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoutineModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      category: data['category'],
      icon: data['icon'],
      color: data['color'],
      startTime: data['startTime'],
      recurrence: List<String>.from(data['recurrence'] ?? []),
      activities: (data['activities'] as List<dynamic>?)
              ?.map((e) => RoutineActivity.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  
  int get totalDuration => activities.fold(0, (sum, item) => sum + item.durationMinutes);
}
