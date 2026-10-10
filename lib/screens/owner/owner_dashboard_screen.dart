import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/state_views.dart';
import '../auth/login_screen.dart';
import '../client/discover_screen.dart';
import 'owner_bookings_calendar.dart';
import 'owner_venue_edit_screen.dart';

/// Three-tab dashboard: My Venues | Bookings | Agenda
class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.user;
    final s = S.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Owner · ${me?.displayName ?? me?.email ?? ''}'),
          actions: [
            const SettingsAppBarAction(),
            IconButton(
              tooltip: s.browseAsClient,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiscoverScreen()),
              ),
              icon: const Icon(Icons.explore_outlined),
            ),
            IconButton(
              tooltip: s.signOut,
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(icon: const Icon(Icons.store_outlined), text: s.myVenues),
            Tab(icon: const Icon(Icons.inbox_outlined), text: s.bookings),
            Tab(icon: const Icon(Icons.calendar_month_outlined), text: s.agenda),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OwnerVenueEditScreen(ownerId: me!.uid),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(s.newVenue),
        ),
        body: TabBarView(
          children: [
            _MyVenuesTab(ownerId: me!.uid),
            _BookingsTab(ownerId: me.uid),
            _AgendaTab(ownerId: me.uid),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Tab 1 — My venues

class _MyVenuesTab extends StatelessWidget {
  final String ownerId;
  const _MyVenuesTab({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    final venueProv = context.read<VenueProvider>();
    return StreamBuilder<List<Venue>>(
      stream: venueProv.watchForOwner(ownerId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingView();
        final venues = snap.data!;
        if (venues.isEmpty) {
          return EmptyView(
            icon: Icons.add_business_outlined,
            title: 'No venues yet',
            message:
                'Add your first venue, define its units (indoor hall, outdoor area, etc.) and clients can start booking it.',
            action: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => OwnerVenueEditScreen(ownerId: ownerId)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create first venue'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: venues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final v = venues[i];
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.event_available_outlined),
                ),
                title: Text(v.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.location),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniBadge(
                          text: v.isApprovedByAdmin ? 'Approved' : 'Pending review',
                          color: v.isApprovedByAdmin
                              ? Colors.green
                              : Colors.orange,
                        ),
                        _MiniBadge(
                          text: v.isPublic ? 'Public' : 'Private · PIN',
                          color: v.isPublic ? Colors.blue : Colors.deepPurple,
                        ),
                        _MiniBadge(
                          text: '${v.units.length} unit(s)',
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (sel) async {
                    if (sel == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => OwnerVenueEditScreen(
                              ownerId: ownerId, existing: v)));
                    } else if (sel == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete venue?'),
                          content: Text(
                              'This will delete "${v.title}" and all its bookings. This cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                    foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) await venueProv.delete(v.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OwnerVenueEditScreen(ownerId: ownerId, existing: v),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------------------
// Tab 2 — Incoming bookings list

class _BookingsTab extends StatelessWidget {
  final String ownerId;
  const _BookingsTab({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venue>>(
      stream: context.read<VenueProvider>().watchForOwner(ownerId),
      builder: (ctx, vSnap) {
        if (!vSnap.hasData) return const LoadingView();
        final venueIds = vSnap.data!.map((v) => v.id).toSet();
        final venueMap = {for (final v in vSnap.data!) v.id: v};

        return StreamBuilder<List<Booking>>(
          stream: context.read<BookingProvider>().watchAll(),
          builder: (ctx, bSnap) {
            if (!bSnap.hasData) return const LoadingView();
            final mine = bSnap.data!
                .where((b) => venueIds.contains(b.venueId))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (mine.isEmpty) {
              return const EmptyView(
                icon: Icons.inbox_outlined,
                title: 'No bookings yet',
                message:
                    'When clients reserve your venues, their requests will show up here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: mine.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final b = mine[i];
                final v = venueMap[b.venueId];
                return _BookingTile(booking: b, venueName: v?.title ?? '—');
              },
            );
          },
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final String venueName;
  const _BookingTile({required this.booking, required this.venueName});

  Color _statusColor(BuildContext ctx) {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Theme.of(ctx).colorScheme.error;
      case BookingStatus.pending:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final datesStr = booking.dates.length <= 3
        ? booking.dateStrings.join(', ')
        : '${booking.dateStrings.take(3).join(', ')} +${booking.dates.length - 3}';

    final bookingProv = context.read<BookingProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.clientName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _MiniBadge(
                    text: booking.status.label, color: _statusColor(context)),
              ],
            ),
            const SizedBox(height: 4),
            Text(venueName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_month_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(datesStr)),
              Text('\$${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 16),
              const SizedBox(width: 6),
              Text(booking.clientPhone),
              const SizedBox(width: 12),
              const Icon(Icons.mail_outline, size: 16),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(booking.clientEmail,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                if (booking.status != BookingStatus.confirmed)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => bookingProv.updateStatus(
                          booking.id, BookingStatus.confirmed),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirm'),
                    ),
                  ),
                if (booking.status != BookingStatus.confirmed)
                  const SizedBox(width: 8),
                if (booking.status != BookingStatus.cancelled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => bookingProv.updateStatus(
                          booking.id, BookingStatus.cancelled),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'),
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

// -------------------------------------------------------------------------
// Tab 3 — Monthly agenda calendar

class _AgendaTab extends StatelessWidget {
  final String ownerId;
  const _AgendaTab({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venue>>(
      stream: context.read<VenueProvider>().watchForOwner(ownerId),
      builder: (ctx, vSnap) {
        if (!vSnap.hasData) return const LoadingView();
        final venueMap = {for (final v in vSnap.data!) v.id: v};
        return StreamBuilder<List<Booking>>(
          stream: context.read<BookingProvider>().watchAll(),
          builder: (ctx, bSnap) {
            if (!bSnap.hasData) return const LoadingView();
            final mine = bSnap.data!
                .where((b) => venueMap.containsKey(b.venueId))
                .toList();
            return OwnerBookingsCalendar(bookings: mine, venues: venueMap);
          },
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
