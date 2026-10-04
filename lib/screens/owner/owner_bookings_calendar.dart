import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/booking.dart';
import '../../models/venue.dart';

/// Monthly agenda calendar for an owner showing all bookings across their
/// venues. Taps on a day reveal the per-unit breakdown.
class OwnerBookingsCalendar extends StatefulWidget {
  final List<Booking> bookings;
  final Map<String, Venue> venues;
  const OwnerBookingsCalendar({
    super.key,
    required this.bookings,
    required this.venues,
  });

  @override
  State<OwnerBookingsCalendar> createState() => _OwnerBookingsCalendarState();
}

class _OwnerBookingsCalendarState extends State<OwnerBookingsCalendar> {
  late DateTime _focused;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _focused = DateTime.now();
    _selected = DateTime(_focused.year, _focused.month, _focused.day);
  }

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<Booking>> get _bookingsByDate {
    final map = <DateTime, List<Booking>>{};
    for (final b in widget.bookings) {
      if (b.status == BookingStatus.cancelled) continue;
      for (final d in b.dates) {
        final key = _norm(d);
        map.putIfAbsent(key, () => []).add(b);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final byDate = _bookingsByDate;

    final selectedList = _selected == null ? <Booking>[] : (byDate[_selected] ?? []);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
              focusedDay: _focused,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              selectedDayPredicate: (d) =>
                  _selected != null && isSameDay(d, _selected),
              onDaySelected: (d, f) => setState(() {
                _focused = f;
                _selected = _norm(d);
              }),
              onPageChanged: (f) => setState(() => _focused = f),
              eventLoader: (d) => byDate[_norm(d)] ?? const [],
              calendarBuilders: CalendarBuilders(
                markerBuilder: (ctx, d, events) {
                  if (events.isEmpty) return const SizedBox();
                  final count = events.length;
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: selectedList.isEmpty
              ? Center(
                  child: Text(
                    _selected == null
                        ? 'Pick a day to see bookings.'
                        : 'No bookings on ${DateFormat('EEE, MMM d').format(_selected!)}.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.outline),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: selectedList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final b = selectedList[i];
                    final v = widget.venues[b.venueId];
                    final unitNames = (v?.units ?? [])
                        .where((u) => b.unitIds.contains(u.unitId))
                        .map((u) => u.name)
                        .join(', ');
                    return ListTile(
                      tileColor: cs.surfaceContainerHighest.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: b.status == BookingStatus.confirmed
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        child: Icon(
                          b.status == BookingStatus.confirmed
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          color: b.status == BookingStatus.confirmed
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(b.clientName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${v?.title ?? ''} · $unitNames'),
                      trailing: Text('\$${b.totalPrice.toStringAsFixed(0)}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
