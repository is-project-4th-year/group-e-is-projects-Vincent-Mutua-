import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';

class AddTaskModal extends ConsumerStatefulWidget {
  const AddTaskModal({super.key});

  @override
  ConsumerState<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<AddTaskModal> {
  final _textController = TextEditingController();
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _textController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Handles submitting the new task
  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      final title = _textController.text.trim();
      final category = _categoryController.text.trim();
      
      DateTime? reminderAt;
      if (_selectedDate != null && _selectedTime != null) {
        reminderAt = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      await ref.read(tasksControllerProvider.notifier).addTask(
        title: title,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        reminderAt: reminderAt,
        category: category.isNotEmpty ? category : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksControllerProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tasksPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // --- Task Title Field ---
            TextFormField(
              controller: _textController,
              autofocus: true,
              style: TextStyle(color: tasksPalette.textPrimary),
              decoration: InputDecoration(
                labelText: 'What needs to be done?',
                labelStyle: TextStyle(color: tasksPalette.textSecondary),
                hintText: 'e.g., Read chapter 1',
                hintStyle: TextStyle(color: tasksPalette.textSecondary.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tasksPalette.textSecondary.withOpacity(0.3))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tasksPalette.accent)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // --- Category Field ---
            TextFormField(
              controller: _categoryController,
              style: TextStyle(color: tasksPalette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Category (Optional)',
                labelStyle: TextStyle(color: tasksPalette.textSecondary),
                hintText: 'e.g., Work, Personal',
                hintStyle: TextStyle(color: tasksPalette.textSecondary.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tasksPalette.textSecondary.withOpacity(0.3))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tasksPalette.accent)),
                prefixIcon: Icon(Icons.tag, color: tasksPalette.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // --- Priority Selector ---
            Text("Priority", style: TextStyle(fontSize: 12, color: tasksPalette.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                Color color;
                switch (priority) {
                  case TaskPriority.high: color = tasksPalette.priorityHigh; break;
                  case TaskPriority.medium: color = tasksPalette.priorityMedium; break;
                  case TaskPriority.low: color = tasksPalette.priorityLow; break;
                }
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedPriority = priority),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: tasksPalette.surface, width: 2) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : null,
                    ),
                    child: isSelected ? Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // --- Date & Time Row ---
            Row(
              children: [
                // Date Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Due Date", style: TextStyle(fontSize: 12, color: tasksPalette.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: tasksPalette.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tasksPalette.textSecondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: tasksPalette.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null ? "No Date" : DateFormat('MMM d').format(_selectedDate!),
                                style: TextStyle(color: tasksPalette.textPrimary),
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
                      Text("Time (Reminder)", style: TextStyle(fontSize: 12, color: tasksPalette.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: tasksPalette.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tasksPalette.textSecondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: tasksPalette.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime == null ? "No Time" : _selectedTime!.format(context),
                                style: TextStyle(color: tasksPalette.textPrimary),
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

            const SizedBox(height: 32),

            // --- Add Task Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: tasksState.isLoading ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tasksPalette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: tasksState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Create Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}