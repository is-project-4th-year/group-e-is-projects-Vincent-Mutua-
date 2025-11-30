import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class SubtasksList extends ConsumerStatefulWidget {
  final List<SubTask> subTasks;
  final Function(List<SubTask>) onSubTasksChanged;

  const SubtasksList({
    super.key,
    required this.subTasks,
    required this.onSubTasksChanged,
  });

  @override
  ConsumerState<SubtasksList> createState() => _SubtasksListState();
}

class _SubtasksListState extends ConsumerState<SubtasksList> {
  late TextEditingController _subtaskController;

  @override
  void initState() {
    super.initState();
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubTask() {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      final newSubTask = SubTask(
        id: const Uuid().v4(),
        title: title,
      );
      final updatedList = List<SubTask>.from(widget.subTasks)..add(newSubTask);
      widget.onSubTasksChanged(updatedList);
      _subtaskController.clear();
    }
  }

  void _toggleSubTask(int index) {
    final old = widget.subTasks[index];
    final updatedSubTask = SubTask(
      id: old.id,
      title: old.title,
      isCompleted: !old.isCompleted,
    );
    final updatedList = List<SubTask>.from(widget.subTasks);
    updatedList[index] = updatedSubTask;
    widget.onSubTasksChanged(updatedList);
  }

  void _deleteSubTask(int index) {
    final updatedList = List<SubTask>.from(widget.subTasks)..removeAt(index);
    widget.onSubTasksChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of Subtasks
        ...widget.subTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final subtask = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: tasksPalette.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Checkbox(
                value: subtask.isCompleted,
                activeColor: tasksPalette.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => _toggleSubTask(index),
              ),
              title: Text(
                subtask.title,
                style: TextStyle(
                  color: subtask.isCompleted ? tasksPalette.textSecondary : tasksPalette.textPrimary,
                  decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 18, color: tasksPalette.textSecondary),
                onPressed: () => _deleteSubTask(index),
              ),
            ),
          );
        }),

        // Add Subtask Input
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: tasksPalette.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tasksPalette.textSecondary.withValues(alpha: 0.2), style: BorderStyle.solid),
          ),
          child: TextField(
            controller: _subtaskController,
            style: TextStyle(color: tasksPalette.textPrimary),
            decoration: InputDecoration(
              hintText: "Add a subtask...",
              hintStyle: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.add, color: tasksPalette.accent),
              suffixIcon: IconButton(
                icon: Icon(Icons.check, color: tasksPalette.accent),
                onPressed: _addSubTask,
              ),
            ),
            onSubmitted: (_) => _addSubTask(),
          ),
        ),
      ],
    );
  }
}
