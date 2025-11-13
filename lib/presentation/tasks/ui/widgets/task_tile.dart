import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';

class TaskTile extends ConsumerWidget {
  final TaskModel task;

  const TaskTile({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));

    // This widget allows the user to swipe left or right
    return Dismissible(
      // The key MUST be unique, so we use the task's ID
      key: ValueKey(task.id),
      
      // --- Swipe-to-Delete Logic ---
      direction: DismissDirection.endToStart, // Only allow swipe from right-to-left
      onDismissed: (direction) {
        // When dismissed, call the controller to delete the task
        ref.read(tasksControllerProvider.notifier).deleteTask(task);
      },
      // The red background that appears when swiping
      background: Container(
        color: colors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Icon(Icons.delete_outline, color: colors.onError),
      ),
      
      // --- The Task Tile UI ---
      child: Card(
        // We use our modern CardTheme defined in app_theme.dart
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          onTap: () {
            // We can use this later to open a detail view
          },
          
          // --- Custom Checkbox ---
          leading: Checkbox(
            value: task.isCompleted,
            // When tapped, call the controller to toggle the status
            onChanged: (value) {
              ref.read(tasksControllerProvider.notifier).toggleTaskCompletion(task);
            },
            // Apply our app's theme colors
            activeColor: colors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // --- Task Title ---
          title: Text(
            task.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              // Add a "strikethrough" style when completed
              decoration: task.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
              color: task.isCompleted 
                ? colors.onSurface.withOpacity(0.5) 
                : colors.onSurface,
            ),
          ),
          
          // TODO: Add due date or sub-task info here
          // subtitle: task.dueDate != null ? Text("Due: ...") : null,
          
          // --- Trailing Handle (for reordering later) ---
          trailing: const Icon(
            Icons.drag_handle,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}