import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';
import 'package:is_application/presentation/journal/ui/widgets/formatting_toolbar.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_action_bar.dart';
import 'package:is_application/presentation/journal/ui/widgets/journal_image_grid.dart';
import 'package:is_application/presentation/journal/data/models/text_format_range.dart'; // NEW
import 'package:is_application/presentation/journal/ui/controllers/journal_editing_controller.dart'; // NEW
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

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
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textBeforeListening = '';

  // Text to Speech
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    final state = ref.read(journalEditorProvider);
    _titleController = TextEditingController(text: state.title);
    
    // Initialize with current state and default colors (will be updated in build)
    // We use a temporary palette until build provides the theme-aware one
    _contentController = JournalEditingController(
      text: state.content,
      formattingRanges: state.formats,
      journalColors: const JournalPalette(
        background: Colors.white,
        surface: Colors.white,
        ink: Colors.black,
        accent: Colors.blue,
        canvas: Colors.grey,
      ),
    );
    
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    // CHANGE 2: Update controller instead of recreating it
    final editorState = ref.watch(journalEditorProvider);
    
    _contentController.update(
      newRanges: editorState.formats,
      newColors: journalColors,
      newText: editorState.content,
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
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 120), // Increased top padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        color: journalColors.ink.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24), // Increased spacing

                    // Header Row (Title + Actions)
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
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              hintText: "Title...",
                              hintStyle: TextStyle(
                                color: journalColors.ink.withValues(alpha: 0.3),
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                        // Actions Row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Read Aloud (TTS)
                            IconButton(
                              icon: Icon(Icons.volume_up_outlined, color: journalColors.ink.withValues(alpha: 0.6)),
                              onPressed: _readAloud,
                              tooltip: "Read Aloud",
                            ),
                            // Delete Button (Always visible if entry exists)
                            if (editorState.id != null)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red.withValues(alpha: 0.7)),
                                onPressed: () => _confirmDelete(context, editorState.id!),
                                tooltip: "Delete Entry",
                              ),
                            const SizedBox(width: 4),
                            // Save Button
                            IconButton(
                              icon: CircleAvatar(
                                backgroundColor: journalColors.accent.withValues(alpha: 0.1),
                                radius: 18,
                                child: Icon(Icons.check, color: journalColors.accent, size: 20),
                              ),
                              onPressed: () async {
                                await ref.read(journalControllerProvider.notifier).saveEntry();
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              tooltip: "Save",
                            ),
                            const SizedBox(width: 8),
                            // Minimize / Back Button
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: CircleAvatar(
                                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                radius: 18,
                                child: Icon(Icons.keyboard_arrow_down, color: journalColors.ink, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),

                    // Image Gallery (Updated Layout)
                    const JournalImageGrid(),

                    // The Main Body Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10), // Removed container padding/bg for cleaner look
                      decoration: const BoxDecoration(), // Removed box decoration for cleaner "paper" look
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        onChanged: (value) => ref
                            .read(journalEditorProvider.notifier)
                            .updateContent(value),
                        maxLines: null, // Expands infinitely
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: journalColors.ink.withValues(alpha: 0.85),
                              height: 1.8, // More breathing room
                              fontSize: 18,
                            ),
                        decoration: InputDecoration(
                          hintText: "Start writing...",
                          hintStyle: TextStyle(
                              color: journalColors.ink.withValues(alpha: 0.3),
                              fontStyle: FontStyle.normal),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
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
                  isListening: _isListening, // Pass state
                  onClose: () {
                    // Trigger Save and Close
                    ref.read(journalControllerProvider.notifier).saveEntry();
                    Navigator.of(context).pop();
                  },
                  onCameraTap: _showImagePickerOptions,
                  onPenTap: () {
                    // Toggle Draw Mode or just focus
                    _contentFocusNode.requestFocus();
                  },
                  onMicTap: _toggleListening, // Connect STT
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


  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery (Multiple)'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final pickedFiles = await picker.pickMultiImage();
        print("Picked files: ${pickedFiles.length}");
        if (pickedFiles.isNotEmpty) {
          ref.read(journalEditorProvider.notifier).addLocalImages(pickedFiles);
        }
      } else {
        final pickedFile = await picker.pickImage(source: source);
        print("Picked file: ${pickedFile?.path}");
        if (pickedFile != null) {
          ref.read(journalEditorProvider.notifier).addLocalImage(pickedFile);
        }
      }
    } catch (e) {
      print("Error picking images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _readAloud() async {
    await _flutterTts.speak("${_titleController.text}. ${_contentController.text}");
  }

  // Helper to bridge UI -> Provider
  void _applyFormat(FormatType type) {
    final selection = _contentController.selection;
    ref.read(journalEditorProvider.notifier).applyFormat(selection, type);
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      // Initialize Speech Service (Requests permission automatically)
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech Status: $status'); // Debug log
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          print('Speech Error: ${errorNotification.errorMsg}'); // Debug log
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorNotification.errorMsg}')),
          );
        },
        debugLogging: true, // Enable debug logging
      );

      if (available) {
        setState(() {
          _isListening = true;
          _textBeforeListening = _contentController.text; // Capture current text
        });
        
        _speech.listen(
          onResult: (result) {
            print("Speech Result: ${result.recognizedWords}"); // Debug log
            // Real-time update: Combine original text with current recognized words
            // We add a space if there was previous text
            final prefix = _textBeforeListening.isNotEmpty ? "$_textBeforeListening " : "";
            final newText = "$prefix${result.recognizedWords}";
            
            // Update Provider immediately to show results in real-time
            ref.read(journalEditorProvider.notifier).updateContent(newText);
          },
          listenFor: const Duration(minutes: 5), // Listen longer
          pauseFor: const Duration(seconds: 5), // Allow pauses
          listenOptions: stt.SpeechListenOptions(
            partialResults: true, // Enable real-time feedback
            cancelOnError: true,
            listenMode: stt.ListenMode.dictation, // Optimize for dictation
          ),
        );
      } else {
        print("Speech initialization failed");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available. Please enable microphone permissions in settings.')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }



  Future<void> _confirmDelete(BuildContext context, String entryId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref.read(journalControllerProvider.notifier).deleteEntry(entryId);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

