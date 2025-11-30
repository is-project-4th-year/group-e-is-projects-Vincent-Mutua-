import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/chat/data/chat_message_model.dart';
import 'package:is_application/presentation/chat/data/chat_service.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:intl/intl.dart';

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
  return ChatNotifier(chatService, ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final Ref _ref;

  ChatNotifier(this._chatService, this._ref) : super(ChatState());

  // NEW: Method to seed the chat with context without showing it as a user message immediately
  // or to send a hidden system prompt.
  Future<void> analyzeJournalEntry(String title, String content) async {
    // Clear previous chat or keep it? Let's keep it for now, or maybe clear it for a new context.
    // For now, we just append.
    
    final contextMessage = "I've just written a journal entry.\nTitle: $title\nContent: $content\n\nCan you give me some insights or support based on this?";
    
    // We add this as a user message so the user sees what they are asking
    await sendMessage(contextMessage);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      role: 'user',
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Check for local intents (Tiimo-like integration)
    final lowerText = text.toLowerCase();
    if (lowerText.contains('reminder') || lowerText.contains('task') || lowerText.contains('todo') || lowerText.contains('schedule')) {
      await _handleTaskIntent();
      return;
    }

    try {
      // Get response from API
      final responseText = await _chatService.sendMessage(text);

      // Add bot message
      final botMessage = ChatMessage(
        text: responseText,
        role: 'assistant',
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
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<void> _handleTaskIntent() async {
    try {
      // We need to read the stream's latest value. 
      // Since it's a stream, we might not have the value immediately if it's loading.
      // But usually, if the app is running, the stream has emitted.
      final tasksAsync = _ref.read(tasksProvider);
      
      final tasks = tasksAsync.value ?? [];
      
      String responseText;
      if (tasks.isEmpty) {
        responseText = "You don't have any tasks scheduled right now. Would you like to add one?";
      } else {
        final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
        if (incompleteTasks.isEmpty) {
          responseText = "You've completed all your tasks! Great job!";
        } else {
          final count = incompleteTasks.length;
          final taskList = incompleteTasks.take(5).map((t) {
            final time = t.reminderAt != null 
                ? " at ${DateFormat('h:mm a').format(t.reminderAt!.toDate())}" 
                : "";
            return "• ${t.title}$time";
          }).join("\n");
          
          responseText = "Here are your upcoming tasks ($count):\n\n$taskList";
          if (count > 5) {
            responseText += "\n\n...and ${count - 5} more.";
          }
        }
      }

      // Simulate a small delay for "thinking"
      await Future.delayed(const Duration(milliseconds: 800));

      final botMessage = ChatMessage(
        text: responseText,
        role: 'assistant',
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );

    } catch (e) {
       final errorMessage = ChatMessage(
        text: "I tried to check your tasks but something went wrong.",
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = ChatState();
  }
}
