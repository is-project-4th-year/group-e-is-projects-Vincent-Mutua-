import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/routine_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/ui/widgets/create_routine_modal.dart';

class TimelineRoutineCard extends ConsumerWidget {
  final RoutineModel routine;
  final bool isFirst;
  final bool isLast;

  const TimelineRoutineCard({
    super.key,
    required this.routine,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    // Parse Start Time
    DateTime startTime = DateTime.now();
    if (routine.startTime != null) {
      final parts = routine.startTime!.split(":");
      final now = DateTime.now();
      startTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    }
    
    final duration = routine.totalDuration;
    final endTime = startTime.add(Duration(minutes: duration));

    final timeFormat = DateFormat('HH:mm');
    final startStr = routine.startTime ?? "Anytime";
    
    final baseColor = routine.color != null ? Color(routine.color!) : tasksPalette.accent;
    
    // Distinct Look: Lighter background, dashed border effect implied by design
    final isLight = baseColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    return IntrinsicHeight(
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
                    color: tasksPalette.textSecondary, // Softer than tasks
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: 2,
                    // Dashed line effect could be done here, but solid is fine for now
                    color: isLast ? Colors.transparent : tasksPalette.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),

          // --- Right Side: The Routine Card ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: tasksPalette.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                    ),
                    builder: (ctx) => CreateRoutineModal(routineToEdit: routine),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: tasksPalette.surface, // Card background matches surface
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 1.5), // Colored border
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: baseColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                TaskConstants.getIcon(routine.icon),
                                color: baseColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Title & Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routine.title,
                                    style: TextStyle(
                                      color: tasksPalette.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Routine • ${routine.activities.length} steps",
                                    style: TextStyle(
                                      color: tasksPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Duration Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tasksPalette.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 12, color: tasksPalette.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$duration min",
                                    style: TextStyle(
                                      color: tasksPalette.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Preview of activities (first 3)
                        if (routine.activities.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: routine.activities.take(3).map((activity) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: baseColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activity.title,
                                  style: TextStyle(
                                    color: baseColor,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (routine.activities.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "+ ${routine.activities.length - 3} more",
                                style: TextStyle(color: tasksPalette.textSecondary, fontSize: 10),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
