import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';

class AddTaskModal extends ConsumerStatefulWidget {
  const AddTaskModal({super.key});

  @override
  ConsumerState<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends ConsumerState<AddTaskModal> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Handles submitting the new task
  Future<void> _submitTask() async {
    // 1. Validate the form
    if (_formKey.currentState!.validate()) {
      final title = _textController.text.trim();
      
      // 2. Call the controller to add the task
      // We use 'await' to wait for the operation to complete
      // before closing the modal.
      await ref.read(tasksControllerProvider.notifier).addTask(title);

      // 3. Close the modal sheet
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the controller's state for loading
    final tasksState = ref.watch(tasksControllerProvider);

    return Padding(
      // This padding ensures the modal respects the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the sheet only as tall as needed
          children: [
            Text(
              'Add New Task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            // --- Task Title Field ---
            TextFormField(
              controller: _textController,
              autofocus: true, // Automatically open the keyboard
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Read chapter 1 of my book',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              // Allow submitting with the keyboard's "done" button
              onFieldSubmitted: (_) => _submitTask(),
            ),
            const SizedBox(height: 24),

            // --- Add Task Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tasksState.isLoading ? null : _submitTask,
                child: tasksState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Add Task'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}