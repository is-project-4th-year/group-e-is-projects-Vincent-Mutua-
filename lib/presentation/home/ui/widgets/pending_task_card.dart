import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/routing/app_router.dart';

class PendingTaskCard extends StatelessWidget {
  final TaskModel task;

  const PendingTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.color != null ? Color(task.color!) : Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        // Navigate to tasks screen or task detail
        context.go(AppRoutes.tasks);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "UP NEXT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (task.priority == TaskPriority.high)
                  const Icon(Icons.priority_high_rounded, color: Colors.white, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (task.dueDate != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(task.dueDate!.toDate()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              const Text(
                "No due date",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
