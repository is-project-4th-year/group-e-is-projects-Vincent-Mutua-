import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/screens/task_detail_screen.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  Color? _getCategoryColor(String? category, TasksPalette palette) {
    switch (category) {
      case "Work":
        return palette.categoryWork;
      case "Personal":
        return palette.categoryPersonal;
      case "School":
        return palette.categorySchool;
      default:
        return null;
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text("Are you sure you want to delete '${widget.task.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksControllerProvider.notifier).deleteTask(widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;
    final categoryColor = _getCategoryColor(widget.task.category, tasksPalette);
    final baseColor = widget.task.color != null ? Color(widget.task.color!) : (categoryColor ?? tasksPalette.accent);

    final completedSubtasks = widget.task.subTasks.where((s) => s.isCompleted).length;
    final totalSubtasks = widget.task.subTasks.length;
    final progressText = totalSubtasks > 0 ? '$completedSubtasks/$totalSubtasks steps' : '';

    // Determine priority color
    Color priorityColor;
    switch (widget.task.priority) {
      case TaskPriority.high:
        priorityColor = tasksPalette.priorityHigh;
        break;
      case TaskPriority.medium:
        priorityColor = tasksPalette.priorityMedium;
        break;
      case TaskPriority.low:
        priorityColor = tasksPalette.priorityLow;
        break;
    }

    return Animate(
      effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
      child: Opacity(
        opacity: widget.task.isCompleted ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            // Glassmorphism-like effect
            color: tasksPalette.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24), // Very rounded
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: widget.task),
                    ),
                  );
                },
                onLongPress: _showDeleteConfirmation,
                child: Stack(
                  children: [
                    // Priority Strip
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                      child: Row(
                        children: [
                          // Custom Checkbox
                          GestureDetector(
                            onTap: () {
                              ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(widget.task);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: widget.task.isCompleted ? baseColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: widget.task.isCompleted ? baseColor : tasksPalette.textSecondary.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: widget.task.isCompleted
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                          
                          const SizedBox(width: 16),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: widget.task.isCompleted 
                                        ? tasksPalette.textSecondary 
                                        : tasksPalette.textPrimary,
                                    decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                    decorationColor: tasksPalette.textSecondary,
                                  ),
                                ),
                                if (progressText.isNotEmpty || widget.task.category != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Icon
                                      if (widget.task.icon != null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Icon(
                                            TaskConstants.getIcon(widget.task.icon!),
                                            size: 16,
                                            color: baseColor,
                                          ),
                                        ),
                                      
                                      // Category Chip
                                      if (widget.task.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: baseColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            widget.task.category!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: baseColor,
                                            ),
                                          ),
                                        ),

                                      // Duration Chip
                                      if (widget.task.durationMinutes != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: tasksPalette.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: tasksPalette.textSecondary.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer_outlined, size: 12, color: tasksPalette.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${widget.task.durationMinutes}m',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: tasksPalette.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (progressText.isNotEmpty)
                                        Text(
                                          progressText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tasksPalette.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Time/Icon
                          if (widget.task.reminderAt != null)
                             Icon(Icons.alarm, size: 18, color: tasksPalette.textSecondary.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
