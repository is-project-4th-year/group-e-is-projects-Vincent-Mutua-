import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/widgets/add_task_modal.dart';
import 'package:is_application/presentation/tasks/ui/widgets/task_tile.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedFilter = 'All'; // 'All', 'Today', 'Upcoming'

  void _showAddTaskModal(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.read(appColorsProvider(brightness));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.tasks.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => const AddTaskModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsyncValue = ref.watch(tasksProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Scaffold(
      backgroundColor: tasksPalette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tasksPalette.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "My Tasks",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: tasksPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Filter Tabs ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['All', 'Today', 'Upcoming', 'Completed'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? tasksPalette.accent : tasksPalette.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: tasksPalette.accent.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : tasksPalette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // --- Task List ---
            Expanded(
              child: tasksAsyncValue.when(
                loading: () => Center(child: CircularProgressIndicator(color: tasksPalette.accent)),
                error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: colors.error))),
                data: (tasks) {
                  // Filter Logic
                  final filteredTasks = tasks.where((task) {
                    if (_selectedFilter == 'Completed') return task.isCompleted;
                    if (task.isCompleted) return false; // Hide completed in other tabs

                    if (_selectedFilter == 'Today') {
                      if (task.dueDate == null) return false;
                      final now = DateTime.now();
                      final due = task.dueDate!.toDate();
                      return due.year == now.year && due.month == now.month && due.day == now.day;
                    }
                    
                    if (_selectedFilter == 'Upcoming') {
                      if (task.dueDate == null) return false;
                      final now = DateTime.now();
                      return task.dueDate!.toDate().isAfter(now);
                    }
                    
                    return true; // 'All'
                  }).toList();

                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt, size: 64, color: tasksPalette.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(color: tasksPalette.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return TaskTile(task: filteredTasks[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        backgroundColor: tasksPalette.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}