import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// A multi-date picker built on top of `table_calendar` that supports
/// non-consecutive selections. Tap a day to toggle it. Disabled dates
/// (passed via [blockedDates]) are grayed out and non-selectable.
class MultiDateCalendar extends StatefulWidget {
  final Set<DateTime> selectedDates;
  final Set<DateTime> blockedDates;
  final ValueChanged<Set<DateTime>> onChanged;
  final DateTime? firstDay;
  final DateTime? lastDay;

  const MultiDateCalendar({
    super.key,
    required this.selectedDates,
    required this.blockedDates,
    required this.onChanged,
    this.firstDay,
    this.lastDay,
  });

  @override
  State<MultiDateCalendar> createState() => _MultiDateCalendarState();
}

class _MultiDateCalendarState extends State<MultiDateCalendar> {
  late DateTime _focused;

  @override
  void initState() {
    super.initState();
    _focused = DateTime.now();
  }

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isBlocked(DateTime day) {
    final n = _norm(day);
    if (widget.blockedDates.contains(n)) return true;
    final today = _norm(DateTime.now());
    return n.isBefore(today);
  }

  bool _isSelected(DateTime day) => widget.selectedDates.contains(_norm(day));

  void _toggle(DateTime day) {
    if (_isBlocked(day)) return;
    final n = _norm(day);
    final next = Set<DateTime>.from(widget.selectedDates);
    if (next.contains(n)) {
      next.remove(n);
    } else {
      next.add(n);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        TableCalendar(
          firstDay:
              widget.firstDay ?? DateTime.now().subtract(const Duration(days: 1)),
          lastDay: widget.lastDay ??
              DateTime.now().add(const Duration(days: 365 * 2)),
          focusedDay: _focused,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w700),
            leftChevronIcon:
                Icon(Icons.chevron_left_rounded, color: cs.primary),
            rightChevronIcon:
                Icon(Icons.chevron_right_rounded, color: cs.primary),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: cs.onSurfaceVariant),
            weekendStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
          enabledDayPredicate: (d) => !_isBlocked(d),
          selectedDayPredicate: _isSelected,
          onDaySelected: (day, focused) {
            setState(() => _focused = focused);
            _toggle(day);
          },
          onPageChanged: (f) => setState(() => _focused = f),
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (ctx, day, _) {
              final isPast = _norm(day).isBefore(_norm(DateTime.now()));
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.transparent
                        : cs.errorContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: cs.outline,
                      decoration: isPast
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            },
            selectedBuilder: (ctx, day, _) => Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('${day.day}',
                    style: TextStyle(
                        color: cs.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
            todayBuilder: (ctx, day, _) => Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: cs.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text('${day.day}',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _LegendDot(color: cs.primary, label: 'Selected'),
              const SizedBox(width: 12),
              _LegendDot(
                  color: cs.errorContainer, label: 'Unavailable', bordered: true),
              const SizedBox(width: 12),
              _LegendDot(
                  color: Colors.transparent,
                  label: 'Available',
                  bordered: true,
                  borderColor: cs.outlineVariant),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  final Color? borderColor;
  const _LegendDot({
    required this.color,
    required this.label,
    this.bordered = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: bordered
                ? Border.all(
                    color: borderColor ?? Theme.of(context).colorScheme.outline)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
