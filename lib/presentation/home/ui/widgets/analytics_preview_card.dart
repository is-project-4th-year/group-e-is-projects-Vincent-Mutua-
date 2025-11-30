import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/screens/analytics_screen.dart';
import 'package:is_application/core/theme/app_colors.dart';

class AnalyticsPreviewCard extends ConsumerWidget {
  const AnalyticsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Productivity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.onSurface.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 20),
            tasksAsync.when(
              data: (tasks) {
                // --- PRESENTATION MODE: Placeholder Data ---
                // We use hardcoded values to demonstrate how the system looks with active usage.
                const int hours = 14;
                const int minutes = 35;
                const int completedTasks = 12;
                
                /* 
                // Real Data Logic (Uncomment to use real data)
                int totalMinutes = 0;
                int completedTasks = 0;
                final now = DateTime.now();
                final startOfWeek = now.subtract(const Duration(days: 7));

                for (final task in tasks) {
                  if (task.isCompleted && task.completedAt != null) {
                    final completedAt = task.completedAt!.toDate();
                    if (completedAt.isAfter(startOfWeek)) {
                      totalMinutes += task.durationMinutes ?? 25;
                      completedTasks++;
                    }
                  }
                }
                final hours = totalMinutes ~/ 60;
                final minutes = totalMinutes % 60;
                */
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${hours}h ${minutes}m",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          "Focus time (7d)",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "+$completedTasks Tasks",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Could not load stats"),
            ),
          ],
        ),
      ),
    );
  }
}
