import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:is_application/presentation/tasks/ui/widgets/subtasks_list.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  
  late TaskPriority _priority;
  DateTime? _dueDate;
  TimeOfDay? _reminderTime;
  late List<SubTask> _subTasks;

  // Tiimo-like Visual Fields
  String? _selectedCategory;
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
    _titleController = TextEditingController(text: widget.task.title);
    _categoryController = TextEditingController(text: widget.task.category);
    
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate?.toDate();
    if (widget.task.reminderAt != null) {
      final dt = widget.task.reminderAt!.toDate();
      _reminderTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    _subTasks = List.from(widget.task.subTasks);

    // Initialize visual fields
    _selectedCategory = widget.task.category;
    _selectedColor = widget.task.color;
    _selectedIcon = widget.task.icon;
    _durationMinutes = widget.task.durationMinutes;
    _recurrenceRule = widget.task.recurrenceRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Activity"),
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
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveChanges() async {
    DateTime? reminderAt;
    if (_reminderTime != null) {
      final date = _dueDate ?? DateTime.now();
      reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
      
      // If no date and time is past, assume tomorrow
      if (_dueDate == null && reminderAt.isBefore(DateTime.now())) {
        reminderAt = reminderAt.add(const Duration(days: 1));
      }
    }

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      priority: _priority,
      dueDate: _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
      reminderAt: reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
      subTasks: _subTasks,
      color: _selectedColor,
      icon: _selectedIcon,
      durationMinutes: _durationMinutes,
      recurrenceRule: _recurrenceRule,
    );

    await ref.read(tasksControllerProvider.notifier).updateTask(updatedTask);
    if (mounted) {
      Navigator.pop(context);
    }
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
          IconButton(
            onPressed: _deleteTask,
            icon: Icon(Icons.delete_outline, color: colors.error),
            tooltip: "Delete",
          ),
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120), // Increased bottom padding for navigation bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Title Input ---
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tasksPalette.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Activity Title",
                  hintStyle: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.5)),
                ),
                maxLines: null,
              ),
              
              const SizedBox(height: 32),

              // --- Section: When ---
              _buildSectionHeader("WHEN", tasksPalette),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.calendar_today_outlined,
                      label: "Date",
                      value: _dueDate == null ? "Set Date" : DateFormat('EEE, MMM d').format(_dueDate!),
                      onTap: _pickDate,
                      palette: tasksPalette,
                    ),
                    const Divider(height: 24),
                    _buildRowItem(
                      icon: Icons.access_time_outlined,
                      label: "Time",
                      value: _reminderTime == null ? "Set Time" : _reminderTime!.format(context),
                      onTap: _pickTime,
                      palette: tasksPalette,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Section: Details ---
              _buildSectionHeader("DETAILS", tasksPalette),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Category Selector ---
                    Text("Category", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
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
                    const Divider(height: 24),

                    // --- Priority Selector ---
                    Text("Priority", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: TaskPriority.values.map((priority) {
                        final isSelected = _priority == priority;
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
                          onTap: () => setState(() => _priority = priority),
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
                    const Divider(height: 24),

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
                    ],

                    if (_selectedCategory != null) ...[
                      Text("Icon", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (_categoryIcons[_selectedCategory] ?? TaskConstants.iconMap.keys).map((iconName) {
                            final isSelected = _selectedIcon == iconName;
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
                                  color: isSelected ? iconColor : iconColor.withValues(alpha: 0.7),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 24),
                    ],

                    // --- Duration & Recurrence ---
                    Text("Duration & Recurrence", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
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
                              hintText: 'Minutes',
                              hintStyle: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: tasksPalette.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            style: TextStyle(color: tasksPalette.textPrimary),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showRecurrenceOptions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: tasksPalette.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.repeat, size: 18, color: tasksPalette.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _recurrenceRule == null ? 'Repeat' : 'Repeats',
                                  style: TextStyle(
                                    color: _recurrenceRule != null ? tasksPalette.accent : tasksPalette.textSecondary,
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
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Section: Steps ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader("STEPS", tasksPalette),
                  TextButton.icon(
                    onPressed: _generateSubtasks,
                    icon: Icon(Icons.auto_awesome, size: 16, color: tasksPalette.accent),
                    label: Text("Magic Breakdown", style: TextStyle(color: tasksPalette.accent, fontSize: 12)),
                    style: TextButton.styleFrom(
                      backgroundColor: tasksPalette.accent.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SubtasksList(
                subTasks: _subTasks,
                onSubTasksChanged: (updatedList) {
                  setState(() {
                    _subTasks = updatedList;
                  });
                },
              ),

              const SizedBox(height: 40),

              // --- Start Activity Timer Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.taskTimer, extra: widget.task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tasksPalette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: tasksPalette.accent.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    "Start Activity Timer",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TasksPalette palette) {
    return Text(
      title,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required TasksPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: palette.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: palette.textSecondary.withValues(alpha: 0.5), size: 16),
        ],
      ),
    );
  }
  Future<void> _generateSubtasks() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title first")));
      return;
    }

    setState(() {
      // Show loading indicator? Ideally yes, but for now we just block
    });

    try {
      final newSubtasks = await ref.read(tasksControllerProvider.notifier).generateSubtasks(_titleController.text);
      setState(() {
        _subTasks = [..._subTasks, ...newSubtasks];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

