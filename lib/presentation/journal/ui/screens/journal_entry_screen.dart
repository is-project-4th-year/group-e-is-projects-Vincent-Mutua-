import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/widgets/formatting_toolbar.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_action_bar.dart';
import 'package:is_application/presentation/journal/data/models/text_format_range.dart'; // NEW
import 'package:is_application/presentation/journal/ui/controllers/journal_editing_controller.dart'; // NEW

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  // We use local controllers to manage cursor position and text input smoothly.
  // We sync changes to the provider via onChanged.
  late TextEditingController _titleController;
  late JournalEditingController _contentController; // CHANGE 1: Use Custom Controller
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(journalEditorProvider);
    _titleController = TextEditingController(text: state.title);
    // Content controller is initialized in build to react to theme/state changes
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    // CHANGE 2: Re-construct controller when Provider State changes
    final editorState = ref.watch(journalEditorProvider);
    
    _contentController = JournalEditingController(
      text: editorState.content,
      formattingRanges: editorState.formats,
      journalColors: journalColors,
    );
    
    // Maintain cursor position hack for MVP
    _contentController.selection = TextSelection.fromPosition(
       TextPosition(offset: editorState.content.length)
    );

    // Detect keyboard height to position the formatting toolbar
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: journalColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // -------------------------------------------------------
            // LAYER 1: The Scrollable Paper Content
            // -------------------------------------------------------
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120), // Bottom padding for bars
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Title + Minimize)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            onChanged: (value) => ref
                                .read(journalEditorProvider.notifier)
                                .updateTitle(value),
                            maxLines: null,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: journalColors.ink,
                                  height: 1.1,
                                ),
                            decoration: InputDecoration(
                              hintText: "Title your story...",
                              hintStyle: TextStyle(color: journalColors.ink.withOpacity(0.3)),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        // Minimize / Back Button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: CircleAvatar(
                            backgroundColor: journalColors.accent,
                            radius: 16,
                            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),

                    // The Main Body Input
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      onChanged: (value) => ref
                          .read(journalEditorProvider.notifier)
                          .updateContent(value),
                      maxLines: null, // Expands infinitely
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: journalColors.ink.withOpacity(0.85),
                            height: 1.6, // Comfortable reading height
                            fontSize: 18,
                          ),
                      decoration: InputDecoration(
                        hintText: "Keep your story unfolding. Just tap to continue!",
                        hintStyle: TextStyle(
                            color: journalColors.ink.withOpacity(0.3),
                            fontStyle: FontStyle.italic),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------------
            // LAYER 2: Floating Formatting Toolbar
            // -------------------------------------------------------
            // Only show this when the keyboard is up or user is focused on content
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              bottom: isKeyboardVisible 
                  ? keyboardHeight + 10 // Float just above keyboard
                  : -100, // Hide below screen if keyboard closed
              left: 0,
              right: 0,
              child: Center(
                child: FormattingToolbar(
                  onBoldTap: () => _applyFormat(FormatType.bold),
                  onItalicTap: () => _applyFormat(FormatType.italic),
                  onHighlightTap: () => _applyFormat(FormatType.highlight),
                ),
              ),
            ),

            // -------------------------------------------------------
            // LAYER 3: Bottom Action Bar
            // -------------------------------------------------------
            // Always pinned to the bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: JournalActionBar(
                  onClose: () {
                    // Trigger Save and Close
                    ref.read(journalControllerProvider.notifier).saveEntry();
                    Navigator.of(context).pop();
                  },
                  onCameraTap: () {
                    // TODO: Connect to Image Picker
                    print("Open Camera");
                  },
                  onPenTap: () {
                    // TODO: Toggle Draw Mode
                    _contentFocusNode.requestFocus();
                  },
                  onMicTap: () {
                    // TODO: Connect to Speech-to-Text
                    print("Start Recording");
                  },
                ),
              ),
            ),
            
            // Loading Indicator Overlay (if saving)
            if (ref.watch(journalControllerProvider).isLoading)
               Positioned.fill(
                 child: Container(
                   color: Colors.black12,
                   child: const Center(child: CircularProgressIndicator()),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // Helper to bridge UI -> Provider
  void _applyFormat(FormatType type) {
    final selection = _contentController.selection;
    ref.read(journalEditorProvider.notifier).applyFormat(selection, type);
  }
}