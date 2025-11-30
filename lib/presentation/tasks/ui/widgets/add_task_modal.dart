import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:uuid/uuid.dart';

class AddTaskModal extends ConsumerStatefulWidget {
  const AddTaskModal({super.key});

  @override
  ConsumerState<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<AddTaskModal> {
  final _textController = TextEditingController();
  final _subTaskController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedCategory;
  DateTime? _selectedDate;
  DateTime? _startDate;
  TimeOfDay? _selectedTime;
  List<SubTask> _subTasks = [];
  bool _isBreakingDown = false;

  // Tiimo-like Visual Fields
  int? _selectedColor;
  String? _selectedIcon;
  int? _durationMinutes;
  String? _recurrenceRule;

  // Category Colors
  final Map<String, List<int>> _categoryColors = {
    "Work": [0xFF2196F3, 0xFF1976D2, 0xFF0D47A1, 0xFF00BCD4, 0xFF0097A7], // Blues/Cyans
    "Personal": [0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39, 0xFF9C27B0, 0xFFE91E63], // Greens/Purples/Pinks
    "School": [0xFFFF9800, 0xFFFF5722, 0xFFFFC107, 0xFFF44336, 0xFF795548], // Oranges/Reds/Browns
  };

  // Category Icons
  final Map<String, List<String>> _categoryIcons = {
    "Work": ['work', 'mail', 'phone', 'code', 'finance'],
    "Personal": ['home', 'fitness', 'food', 'game', 'music'],
    "School": ['school', 'read', 'idea', 'art', 'commute'],
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({bool isStartDate = false}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _selectedDate) ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _selectedDate = picked;
        }
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

  Future<void> _breakDownTask() async {
    final title = _textController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a task title first")),
      );
      return;
    }

    setState(() {
      _isBreakingDown = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://cathern-disembodied-nondomestically.ngrok-free.dev/break_down_task'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {'taskTitle': title}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> subtasks = data['data']['subtasks'];
        setState(() {
          for (var task in subtasks) {
            _subTasks.add(SubTask(title: task.toString(), id: const Uuid().v4()));
          }
        });
      } else {
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("AI Error: ${response.body}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint("General Error breaking down task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect to AI: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBreakingDown = false;
        });
      }
    }
  }

  void _inferVisuals() {
    if (_selectedColor != null && _selectedIcon != null) return;

    final text = "${_textController.text} ${_selectedCategory ?? ''}".toLowerCase();
    
    // Simple keyword matching
    if (text.contains('work') || text.contains('meeting') || text.contains('email') || text.contains('project')) {
        _selectedIcon ??= 'work';
        _selectedColor ??= 0xFF2196F3; // Blue
    } else if (text.contains('gym') || text.contains('run') || text.contains('workout') || text.contains('exercise')) {
        _selectedIcon ??= 'fitness';
        _selectedColor ??= 0xFF4CAF50; // Green
    } else if (text.contains('study') || text.contains('read') || text.contains('learn') || text.contains('class')) {
        _selectedIcon ??= 'book';
        _selectedColor ??= 0xFFFF9800; // Orange
    } else if (text.contains('sleep') || text.contains('nap') || text.contains('rest')) {
        _selectedIcon ??= 'moon';
        _selectedColor ??= 0xFF673AB7; // Purple
    } else if (text.contains('food') || text.contains('lunch') || text.contains('dinner') || text.contains('cook')) {
        _selectedIcon ??= 'restaurant'; // Assuming this exists or similar
        _selectedColor ??= 0xFFE91E63; // Pink
    }
    
    // Default fallback if still null
    _selectedIcon ??= 'star';
    _selectedColor ??= 0xFF9E9E9E; // Grey
  }

  /// Handles submitting the new task
  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      final title = _textController.text.trim();
      
      // Infer visuals if not selected
      _inferVisuals();

      DateTime? reminderAt;
      if (_selectedTime != null) {
        final date = _selectedDate ?? DateTime.now();
        reminderAt = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        
        // If no date was selected and time is in the past, schedule for tomorrow
        if (_selectedDate == null && reminderAt.isBefore(DateTime.now())) {
          reminderAt = reminderAt.add(const Duration(days: 1));
        }
      }

      // Calculate Start Date with Time
      DateTime? finalStartDate = _startDate;
      
      // If user picked a time, merge it into the start date (or due date/today if start date is null)
      if (_selectedTime != null) {
        final baseDate = finalStartDate ?? _selectedDate ?? DateTime.now();
        finalStartDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else if (finalStartDate == null && _selectedDate != null) {
         // Fallback: If no specific start date, use due date as start date for timeline purposes
         finalStartDate = _selectedDate;
      }

      await ref.read(tasksControllerProvider.notifier).addTask(
        title: title,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        startDate: finalStartDate, // Use the calculated start date
        reminderAt: reminderAt,
        category: _selectedCategory,
        subTasks: _subTasks,
        color: _selectedColor,
        icon: _selectedIcon,
        durationMinutes: _durationMinutes,
        recurrenceRule: _recurrenceRule,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showRecurrenceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Recurrence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Does not repeat"),
                onTap: () {
                  setState(() => _recurrenceRule = null);
                  Navigator.pop(context);
                },
                trailing: _recurrenceRule == null ? const Icon(Icons.check) : null,
              ),
              ListTile(
                title: const Text("Daily"),
                onTap: () {
                  setState(() => _recurrenceRule = 'FREQ=DAILY');
                  Navigator.pop(context);
                },
                trailing: _recurrenceRule == 'FREQ=DAILY' ? const Icon(Icons.check) : null,
              ),
              ListTile(
                title: const Text("Weekly"),
                onTap: () {
                  setState(() => _recurrenceRule = 'FREQ=WEEKLY');
                  Navigator.pop(context);
                },
                trailing: _recurrenceRule == 'FREQ=WEEKLY' ? const Icon(Icons.check) : null,
              ),
              ListTile(
                title: const Text("Monthly"),
                onTap: () {
                  setState(() => _recurrenceRule = 'FREQ=MONTHLY');
                  Navigator.pop(context);
                },
                trailing: _recurrenceRule == 'FREQ=MONTHLY' ? const Icon(Icons.check) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksControllerProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    String recurrenceText = 'Recurrence';
    if (_recurrenceRule == 'FREQ=DAILY') recurrenceText = 'Daily';
    if (_recurrenceRule == 'FREQ=WEEKLY') recurrenceText = 'Weekly';
    if (_recurrenceRule == 'FREQ=MONTHLY') recurrenceText = 'Monthly';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: tasksPalette.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: tasksPalette.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- Activity Title Field ---
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Activity Title',
                  labelStyle: TextStyle(color: tasksPalette.textSecondary),
                  filled: true,
                  fillColor: tasksPalette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                style: TextStyle(color: tasksPalette.textPrimary),
                cursorColor: colors.primary,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an activity title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Subtask Field + Add Button ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subTaskController,
                      decoration: InputDecoration(
                        labelText: 'Add a step',
                        labelStyle: TextStyle(color: tasksPalette.textSecondary),
                        filled: true,
                        fillColor: tasksPalette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      style: TextStyle(color: tasksPalette.textPrimary),
                      cursorColor: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      final subTaskTitle = _subTaskController.text.trim();
                      if (subTaskTitle.isNotEmpty) {
                        setState(() {
                          _subTasks.add(SubTask(title: subTaskTitle, id: Uuid().v4()));
                          _subTaskController.clear();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // AI Breakdown Button
              GestureDetector(
                onTap: _isBreakingDown ? null : _breakDownTask,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: tasksPalette.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tasksPalette.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isBreakingDown)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tasksPalette.accent,
                          ),
                        )
                      else
                        Icon(Icons.auto_awesome, size: 16, color: tasksPalette.accent),
                      const SizedBox(width: 8),
                      Text(
                        _isBreakingDown ? "Thinking..." : "Breakdown with AI",
                        style: TextStyle(
                          color: tasksPalette.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtask List
              ..._subTasks.map((subTask) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: tasksPalette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subTask.title,
                          style: TextStyle(
                            color: tasksPalette.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _subTasks.removeWhere((item) => item.id == subTask.id);
                          });
                        },
                        child: Icon(Icons.remove_circle_outline, color: colors.error, size: 20),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // --- Category Selector ---
              Text("Category", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ["Work", "Personal", "School"].map((category) {
                  final isSelected = _selectedCategory == category;
                  Color categoryColor;
                  switch (category) {
                    case "Work":
                      categoryColor = tasksPalette.categoryWork;
                      break;
                    case "Personal":
                      categoryColor = tasksPalette.categoryPersonal;
                      break;
                    case "School":
                      categoryColor = tasksPalette.categorySchool;
                      break;
                    default:
                      categoryColor = tasksPalette.textSecondary;
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = isSelected ? null : category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? categoryColor.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? categoryColor : colors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? categoryColor : tasksPalette.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // --- Priority Selector ---
              Text("Priority", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  String label;
                  switch (priority) {
                    case TaskPriority.high: 
                      label = "High";
                      break;
                    case TaskPriority.medium: 
                      label = "Medium";
                      break;
                    case TaskPriority.low: 
                      label = "Low";
                      break;
                  }
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPriority = priority),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? tasksPalette.textPrimary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? tasksPalette.textPrimary : colors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? tasksPalette.textPrimary : tasksPalette.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // --- Visuals (Color & Icon) ---
              if (_selectedCategory != null) ...[
                Text("Color", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (_categoryColors[_selectedCategory] ?? TaskConstants.colorPalette).map((colorValue) {
                      final isSelected = _selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = isSelected ? null : colorValue),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: tasksPalette.textPrimary, width: 2) : null,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: Color(colorValue).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Text("Select a Category to choose a color", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
              ],

              if (_selectedCategory != null) ...[
                Text("Icon", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (_categoryIcons[_selectedCategory] ?? TaskConstants.iconMap.keys).map((iconName) {
                      final isSelected = _selectedIcon == iconName;
                      // Determine icon color: Use selected color if available, else use the first color of the category
                      final iconColor = _selectedColor != null 
                          ? Color(_selectedColor!) 
                          : Color((_categoryColors[_selectedCategory] ?? [0xFF9E9E9E]).first);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = isSelected ? null : iconName),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? iconColor.withValues(alpha: 0.1) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: iconColor, width: 1.5) : Border.all(color: colors.border),
                          ),
                          child: Icon(
                            TaskConstants.getIcon(iconName),
                            size: 18,
                            color: isSelected ? iconColor : iconColor.withValues(alpha: 0.7), // Always colored, slightly dimmed if not selected
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Text("Select a Category to choose an icon", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
              ],

              // --- Duration (Timeline Blocking) ---
              Text("Duration", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _durationMinutes != null ? _durationMinutes.toString() : null,
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        setState(() {
                          _durationMinutes = intValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Duration in minutes',
                        labelStyle: TextStyle(color: tasksPalette.textSecondary),
                        filled: true,
                        fillColor: tasksPalette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      style: TextStyle(color: tasksPalette.textPrimary),
                      cursorColor: colors.primary,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showRecurrenceOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: tasksPalette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 18, color: tasksPalette.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            recurrenceText,
                            style: TextStyle(
                              color: tasksPalette.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Date & Time Row ---
              Row(
                children: [
                  // Due Date Picker
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Due Date", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickDate(isStartDate: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: tasksPalette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 18, color: _selectedDate != null ? colors.primary : tasksPalette.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null ? "Select Date" : DateFormat('MMM d').format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate != null ? tasksPalette.textPrimary : tasksPalette.textSecondary,
                                    fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
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
                        Text("Time", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: tasksPalette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 18, color: _selectedTime != null ? colors.primary : tasksPalette.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null ? "No Time" : _selectedTime!.format(context),
                                  style: TextStyle(
                                    color: _selectedTime != null ? tasksPalette.textPrimary : tasksPalette.textSecondary,
                                    fontWeight: _selectedTime != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
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
            
            // --- Start Date ---
            const SizedBox(height: 16),
            Text("Start Date", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickDate(isStartDate: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.start_rounded, size: 18, color: _startDate != null ? colors.primary : tasksPalette.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _startDate == null ? "Select Start Date" : DateFormat('MMM d').format(_startDate!),
                      style: TextStyle(
                        color: _startDate != null ? tasksPalette.textPrimary : tasksPalette.textSecondary,
                        fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Add Task Button ---
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: colors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: tasksState.isLoading ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: tasksState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Create Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            // Extra padding for scrolling
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 100),
          ],
        ),
      ),
      ),
    );
  }
}
