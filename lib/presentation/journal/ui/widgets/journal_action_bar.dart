import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';

class JournalActionBar extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onPenTap;
  final VoidCallback onMicTap;
  final bool isListening; // NEW

  const JournalActionBar({
    super.key,
    required this.onClose,
    required this.onCameraTap, 
    required this.onPenTap, 
    required this.onMicTap,
    this.isListening = false, // Default to false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: journalColors.background, // Blends with page or slightly distinct
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: journalColors.ink.withValues(alpha: 0.05)),
        boxShadow: isListening 
            ? [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)] 
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close Button (The Colored Circle X)
          GestureDetector(
            onTap: onClose,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: journalColors.accent,
              child: Icon(Icons.close, color: journalColors.surface, size: 20),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Camera
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: journalColors.ink),
            onPressed: onCameraTap,
          ),
          
          const SizedBox(width: 10),

          // Pen (Edit)
          IconButton(
            icon: Icon(Icons.edit_outlined, color: journalColors.ink),
            onPressed: onPenTap,
          ),

          const SizedBox(width: 10),

          // Mic (Audio)
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none_outlined, 
              color: isListening ? Colors.red : journalColors.ink
            ),
            onPressed: onMicTap,
          ),
        ],
      ),
    );
  }
}
