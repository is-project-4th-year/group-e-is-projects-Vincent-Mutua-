import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/screens/routines_screen.dart';
import 'package:is_application/presentation/tasks/ui/screens/analytics_screen.dart';
import 'package:is_application/presentation/tasks/ui/widgets/add_task_modal.dart';
import 'package:is_application/presentation/tasks/ui/widgets/right_now_widget.dart';
import 'package:is_application/presentation/tasks/ui/widgets/timeline_routine_card.dart';
import 'package:is_application/presentation/tasks/ui/widgets/tasks_calendar.dart';
import 'package:is_application/presentation/tasks/ui/widgets/timeline_task_card.dart';
import 'package:is_application/core/models/routine_model.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/widgets/aurora_background.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  void _showAddTaskModal(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
    final routinesAsyncValue = ref.watch(routinesStreamProvider);
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Scaffold(
      backgroundColor: tasksPalette.background,
      body: AuroraBackground(
        baseColor: colors.background,
        accentColor: tasksPalette.accent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Simplified Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tasksPalette.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: tasksPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                        );
                      },
                      icon: const Icon(Icons.bar_chart_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: tasksPalette.accent.withValues(alpha: 0.1),
                        foregroundColor: tasksPalette.accent,
                      ),
                      tooltip: "Analytics",
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoutinesScreen()),
                        );
                      },
                      icon: const Icon(Icons.repeat),
                      style: IconButton.styleFrom(
                        backgroundColor: tasksPalette.accent.withValues(alpha: 0.1),
                        foregroundColor: tasksPalette.accent,
                      ),
                      tooltip: "Routines",
                    ),
                  ],
                ),
              ),

              // --- Right Now Widget (Only show if today is selected) ---
              if (DateUtils.isSameDay(_selectedDate, DateTime.now()))
                tasksAsyncValue.when(
                  data: (tasks) {
                    final now = DateTime.now();
                    
                    // Find Current Task
                    // Logic: Start <= Now < End AND Not Completed
                    final current = tasks.where((t) {
                      if (t.isCompleted) return false;
                      final start = t.startDate?.toDate() ?? t.createdAt?.toDate() ?? now;
                      final duration = t.durationMinutes ?? 30;
                      final end = start.add(Duration(minutes: duration));
                      return now.isAfter(start) && now.isBefore(end);
                    }).firstOrNull;

                    // Find Next Task
                    // Logic: Start > Now AND Not Completed, sorted by start time
                    final next = tasks.where((t) {
                      if (t.isCompleted) return false;
                      final start = t.startDate?.toDate() ?? t.createdAt?.toDate() ?? now;
                      return start.isAfter(now);
                    }).toList()
                      ..sort((a, b) {
                        final startA = a.startDate?.toDate() ?? a.createdAt?.toDate() ?? now;
                        final startB = b.startDate?.toDate() ?? b.createdAt?.toDate() ?? now;
                        return startA.compareTo(startB);
                      });
                    
                    final nextTask = next.firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: RightNowWidget(
                        currentTask: current,
                        nextTask: nextTask,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              // --- Horizontal Calendar ---
              TasksCalendar(
                key: const ValueKey('calendar_fixed_range'),
                initialDate: DateTime.now(),
                onDateChange: (selectedDate) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                },
              ),

              const SizedBox(height: 16),

              // --- Task & Routine List ---
              Expanded(
                child: tasksAsyncValue.when(
                  loading: () => Center(child: CircularProgressIndicator(color: tasksPalette.accent)),
                  error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: colors.error))),
                  data: (tasks) {
                    return routinesAsyncValue.when(
                      loading: () => Center(child: CircularProgressIndicator(color: tasksPalette.accent)),
                      error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: colors.error))),
                      data: (routines) {
                        // 1. Filter Tasks
                        final filteredTasks = tasks.where((task) {
                          bool isSameDay(DateTime? d1, DateTime d2) {
                            if (d1 == null) return false;
                            return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
                          }

                          final selected = _selectedDate;
                          final start = task.startDate?.toDate() ?? task.createdAt?.toDate() ?? DateTime.now();
                          final due = task.dueDate?.toDate();

                          if (isSameDay(start, selected)) return true;
                          if (isSameDay(due, selected)) return true;
                          if (due != null && !task.isCompleted) {
                            final selectedDateOnly = DateTime(selected.year, selected.month, selected.day);
                            final startDateOnly = DateTime(start.year, start.month, start.day);
                            final dueDateOnly = DateTime(due.year, due.month, due.day);
                            if (selectedDateOnly.isAfter(startDateOnly) && selectedDateOnly.isBefore(dueDateOnly)) {
                              return true;
                            }
                          }
                          return false;
                        }).toList();

                        // 2. Filter Routines
                        final selectedDayName = DateFormat('E').format(_selectedDate); // Mon, Tue, etc.
                        final filteredRoutines = routines.where((routine) {
                          // Show if recurrence contains the day
                          return routine.recurrence.contains(selectedDayName);
                        }).toList();

                        // 3. Merge and Sort
                        final List<dynamic> timelineItems = [...filteredTasks, ...filteredRoutines];
                        
                        timelineItems.sort((a, b) {
                          DateTime timeA;
                          if (a is TaskModel) {
                            timeA = a.startDate?.toDate() ?? a.createdAt?.toDate() ?? DateTime.now();
                          } else if (a is RoutineModel) {
                            if (a.startTime != null) {
                              final parts = a.startTime!.split(":");
                              timeA = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(parts[0]), int.parse(parts[1]));
                            } else {
                              timeA = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0); // Start of day if no time
                            }
                          } else {
                            timeA = DateTime.now();
                          }

                          DateTime timeB;
                          if (b is TaskModel) {
                            timeB = b.startDate?.toDate() ?? b.createdAt?.toDate() ?? DateTime.now();
                          } else if (b is RoutineModel) {
                            if (b.startTime != null) {
                              final parts = b.startTime!.split(":");
                              timeB = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(parts[0]), int.parse(parts[1]));
                            } else {
                              timeB = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
                            }
                          } else {
                            timeB = DateTime.now();
                          }

                          return timeA.compareTo(timeB);
                        });

                        if (timelineItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: tasksPalette.accent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.spa_outlined, size: 48, color: tasksPalette.accent),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Enjoy your free time!',
                                  style: TextStyle(
                                    color: tasksPalette.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No activities scheduled for this day.',
                                  style: TextStyle(color: tasksPalette.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: timelineItems.length,
                          itemBuilder: (context, index) {
                            final item = timelineItems[index];
                            final isFirst = index == 0;
                            final isLast = index == timelineItems.length - 1;

                            if (item is TaskModel) {
                              return TimelineTaskCard(
                                task: item,
                                isFirst: isFirst,
                                isLast: isLast,
                              );
                            } else if (item is RoutineModel) {
                              return TimelineRoutineCard(
                                routine: item,
                                isFirst: isFirst,
                                isLast: isLast,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140), // Raise above custom nav bar
        child: FloatingActionButton.extended(
          heroTag: 'tasks_fab',
          onPressed: () => _showAddTaskModal(context),
          backgroundColor: tasksPalette.accent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

