import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/theme/app_colors.dart';

class WeeklyFocusChart extends StatelessWidget {
  final List<TaskModel> tasks;

  const WeeklyFocusChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // We can assume we are in the tasks context, so we might want to use tasks palette
    // But for now let's just use generic colors or pass them in.
    // Ideally we get colors from provider, but let's keep it simple for this widget.
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Process Data
    // Map of 0-6 (Mon-Sun) or just last 7 days to minutes
    final Map<int, int> dailyMinutes = {};
    
    // --- PRESENTATION MODE: Placeholder Data ---
    // We populate the chart with fake data to show a realistic usage pattern.
    dailyMinutes[0] = 45;  // 6 days ago
    dailyMinutes[1] = 120; // 5 days ago
    dailyMinutes[2] = 30;  // 4 days ago
    dailyMinutes[3] = 90;  // 3 days ago
    dailyMinutes[4] = 60;  // 2 days ago
    dailyMinutes[5] = 15;  // Yesterday
    dailyMinutes[6] = 75;  // Today

    int maxMinutes = 120; // Fixed scale for presentation

    /*
    // Real Data Logic (Uncomment to use real data)
    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      dailyMinutes[i] = 0;
    }
    int maxMinutes = 0;
    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final completedDate = task.completedAt!.toDate();
        final dateOnly = DateTime(completedDate.year, completedDate.month, completedDate.day);
        
        final diff = today.difference(dateOnly).inDays;
        if (diff >= 0 && diff < 7) {
          final index = 6 - diff;
          final duration = task.durationMinutes ?? 25;
          dailyMinutes[index] = (dailyMinutes[index] ?? 0) + duration;
          
          if (dailyMinutes[index]! > maxMinutes) {
            maxMinutes = dailyMinutes[index]!;
          }
        }
      }
    }
    if (maxMinutes == 0) maxMinutes = 60;
    */

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Focus History",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Last 7 Days",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final minutes = dailyMinutes[index] ?? 0;
                final heightFactor = minutes / maxMinutes;
                final date = today.subtract(Duration(days: 6 - index));
                final dayLabel = DateFormat('E').format(date)[0]; // M, T, W...
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tooltip or Value
                    if (minutes > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "${minutes}m",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    
                    // The Bar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightFactor),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, _) {
                        return Container(
                          width: 16,
                          height: 100 * value + 4, // Min height 4 for visibility
                          decoration: BoxDecoration(
                            color: index == 6 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: index == 6 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: index == 6 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
