import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_application/presentation/journal/data/models/text_format_range.dart'; // Import your new class

class JournalEntryModel {
  final String? id;
  final String uid;
  final String? title; // Made nullable just in case
  final String content;
  final DateTime createdAt;
  // NEW FIELD: Stores the formatting data
  final List<TextFormatRange> formatting; 

  JournalEntryModel({
    this.id,
    required this.uid,
    this.title,
    required this.content,
    required this.createdAt,
    this.formatting = const [], // Default to empty list
  });

  // --- FIRESTORE CONVERSION ---

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      // Convert List of Objects -> List of Maps
      'formatting': formatting.map((range) => range.toMap()).toList(),
    };
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return JournalEntryModel(
      id: documentId,
      uid: map['uid'] ?? '',
      title: map['title'],
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      // Convert List of Maps -> List of Objects
      formatting: (map['formatting'] as List<dynamic>?)
              ?.map((item) => TextFormatRange.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}