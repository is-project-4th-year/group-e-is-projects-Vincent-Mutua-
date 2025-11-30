import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/chat/providers/chat_provider.dart';
import 'package:is_application/core/widgets/aurora_background.dart';
import 'package:is_application/presentation/chat/ui/widgets/typing_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _hasText = false;

  final List<String> _suggestions = [
    "Help me focus",
    "Plan my day",
    "I'm feeling overwhelmed",
    "Break down a task",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
          );
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    // With reverse: true, the list automatically updates at the bottom (index 0)
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final chatColors = appColors.chat;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent, // Transparent for Aurora
      extendBodyBehindAppBar: true, // Extend body behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: chatColors.inputBar.withValues(alpha: 0.5), // Semi-transparent
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: chatColors.botText),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Column(
          children: [
            Text(
              'My AI Companion',
              style: TextStyle(
                color: chatColors.botText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (chatState.isLoading)
              Text(
                'Thinking...',
                style: TextStyle(
                  color: chatColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: chatColors.inputBar.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline_rounded, size: 20, color: chatColors.botText),
            ),
            tooltip: "Clear Chat",
            onPressed: () {
              _showClearDialog(context, chatColors);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AuroraBackground(
        baseColor: chatColors.background,
        accentColor: chatColors.accent,
        child: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty 
                ? _buildEmptyState(chatColors)
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16.0, 
                      right: 16.0, 
                      bottom: 20.0,
                      top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, // Add padding for AppBar
                    ),
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Handle Loading Indicator at the bottom (Index 0 in reversed list)
                      if (chatState.isLoading) {
                        if (index == 0) return _buildLoadingIndicator(chatColors);
                        
                        // Adjust index for messages
                        final msgIndex = chatState.messages.length - index;
                        final message = chatState.messages[msgIndex];
                        final olderMessage = msgIndex > 0 ? chatState.messages[msgIndex - 1] : null;
                        return _buildMessageBubble(message, chatColors, olderMessage);
                      } 
                      
                      // Normal Message Handling
                      final msgIndex = chatState.messages.length - 1 - index;
                      final message = chatState.messages[msgIndex];
                      final olderMessage = msgIndex > 0 ? chatState.messages[msgIndex - 1] : null;
                      return _buildMessageBubble(message, chatColors, olderMessage);
                    },
                  ),
            ),
            _buildInputArea(chatColors),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatPalette chatColors) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: chatColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, size: 40, color: chatColors.accent),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              "How can I help you?",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: chatColors.botText,
              ),
            ).animate().fadeIn().slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              "I can help you plan, focus, or just chat.",
              style: TextStyle(
                fontSize: 14,
                color: chatColors.botText.withValues(alpha: 0.6),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) => _buildSuggestionChip(suggestion, chatColors)).toList(),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ChatPalette chatColors) {
    return ActionChip(
      label: Text(text),
      labelStyle: TextStyle(
        color: chatColors.botText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: chatColors.botBubble,
      elevation: 0,
      side: BorderSide(color: chatColors.botText.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () => _handleSubmitted(text),
    );
  }

  Widget _buildMessageBubble(dynamic message, ChatPalette chatColors, dynamic previousMessage) {
    final isUser = message.role == 'user';
    final showAvatar = !isUser && (previousMessage == null || previousMessage.role == 'user');
    
    return Padding(
      padding: EdgeInsets.only(top: showAvatar ? 16.0 : 4.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: chatColors.accent,
                child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser 
                    ? LinearGradient(
                        colors: [chatColors.accent, chatColors.accent.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : chatColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? chatColors.userText : chatColors.botText,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.1 : -0.1, end: 0);
  }

  Widget _buildLoadingIndicator(ChatPalette chatColors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 36.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: chatColors.botBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: TypingIndicator(color: chatColors.accent, size: 6),
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatPalette chatColors) {
    return Container(
      color: chatColors.background, // Ensure solid background behind input area
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: chatColors.background,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                chatColors.background.withValues(alpha: 0.0),
                chatColors.background,
              ],
              stops: const [0.0, 0.2],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: chatColors.inputBar,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: _isListening ? 'Listening...' : 'Type a message...',
                            hintStyle: TextStyle(color: chatColors.botText.withValues(alpha: 0.4)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            isDense: true,
                          ),
                          style: TextStyle(color: chatColors.botText, fontSize: 16),
                          onSubmitted: _handleSubmitted,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                          color: _isListening ? Colors.redAccent : chatColors.botText.withValues(alpha: 0.5),
                        ),
                        onPressed: _toggleListening,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _handleSubmitted(_textController.text),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: chatColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: chatColors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
                ),
              ).animate(target: _hasText ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, ChatPalette chatColors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: chatColors.botBubble,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Start New Chat?", style: TextStyle(color: chatColors.botText)),
        content: Text("This will clear the current conversation.", style: TextStyle(color: chatColors.botText.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: chatColors.accent)),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
