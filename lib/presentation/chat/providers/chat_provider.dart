import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/chat/data/chat_message_model.dart';
import 'package:is_application/presentation/chat/data/chat_service.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatNotifier(this._chatService) : super(ChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      // Get response from API
      final responseText = await _chatService.sendMessage(text);

      // Add bot message
      final botMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
    } catch (e) {
      // Handle error
      final errorMessage = ChatMessage(
        text: "Error: Could not connect to the bot. Please check your connection.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }
}
