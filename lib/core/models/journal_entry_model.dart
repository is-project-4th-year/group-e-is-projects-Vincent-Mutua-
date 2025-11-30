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
  // NEW FIELD: Stores image URLs
  final List<String> images;
  final String? mood;

  JournalEntryModel({
    this.id,
    required this.uid,
    this.title,
    required this.content,
    required this.createdAt,
    this.formatting = const [], // Default to empty list
    this.images = const [], // Default to empty list
    this.mood,
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
      'images': images,
      'mood': mood,
    };
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Robust Date Handling: Check 'createdAt', then 'timestamp', then fallback
    DateTime createdDate;
    try {
      if (map['createdAt'] != null) {
        createdDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['timestamp'] != null) {
        createdDate = (map['timestamp'] as Timestamp).toDate();
      } else {
        createdDate = DateTime.now();
      }
    } catch (e) {
      createdDate = DateTime.now();
    }

    return JournalEntryModel(
      id: documentId,
      uid: map['uid'] ?? '',
      title: map['title'],
      content: map['content'] ?? '',
      createdAt: createdDate,
      // Convert List of Maps -> List of Objects
      formatting: (map['formatting'] as List<dynamic>?)
              ?.map((item) => TextFormatRange.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      images: List<String>.from(map['images'] ?? []),
      mood: map['mood'],
    );
  }
}