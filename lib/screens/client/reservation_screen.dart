import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../models/venue_unit.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/multi_date_calendar.dart';
import '../../widgets/state_views.dart';

/// Multi-date reservation flow. The client can:
///   1. Pick one or more units within a venue
///   2. Tap non-consecutive dates on the calendar (blocked dates are grayed)
///   3. Enter contact info
///   4. Submit a Pending Payment reservation
class ReservationScreen extends StatefulWidget {
  final String venueId;
  const ReservationScreen({super.key, required this.venueId});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final Set<String> _unitIds = {};
  final Set<DateTime> _dates = {};
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  double _computeTotal(Venue venue) {
    final selectedUnits =
        venue.units.where((u) => _unitIds.contains(u.unitId));
    final perDay = selectedUnits.fold<double>(0, (s, u) => s + u.pricePerDay);
    return perDay * _dates.length;
  }

  Future<void> _submit(Venue venue) async {
    if (!_form.currentState!.validate()) return;
    if (_unitIds.isEmpty) {
      _snack('Pick at least one unit to reserve.');
      return;
    }
    if (_dates.isEmpty) {
      _snack('Pick at least one date.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = Booking(
        id: 'bk-${DateTime.now().microsecondsSinceEpoch}',
        venueId: venue.id,
        unitIds: _unitIds.toList(),
        dates: _dates.toList()..sort(),
        clientName: _name.text.trim(),
        clientPhone: _phone.text.trim(),
        clientEmail: _email.text.trim(),
        status: BookingStatus.pending,
        totalPrice: _computeTotal(venue),
        createdAt: DateTime.now(),
      );
      await context.read<BookingProvider>().create(booking);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 56),
          title: const Text('Reservation submitted!'),
          content: Text(
            'Your booking for ${_dates.length} day(s) is marked as "Pending Payment". '
            'The venue owner will confirm and collect payment on arrival.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // back to venue detail
                Navigator.of(context).pop(); // back to discover
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserve dates')),
      body: StreamBuilder<List<Venue>>(
        stream: context.read<VenueProvider>().watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const LoadingView();
          final venue = snap.data!
              .where((v) => v.id == widget.venueId)
              .cast<Venue?>()
              .firstWhere((_) => true, orElse: () => null);
          if (venue == null) {
            return const EmptyView(
              icon: Icons.error_outline,
              title: 'Venue unavailable',
              message: 'This venue may have been removed.',
            );
          }

          final bookingProv = context.read<BookingProvider>();

          return StreamBuilder<List<Booking>>(
            stream: bookingProv.watchForVenue(venue.id),
            builder: (ctx, bSnap) {
              final bookings = bSnap.data ?? const <Booking>[];
              final blocked = bookingProv.service.computeBlockedDates(
                bookings: bookings,
                venueId: venue.id,
                unitIds: _unitIds,
              );

              // If the user has not picked units yet, show nothing as blocked
              // (we want them to pick units first for a correct availability
              // calculation). Prune invalid selected dates after this frame
              // without triggering a build-phase setState.
              if (_unitIds.isNotEmpty &&
                  _dates.any(blocked.contains)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _dates.removeWhere(blocked.contains));
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(venue.location,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline)),
                      const SizedBox(height: 20),
                      _SectionLabel(
                          number: 1,
                          title: 'Pick unit(s) to reserve',
                          hint:
                              'You can book several units together (e.g. Indoor Hall + Garden).'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final u in venue.units)
                            _UnitChip(
                              unit: u,
                              selected: _unitIds.contains(u.unitId),
                              onTap: () => setState(() {
                                if (_unitIds.contains(u.unitId)) {
                                  _unitIds.remove(u.unitId);
                                } else {
                                  _unitIds.add(u.unitId);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        number: 2,
                        title: 'Select dates',
                        hint: _unitIds.isEmpty
                            ? 'Pick units above to see live availability.'
                            : 'Tap each date you want. Non-consecutive dates allowed.',
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: MultiDateCalendar(
                            selectedDates: _dates,
                            blockedDates:
                                _unitIds.isEmpty ? const {} : blocked,
                            onChanged: (set) => setState(() {
                              _dates
                                ..clear()
                                ..addAll(set);
                            }),
                          ),
                        ),
                      ),
                      if (_dates.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final d in (_dates.toList()..sort()))
                              Chip(
                                avatar: const Icon(Icons.calendar_today,
                                    size: 14),
                                label: Text(DateFormat('EEE, MMM d')
                                    .format(d)),
                                onDeleted: () => setState(() => _dates.remove(d)),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionLabel(
                        number: 3,
                        title: 'Your contact details',
                        hint:
                            'The owner will use this to confirm your reservation.',
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 6) ? 'Invalid phone' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _SummaryCard(
                        total: _computeTotal(venue),
                        dayCount: _dates.length,
                        unitCount: _unitIds.length,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _submitting ? null : () => _submit(venue),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('Confirm reservation (Pay on-site)'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final VenueUnit unit;
  final bool selected;
  final VoidCallback onTap;
  const _UnitChip({
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.onPrimary : cs.onSurface,
                    )),
                Text(
                  'Cap ${unit.capacity} · \$${unit.pricePerDay.toStringAsFixed(0)}/day',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? cs.onPrimary.withOpacity(0.9)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final int number;
  final String title;
  final String? hint;
  const _SectionLabel({required this.number, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cs.primary,
          child: Text('$number',
              style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (hint != null)
                Text(hint!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final int dayCount;
  final int unitCount;
  const _SummaryCard({
    required this.total,
    required this.dayCount,
    required this.unitCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reservation summary',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(
                  '$unitCount unit(s) · $dayCount day(s) · Pay on-site',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
          Text('\$${total.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}
