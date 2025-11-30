import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/providers/tasks_provider.dart';
import 'package:is_application/presentation/tasks/ui/widgets/weekly_focus_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: tasksPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Productivity Analytics",
          style: TextStyle(color: tasksPalette.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: tasksPalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Focus Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tasksPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Track your productivity trends over the last week.",
              style: TextStyle(
                fontSize: 16,
                color: tasksPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            tasksAsync.when(
              data: (tasks) => WeeklyFocusChart(tasks: tasks),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error loading data: $err"),
            ),

            const SizedBox(height: 32),
            
            // Additional Stats (Placeholder for now)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context, 
                    "Tasks Completed", 
                    "12", // Placeholder: tasksAsync.value?.where((t) => t.isCompleted).length.toString() ?? "0",
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context, 
                    "Focus Sessions", 
                    "8", // Placeholder
                    Icons.timer_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
