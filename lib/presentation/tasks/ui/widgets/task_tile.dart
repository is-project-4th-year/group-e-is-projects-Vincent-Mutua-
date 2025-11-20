import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/screens/task_detail_screen.dart';

class TaskTile extends ConsumerWidget {
  final TaskModel task;

  const TaskTile({
    super.key,
    required this.task,
  });

  Color _getPriorityColor(TaskPriority priority, TasksPalette palette) {
    switch (priority) {
      case TaskPriority.high:
        return palette.priorityHigh;
      case TaskPriority.medium:
        return palette.priorityMedium;
      case TaskPriority.low:
        return palette.priorityLow;
    }
  }

  String _formatDate(TaskModel task) {
    if (task.reminderAt != null) {
      return DateFormat('MMM d, h:mm a').format(task.reminderAt!.toDate());
    } else if (task.dueDate != null) {
      return DateFormat('MMM d').format(task.dueDate!.toDate());
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(tasksControllerProvider.notifier).deleteTask(task);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.delete_outline, color: colors.onError),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: tasksPalette.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Priority Strip
                  Container(
                    width: 6,
                    color: _getPriorityColor(task.priority, tasksPalette),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Custom Checkbox
                          GestureDetector(
                            onTap: () {
                              ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(task);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: task.isCompleted ? tasksPalette.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: task.isCompleted ? tasksPalette.accent : tasksPalette.textSecondary.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: task.isCompleted
                                  ? Icon(Icons.check, size: 16, color: tasksPalette.surface)
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
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: task.isCompleted 
                                        ? tasksPalette.textSecondary.withOpacity(0.5) 
                                        : tasksPalette.textPrimary,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (task.dueDate != null || task.category != null || task.subTasks.isNotEmpty || task.reminderAt != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (task.dueDate != null || task.reminderAt != null) ...[
                                        Icon(
                                          task.reminderAt != null ? Icons.alarm : Icons.calendar_today, 
                                          size: 12, 
                                          color: tasksPalette.textSecondary
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(task),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tasksPalette.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (task.subTasks.isNotEmpty) ...[
                                        Icon(Icons.checklist, size: 14, color: tasksPalette.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${task.subTasks.where((s) => s.isCompleted).length}/${task.subTasks.length}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tasksPalette.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (task.category != null && task.category!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tasksPalette.accent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            task.category!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: tasksPalette.accent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}