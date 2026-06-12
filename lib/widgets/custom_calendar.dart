import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';

class CustomCalendar extends StatefulWidget {
  final Map<String, List<WorkoutSession>> workoutsByDate;
  final Function(DateTime)? onDateSelected;

  const CustomCalendar({
    super.key,
    required this.workoutsByDate,
    this.onDateSelected,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // Calculate days from previous month to fill the first week grid (starting Sunday)
    final firstDayOfWeek = firstDay.weekday % 7; // Sunday is 0, Monday is 1...
    final days = <DateTime>[];

    for (var i = firstDayOfWeek; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    // Add current month days
    for (var i = 0; i < lastDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    // Add next month days to fill the grid up to multiple of 7
    final totalCells = ((days.length + 6) ~/ 7) * 7;
    final remaining = totalCells - days.length;
    for (var i = 1; i <= remaining; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }

    return days;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedMonth);
    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final dateKey = _formatDateKey(date);
              final isCurrentMonth = date.month == _focusedMonth.month;
              final hasWorkout = widget.workoutsByDate.containsKey(dateKey);
              final isToday = dateKey == todayKey;

              return GestureDetector(
                onTap: () {
                  if (widget.onDateSelected != null) {
                    widget.onDateSelected!(date);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasWorkout
                        ? AppTheme.primary.withAlpha(200)
                        : Colors.transparent,
                    border: isToday
                        ? Border.all(color: AppTheme.secondary, width: 2)
                        : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (hasWorkout || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasWorkout
                          ? Colors.black
                          : (isCurrentMonth
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary.withAlpha(80)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
