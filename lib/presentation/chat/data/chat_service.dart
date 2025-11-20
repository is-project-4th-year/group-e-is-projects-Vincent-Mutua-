import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  // TODO: Replace with your actual ngrok URL
  static const String _baseUrl = 'YOUR_NGROK_URL_HERE'; 

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'), // Adjust endpoint as needed
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from server';
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
