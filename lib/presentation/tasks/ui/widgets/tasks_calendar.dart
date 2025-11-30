import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:is_application/core/theme/app_colors.dart';

class TasksCalendar extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateChange;

  const TasksCalendar({
    super.key,
    required this.initialDate,
    required this.onDateChange,
  });

  @override
  ConsumerState<TasksCalendar> createState() => _TasksCalendarState();
}

class _TasksCalendarState extends ConsumerState<TasksCalendar> {
  late PageController _pageController;
  late DateTime _anchorDate;
  late DateTime _selectedDate;
  final int _initialPage = 5;

  @override
  void initState() {
    super.initState();
    // Strip time from initial date to avoid mismatch issues
    _anchorDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selectedDate = _anchorDate;
    
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.2, // Allows showing 5 items (center + 2 left + 2 right)
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colors = ref.watch(appColorsProvider(brightness));
    final tasksPalette = colors.tasks;

    return SizedBox(
      height: 85,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 11,
        onPageChanged: (index) {
          final daysDifference = index - _initialPage;
          final newDate = _anchorDate.add(Duration(days: daysDifference));
          setState(() {
            _selectedDate = newDate;
          });
          widget.onDateChange(newDate);
        },
        itemBuilder: (context, index) {
          final daysDifference = index - _initialPage;
          final date = _anchorDate.add(Duration(days: daysDifference));
          
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected ? colors.primaryGradient : null,
                color: isSelected ? null : tasksPalette.surface,
                border: isSelected 
                    ? null 
                    : Border.all(
                        color: isToday ? colors.primary.withValues(alpha: 0.5) : colors.border.withValues(alpha: 0.5),
                        width: isToday ? 1.5 : 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : tasksPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : tasksPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
