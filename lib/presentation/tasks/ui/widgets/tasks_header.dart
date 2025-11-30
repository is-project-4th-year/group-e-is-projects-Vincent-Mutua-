import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/theme/app_colors.dart';

import 'package:is_application/presentation/tasks/ui/screens/routines_screen.dart';

class TasksHeader extends ConsumerWidget {
  final DateTime selectedDate;

  const TasksHeader({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Tasks",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: tasksPalette.textPrimary,
                ),
              ),
              // Routines Button
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoutinesScreen()),
                  );
                },
                icon: Icon(Icons.repeat, color: tasksPalette.accent),
                label: Text("Routines", style: TextStyle(color: tasksPalette.accent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: tasksPalette.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, d MMMM').format(selectedDate),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: tasksPalette.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
