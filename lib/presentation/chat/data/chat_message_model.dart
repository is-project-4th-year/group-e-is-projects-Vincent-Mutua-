import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String role; // Changed from isUser (bool) to role (String: 'user', 'assistant')
  final DateTime timestamp;

  ChatMessage({
    this.id = '',
    required this.text,
    required this.role,
    required this.timestamp,
  });

  // Helper getter for backward compatibility
  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'role': role,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    // Migration logic: if role exists, use it. If isUser exists, convert it.
    String role = 'user';
    if (map.containsKey('role')) {
      role = map['role'] as String;
    } else if (map.containsKey('isUser')) {
      role = (map['isUser'] as bool) ? 'user' : 'assistant';
    }

    return ChatMessage(
      id: documentId,
      text: map['text'] ?? '',
      role: role,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
