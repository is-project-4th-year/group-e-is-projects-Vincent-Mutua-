import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  static const String ngrokUrl = 'https://cathern-disembodied-nondomestically.ngrok-free.dev';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$ngrokUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('response')) {
          return data['response'].toString();
        }
        return "I received a response, but it was empty.";
      } else {
        print('Server Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to connect to ngrok server.');
      }
    } catch (e) {
      print('Chat Error: $e');
      throw Exception('Failed to connect to AI.');
    }
  }
}
