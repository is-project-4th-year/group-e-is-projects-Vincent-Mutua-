import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/providers/journal_provider.dart';

class FormattingToolbar extends ConsumerWidget {
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onHighlightTap;

  const FormattingToolbar({
    super.key,
    this.onBoldTap,
    this.onItalicTap,
    this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get the current theme brightness to load correct colors
    final brightness = Theme.of(context).brightness;
    final appColors = ref.watch(appColorsProvider(brightness));
    final journalColors = appColors.journal;

    // 2. Watch the editor state to see what is active (Bold? Italic?)
    final editorState = ref.watch(journalEditorProvider);
    // final notifier = ref.read(journalEditorProvider.notifier); // Removed direct dependency on notifier actions

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: journalColors.surface,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Typography Button (Static for now, or could open a submenu)
          _FormatButton(
            label: "Tt",
            isActive: false,
            onTap: () {
              // TODO: Implement font size picker
            },
            textColor: journalColors.ink,
            activeColor: journalColors.accent,
          ),
          
          const SizedBox(width: 8),
          
          // Bold Button
          _FormatButton(
            label: "B",
            isBold: true,
            isActive: editorState.isBoldActive,
            onTap: onBoldTap ?? () {},
            textColor: journalColors.ink,
            activeColor: journalColors.accent,
          ),

          const SizedBox(width: 8),

          // Italic Button (Currently Active in your screenshot)
          _FormatButton(
            label: "I",
            isItalic: true,
            isActive: editorState.isItalicActive,
            onTap: onItalicTap ?? () {},
            textColor: journalColors.ink,
            activeColor: journalColors.accent,
          ),

          const SizedBox(width: 8),

          // Highlight Button (Replaces Underline or added)
          _FormatButton(
            label: "H", // Using H for Highlight
            isActive: false, // TODO: Add isHighlightActive to state
            onTap: onHighlightTap ?? () {},
            textColor: journalColors.ink,
            activeColor: journalColors.accent,
            // isHighlight: true, // Need to add visual style for highlight
          ),
        ],
      ),
    );
  }
}

// A private helper widget for the individual buttons
class _FormatButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color textColor;
  final Color activeColor;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  const _FormatButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.textColor,
    required this.activeColor,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            fontFamily: 'Serif', // Matches the screenshot vibe
          ),
        ),
      ),
    );
  }
}