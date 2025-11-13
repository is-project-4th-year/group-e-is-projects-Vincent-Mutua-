import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/widgets/add_task_modal.dart';
import 'package:is_application/presentation/tasks/ui/widgets/task_tile.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  /// Shows the "Add Task" modal bottom sheet
  void _showAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Make it scrollable and respect the safe area
      isScrollControlled: true,
      useSafeArea: true,
      // Use our modern rounded theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) => const AddTaskModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the tasksProvider to get the list of tasks
    final tasksAsyncValue = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      
      // 2. Add the FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        child: const Icon(Icons.add),
      ),
      
      // 3. Handle the loading/error/data states
      body: tasksAsyncValue.when(
        // --- Loading State ---
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // --- Error State ---
        error: (error, stack) => Center(
          child: Text('Error loading tasks: $error'),
        ),
        
        // --- Data State ---
        data: (tasks) {
          // If there are no tasks, show a helpful message
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No tasks yet.\nTap the + button to add your first one!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          // If there are tasks, show them in a ListView
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(task: task);
            },
          );
        },
      ),
    );
  }
}