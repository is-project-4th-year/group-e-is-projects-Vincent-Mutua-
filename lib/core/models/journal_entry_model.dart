import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for a single journal entry document in Firestore.
class JournalEntryModel {
  final String? id;
  final String uid;
  final String content;
  final Timestamp? timestamp;
  
  // --- AI-Specific Fields ---
  
  /// Stores the AI-generated supportive response.
  final String? aiResponse;
  
  /// Stores a list of emotions detected by the AI (e.g., "Anxiety", "Overwhelm").
  final List<String> emotionTags;

  JournalEntryModel({
    this.id,
    required this.uid,
    required this.content,
    this.timestamp,
    this.aiResponse,
    this.emotionTags = const [],
  });

  /// Converts this [JournalEntryModel] to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'content': content,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'aiResponse': aiResponse,
      'emotionTags': emotionTags,
    };
  }

  /// Creates a [JournalEntryModel] from a Firestore document snapshot.
  factory JournalEntryModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JournalEntryModel(
      id: doc.id,
      uid: data['uid'] as String,
      content: data['content'] as String,
      timestamp: data['timestamp'] as Timestamp?,
      aiResponse: data['aiResponse'] as String?,
      // Convert the list of dynamic to a list of String
      emotionTags: List<String>.from(data['emotionTags'] ?? []),
    );
  }

  /// Creates a copy of this model with updated fields.
  JournalEntryModel copyWith({
    String? id,
    String? uid,
    String? content,
    Timestamp? timestamp,
    String? aiResponse,
    List<String>? emotionTags,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      aiResponse: aiResponse ?? this.aiResponse,
      emotionTags: emotionTags ?? this.emotionTags,
    );
  }
}