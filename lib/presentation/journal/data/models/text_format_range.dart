enum FormatType { bold, italic, underline, highlight }

class TextFormatRange {
  final int start;
  final int end;
  final FormatType type;

  const TextFormatRange({
    required this.start,
    required this.end,
    required this.type,
  });

  bool contains(int index) => index >= start && index < end;

  // --- SERIALIZATION LOGIC ---

  // Convert object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
      'type': type.name, // Save as string "bold", "highlight", etc.
    };
  }

  // Create object from Firestore Map
  factory TextFormatRange.fromMap(Map<String, dynamic> map) {
    return TextFormatRange(
      start: map['start'] as int,
      end: map['end'] as int,
      // Convert string back to Enum safely
      type: FormatType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FormatType.bold, // Fallback
      ),
    );
  }
}