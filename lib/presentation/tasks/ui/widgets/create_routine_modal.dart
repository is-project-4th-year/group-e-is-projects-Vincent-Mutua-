import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/routine_model.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';

class CreateRoutineModal extends ConsumerStatefulWidget {
  final RoutineModel? routineToEdit;
  const CreateRoutineModal({super.key, this.routineToEdit});

  @override
  ConsumerState<CreateRoutineModal> createState() => _CreateRoutineModalState();
}

class _CreateRoutineModalState extends ConsumerState<CreateRoutineModal> {
  late TextEditingController _titleController;
  final _activityTitleController = TextEditingController();
  final _activityDurationController = TextEditingController(text: "15");
  
  late List<RoutineActivity> _activities;
  int? _selectedColor;
  String? _selectedIcon;
  String? _selectedCategory;
  TimeOfDay? _startTime;
  List<String> _selectedDays = [];

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

  final List<String> _weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routineToEdit?.title ?? "");
    _activities = widget.routineToEdit?.activities.toList() ?? [];
    _selectedColor = widget.routineToEdit?.color;
    _selectedIcon = widget.routineToEdit?.icon;
    _selectedCategory = widget.routineToEdit?.category;
    
    if (widget.routineToEdit?.startTime != null) {
      final parts = widget.routineToEdit!.startTime!.split(":");
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    
    _selectedDays = widget.routineToEdit?.recurrence.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _activityTitleController.dispose();
    _activityDurationController.dispose();
    super.dispose();
  }

  void _addActivity() {
    final title = _activityTitleController.text.trim();
    final duration = int.tryParse(_activityDurationController.text) ?? 15;
    
    if (title.isNotEmpty) {
      setState(() {
        _activities.add(RoutineActivity(
          title: title,
          durationMinutes: duration,
        ));
        _activityTitleController.clear();
        _activityDurationController.text = "15";
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _saveRoutine() async {
    final title = _titleController.text.trim();
    final user = ref.read(authStateProvider).value;
    
    if (title.isNotEmpty && user != null) {
      final routine = RoutineModel(
        uid: user.uid,
        id: widget.routineToEdit?.id, // Preserve ID if editing
        title: title,
        category: _selectedCategory,
        color: _selectedColor,
        icon: _selectedIcon,
        startTime: _startTime != null ? "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}" : null,
        recurrence: _selectedDays,
        activities: _activities,
      );
      
      if (widget.routineToEdit != null && widget.routineToEdit!.id != null) {
        await ref.read(firestoreRepositoryProvider).updateRoutine(user.uid, widget.routineToEdit!.id!, routine);
      } else {
        await ref.read(firestoreRepositoryProvider).addRoutine(routine);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.routineToEdit != null ? "Edit Routine" : "New Routine",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tasksPalette.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: tasksPalette.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Routine Name
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: tasksPalette.textPrimary),
              decoration: InputDecoration(
                labelText: "Routine Name",
                labelStyle: TextStyle(color: tasksPalette.textSecondary),
                filled: true,
                fillColor: tasksPalette.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary)),
              ),
            ),
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
            
            // Appearance (Color & Icon)
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
              const SizedBox(height: 24),
            ],
            
            // --- Schedule (Time & Recurrence) ---
            Text("Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tasksPalette.textPrimary)),
            const SizedBox(height: 16),
            
            // Start Time
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: tasksPalette.accent),
                    const SizedBox(width: 12),
                    Text(
                      _startTime != null ? _startTime!.format(context) : "Set Start Time",
                      style: TextStyle(
                        color: _startTime != null ? tasksPalette.textPrimary : tasksPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Recurrence
            Text("Repeat On", style: TextStyle(fontSize: 13, color: tasksPalette.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? tasksPalette.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? tasksPalette.accent : colors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day[0], // First letter
                      style: TextStyle(
                        color: isSelected ? Colors.white : tasksPalette.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text("Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tasksPalette.textPrimary)),
            const SizedBox(height: 8),
            
            if (_activities.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: _activities.map((a) => ListTile(
                    title: Text(a.title, style: TextStyle(color: tasksPalette.textPrimary)),
                    subtitle: Text("${a.durationMinutes} min", style: TextStyle(color: tasksPalette.textSecondary)),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: tasksPalette.textSecondary),
                      onPressed: () => setState(() => _activities.remove(a)),
                    ),
                  )).toList(),
                ),
              ),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _activityTitleController,
                    style: TextStyle(color: tasksPalette.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Activity Name",
                      hintStyle: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: tasksPalette.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _activityDurationController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: tasksPalette.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Min",
                      hintStyle: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: tasksPalette.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addActivity,
                  style: IconButton.styleFrom(
                    backgroundColor: tasksPalette.surface,
                    foregroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
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
                onPressed: _saveRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.routineToEdit != null ? "Update Routine" : "Save Routine",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
