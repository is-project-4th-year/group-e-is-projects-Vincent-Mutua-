import 'package:flutter/material.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/journal/data/models/text_format_range.dart';

class JournalEditingController extends TextEditingController {
  // The list of styles (Bold ranges, Italic ranges, etc.)
  List<TextFormatRange> formattingRanges;
  JournalPalette journalColors;

  JournalEditingController({
    required String text,
    required this.formattingRanges,
    required this.journalColors,
  }) : super(text: text);

  void update({
    required List<TextFormatRange> newRanges,
    required JournalPalette newColors,
    String? newText,
  }) {
    formattingRanges = newRanges;
    journalColors = newColors;
    if (newText != null && newText != text) {
      // Only update text if it changed externally (e.g. voice input)
      // We need to be careful not to mess up selection if we are typing
      // But if text changed, we usually want to update it.
      // For voice input (append), we want to keep selection or move it to end?
      // If we are typing, newText should match text (because we updated provider from text).
      
      // If the text is different, it means it came from outside (Voice or Load).
      // We update the value.
      text = newText;
      // Move cursor to end for external updates (like voice)
      selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    }
    notifyListeners(); // Trigger rebuild of the text span
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // If no formatting, return standard text
    if (formattingRanges.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final List<TextSpan> children = [];
    
    // iterate through every character in the text
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      // Check which styles apply to this specific character
      bool isBold = false;
      bool isItalic = false;
      bool isUnderline = false;
      bool isHighlight = false;

      for (final range in formattingRanges) {
        if (range.contains(i)) {
          switch (range.type) {
            case FormatType.bold: isBold = true; break;
            case FormatType.italic: isItalic = true; break;
            case FormatType.underline: isUnderline = true; break;
            case FormatType.highlight: isHighlight = true; break;
          }
        }
      }

      // Construct the style for this specific character
      // Note: In a production app, you would optimize this to group characters
      // rather than creating a span per character, but this is optimal for
      // "Fast Implementation" and accurate rendering.
      children.add(TextSpan(
        text: char,
        style: style?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          // THE ORANGE HIGHLIGHT LOGIC:
          backgroundColor: isHighlight ? journalColors.accent : Colors.transparent,
        ),
      ));
    }

    return TextSpan(style: style, children: children);
  }
}