import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/routine_model.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/auth/providers/auth_providers.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';
import 'package:is_application/presentation/tasks/ui/widgets/create_routine_modal.dart';

final routinesStreamProvider = StreamProvider.autoDispose<List<RoutineModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(firestoreRepositoryProvider);
  return repo.watchRoutines(user.uid);
});

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  void _startRoutine(BuildContext context, WidgetRef ref, RoutineModel routine) async {
    // Copy routine activities to tasks for TODAY
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final now = DateTime.now();
    DateTime startTime = now; // Start the first task now

    for (var activity in routine.activities) {
      final newTask = TaskModel(
        uid: user.uid,
        title: activity.title,
        startDate: Timestamp.fromDate(startTime),
        durationMinutes: activity.durationMinutes,
        icon: activity.icon ?? routine.icon,
        color: activity.color ?? routine.color,
      );

      await ref.read(firestoreRepositoryProvider).addTask(newTask);

      // Increment start time for next task
      startTime = startTime.add(Duration(minutes: activity.durationMinutes));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Started routine: ${routine.title}")),
      );
      Navigator.pop(context); // Go back to tasks
    }
  }

  Future<void> _deleteRoutine(BuildContext context, WidgetRef ref, RoutineModel routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Routine"),
        content: Text("Are you sure you want to delete '${routine.title}'?"),
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

    if (confirmed == true && routine.id != null) {
      await ref.read(firestoreRepositoryProvider).deleteRoutine(routine.uid, routine.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesStreamProvider);
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Scaffold(
      backgroundColor: tasksPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Routines", style: TextStyle(color: tasksPalette.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: tasksPalette.textPrimary),
      ),
      body: routinesAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: tasksPalette.accent)),
        error: (err, _) => Center(child: Text("Error: $err", style: TextStyle(color: colors.error))),
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: tasksPalette.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text("No routines yet", style: TextStyle(color: tasksPalette.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Create a routine to quickly add sets of tasks", style: TextStyle(color: tasksPalette.textSecondary.withValues(alpha: 0.7), fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              final baseColor = routine.color != null ? Color(routine.color!) : tasksPalette.accent;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: tasksPalette.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Edit Routine
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: tasksPalette.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                        ),
                        builder: (context) => CreateRoutineModal(routineToEdit: routine),
                      );
                    },
                    onLongPress: () => _deleteRoutine(context, ref, routine),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: baseColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  TaskConstants.getIcon(routine.icon),
                                  color: baseColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      routine.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: tasksPalette.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${routine.activities.length} activities • ${routine.activities.fold(0, (sum, item) => sum + item.durationMinutes)} min total",
                                      style: TextStyle(color: tasksPalette.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _startRoutine(context, ref, routine),
                                style: IconButton.styleFrom(
                                  backgroundColor: tasksPalette.accent.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: Icon(Icons.play_arrow_rounded, color: tasksPalette.accent, size: 28),
                                tooltip: "Start Routine",
                              ),
                            ],
                          ),
                          if (routine.activities.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: colors.border,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: routine.activities.take(3).map((activity) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: baseColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: baseColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    activity.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tasksPalette.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (routine.activities.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "+ ${routine.activities.length - 3} more",
                                  style: TextStyle(fontSize: 12, color: tasksPalette.textSecondary),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140), // Raise above custom nav bar
        child: FloatingActionButton.extended(
          heroTag: 'routines_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: tasksPalette.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              builder: (context) => const CreateRoutineModal(),
            );
          },
          label: const Text("New Routine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: tasksPalette.accent,
        ),
      ),
    );
  }
}
