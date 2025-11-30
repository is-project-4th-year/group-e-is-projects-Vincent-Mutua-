import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/ui/screens/task_detail_screen.dart';

class TimelineTaskCard extends ConsumerWidget {
  final TaskModel task;
  final bool isFirst;
  final bool isLast;

  const TimelineTaskCard({
    super.key,
    required this.task,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    // Determine Start Time
    // Use startDate if available, otherwise createdAt, otherwise now
    final startTime = task.startDate?.toDate() ?? task.createdAt?.toDate() ?? DateTime.now();
    final duration = task.durationMinutes ?? 30;
    final endTime = startTime.add(Duration(minutes: duration));

    final timeFormat = DateFormat('HH:mm');
    final startStr = timeFormat.format(startTime);
    final endStr = timeFormat.format(endTime);

    final baseColor = task.color != null ? Color(task.color!) : tasksPalette.accent;
    
    // Tiimo Style: Solid colorful blocks
    // We need to ensure text is readable. 
    // Simple check: if color is very light, use dark text, else white.
    final isLight = baseColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    return Opacity(
      opacity: task.isCompleted ? 0.5 : 1.0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Left Side: Time & Line ---
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    startStr,
                    style: TextStyle(
                      color: tasksPalette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : tasksPalette.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),

            // --- Right Side: The Card ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // Reduced bottom padding for tighter timeline
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: baseColor, // Solid color
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Icon Circle (White background for contrast)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              TaskConstants.getIcon(task.icon),
                              color: textColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    // decoration: task.isCompleted ? TextDecoration.lineThrough : null, // Removed as requested
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: subTextColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$duration min',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Checkbox (if needed) or Status
                          if (task.isCompleted)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, color: baseColor, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
