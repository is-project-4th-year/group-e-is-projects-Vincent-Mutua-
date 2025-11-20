import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/chat/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    // Assuming you might want a specific palette for chat, but using tasks/journal palette is fine too.
    // Let's use the journal palette for a calm feel or tasks for productivity.
    // Or just use the base colors.
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: colors.surface,
        elevation: 0,
        foregroundColor: colors.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? colors.primary
                          : colors.surface,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? colors.onPrimary
                            : colors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: colors.primary),
            ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                        style: TextStyle(color: colors.onSurface),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: colors.primary),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
