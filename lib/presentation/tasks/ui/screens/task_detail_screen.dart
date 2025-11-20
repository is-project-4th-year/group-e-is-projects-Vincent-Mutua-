import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _subtaskController;
  
  late TaskPriority _priority;
  DateTime? _dueDate;
  TimeOfDay? _reminderTime;
  late List<SubTask> _subTasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _categoryController = TextEditingController(text: widget.task.category);
    _subtaskController = TextEditingController();
    
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate?.toDate();
    if (widget.task.reminderAt != null) {
      final dt = widget.task.reminderAt!.toDate();
      _reminderTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    _subTasks = List.from(widget.task.subTasks);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    DateTime? reminderAt;
    if (_dueDate != null && _reminderTime != null) {
      reminderAt = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
    }

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
      priority: _priority,
      dueDate: _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
      reminderAt: reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
      subTasks: _subTasks,
    );

    await ref.read(tasksControllerProvider.notifier).updateTask(updatedTask);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addSubTask() {
    final title = _subtaskController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(title: title));
        _subtaskController.clear();
      });
    }
  }

  void _toggleSubTask(int index) {
    setState(() {
      final old = _subTasks[index];
      _subTasks[index] = SubTask(title: old.title, isCompleted: !old.isCompleted);
    });
  }

  void _deleteSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Scaffold(
      backgroundColor: tasksPalette.background,
      appBar: AppBar(
        backgroundColor: tasksPalette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tasksPalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              "Save",
              style: TextStyle(
                color: tasksPalette.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Input ---
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tasksPalette.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Task Title",
                hintStyle: TextStyle(color: tasksPalette.textSecondary.withOpacity(0.5)),
              ),
              maxLines: null,
            ),
            
            const SizedBox(height: 24),

            // --- Properties Row ---
            // Priority
            Text("Priority", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              dropdownColor: tasksPalette.surface,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: tasksPalette.surface,
              ),
              items: TaskPriority.values.map((p) {
                Color color;
                switch (p) {
                  case TaskPriority.high: color = tasksPalette.priorityHigh; break;
                  case TaskPriority.medium: color = tasksPalette.priorityMedium; break;
                  case TaskPriority.low: color = tasksPalette.priorityLow; break;
                }
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(p.name.toUpperCase(), style: TextStyle(color: tasksPalette.textPrimary, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _priority = val);
              },
            ),
            
            const SizedBox(height: 24),

            Row(
              children: [
                // Due Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Due Date", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: tasksPalette.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: tasksPalette.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _dueDate == null ? "Set Date" : DateFormat('MMM d').format(_dueDate!),
                                style: TextStyle(color: tasksPalette.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Time Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Time (Reminder)", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: tasksPalette.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: tasksPalette.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _reminderTime == null ? "Set Time" : _reminderTime!.format(context),
                                style: TextStyle(color: tasksPalette.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Category ---
            Text("Category", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              style: TextStyle(color: tasksPalette.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: tasksPalette.surface,
                hintText: "Add a category...",
                hintStyle: TextStyle(color: tasksPalette.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.tag, color: tasksPalette.textSecondary, size: 18),
              ),
            ),

            const SizedBox(height: 32),

            // --- Subtasks ---
            Text("Subtasks", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // List of Subtasks
            ..._subTasks.asMap().entries.map((entry) {
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
                color: tasksPalette.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tasksPalette.textSecondary.withOpacity(0.2), style: BorderStyle.solid),
              ),
              child: TextField(
                controller: _subtaskController,
                style: TextStyle(color: tasksPalette.textPrimary),
                decoration: InputDecoration(
                  hintText: "Add a subtask...",
                  hintStyle: TextStyle(color: tasksPalette.textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(Icons.add, color: tasksPalette.accent),
                ),
                onSubmitted: (_) => _addSubTask(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
