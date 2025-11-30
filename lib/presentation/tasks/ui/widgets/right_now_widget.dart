import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/constants/task_constants.dart';
import 'package:is_application/core/models/task_model.dart';
import 'package:is_application/core/routing/app_router.dart';
import 'package:is_application/core/theme/app_colors.dart';
import 'package:is_application/presentation/tasks/ui/widgets/visual_time_block_timer.dart';

class RightNowWidget extends ConsumerWidget {
  final TaskModel? currentTask;
  final TaskModel? nextTask;

  const RightNowWidget({
    super.key,
    this.currentTask,
    this.nextTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    if (currentTask == null && nextTask == null) {
      return const SizedBox.shrink(); // Don't show anything if nothing is scheduled
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentTask != null) ...[
            Text(
              "HAPPENING NOW",
              style: TextStyle(
                color: tasksPalette.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildCurrentTaskCard(context, currentTask!, tasksPalette),
          ] else if (nextTask != null) ...[
            Text(
              "UP NEXT",
              style: TextStyle(
                color: tasksPalette.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildNextTaskCard(context, nextTask!, tasksPalette),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentTaskCard(BuildContext context, TaskModel task, TasksPalette palette) {
    final baseColor = task.color != null ? Color(task.color!) : palette.accent;
    final duration = Duration(minutes: task.durationMinutes ?? 30);
    
    // Calculate progress for the mini visual timer
    // We need to know when it started vs now
    final now = DateTime.now();
    final start = task.startDate?.toDate() ?? now;
    final end = start.add(duration);
    
    // If start is in future (shouldn't happen for 'current'), clamp
    // If end is past, clamp
    final totalSeconds = duration.inSeconds;
    final elapsedSeconds = now.difference(start).inSeconds;
    final progress = (totalSeconds > 0) ? (1.0 - (elapsedSeconds / totalSeconds)).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.taskTimer, extra: task);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini Visual Timer
            SizedBox(
              width: 60,
              height: 60,
              child: CustomPaint(
                painter: VisualTimerPainter(
                  progress: progress.toDouble(),
                  color: Colors.white,
                  trackColor: Colors.white.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Icon(
                    TaskConstants.getIcon(task.icon),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${(progress * duration.inMinutes).round()} min remaining",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.transparent, // Removed white circle background
                shape: BoxShape.circle,
                // Removed border entirely
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTaskCard(BuildContext context, TaskModel task, TasksPalette palette) {
    final baseColor = task.color != null ? Color(task.color!) : palette.accent;
    final start = task.startDate?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(start);
    final diff = start.difference(DateTime.now());
    
    // Tiimo Style: Solid block for consistency
    final isLight = baseColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    String startsIn;
    if (diff.inMinutes < 60) {
      startsIn = "In ${diff.inMinutes} min";
    } else {
      startsIn = "In ${diff.inHours} hr";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor, // Solid color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              TaskConstants.getIcon(task.icon),
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$timeStr • $startsIn",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
