import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../models/venue_unit.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/multi_date_calendar.dart';
import '../../widgets/settings_sheet.dart';
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
    final s = S.of(context);
    if (!_form.currentState!.validate()) return;
    if (_unitIds.isEmpty) {
      _snack(s.pickAtLeastOneUnit);
      return;
    }
    if (_dates.isEmpty) {
      _snack(s.pickAtLeastOneDate);
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
          title: Text(s.reservationSubmitted),
          content: Text(
            s.reservationSubmittedDetail(_dates.length),
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // back to venue detail
                Navigator.of(context).pop(); // back to discover
              },
              child: Text(s.done),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('${s.failedToSubmit}: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.reserveDates),
        actions: const [SettingsAppBarAction()],
      ),
      body: StreamBuilder<List<Venue>>(
        stream: context.read<VenueProvider>().watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const LoadingView();
          final venue = snap.data!
              .where((v) => v.id == widget.venueId)
              .cast<Venue?>()
              .firstWhere((_) => true, orElse: () => null);
          if (venue == null) {
            return EmptyView(
              icon: Icons.error_outline,
              title: s.venueNotFound,
              message: s.venueNotFoundHint,
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
                          title: s.stepPickUnits,
                          hint: s.stepPickUnitsHint),
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
                        title: s.stepPickDates,
                        hint: _unitIds.isEmpty
                            ? s.stepPickDatesHintPickUnits
                            : s.stepPickDatesHintTap,
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
                        title: s.stepContactDetails,
                        hint: s.stepContactDetailsHint,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: s.fullName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? s.required : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: s.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 6) ? s.invalidPhone : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return s.required;
                          if (!v.contains('@')) return s.invalidEmail;
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
                        label: Text(s.confirmReservation),
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
    final s = S.of(context);
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
                Text(s.reservationSummary,
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(
                  s.reservationSummaryLine(unitCount, dayCount),
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
