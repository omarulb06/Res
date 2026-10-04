import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../models/venue.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/state_views.dart';
import '../auth/login_screen.dart';
import '../client/discover_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin · ${auth.user?.displayName ?? ''}'),
          actions: [
            IconButton(
              tooltip: 'Browse as client',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiscoverScreen()),
              ),
              icon: const Icon(Icons.explore_outlined),
            ),
            IconButton(
              tooltip: 'Sign out',
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
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.insights_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Approvals'),
            Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Users'),
          ]),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _ApprovalsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Overview

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venue>>(
      stream: context.read<VenueProvider>().watchAll(),
      builder: (ctx, vSnap) {
        return StreamBuilder<List<Booking>>(
          stream: context.read<BookingProvider>().watchAll(),
          builder: (ctx, bSnap) {
            return StreamBuilder<List<AppUser>>(
              stream: context.read<AuthProvider>().watchAllUsers(),
              builder: (ctx, uSnap) {
                if (!vSnap.hasData || !bSnap.hasData || !uSnap.hasData) {
                  return const LoadingView();
                }
                final venues = vSnap.data!;
                final bookings = bSnap.data!;
                final users = uSnap.data!;

                final totalRevenue = bookings
                    .where((b) => b.status == BookingStatus.confirmed)
                    .fold<double>(0, (s, b) => s + b.totalPrice);
                final activeBookings = bookings
                    .where((b) =>
                        b.status != BookingStatus.cancelled &&
                        b.dates.any((d) => d.isAfter(DateTime.now()
                            .subtract(const Duration(days: 1)))))
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Platform metrics',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _MetricCard(
                          icon: Icons.store_outlined,
                          label: 'Total venues',
                          value: '${venues.length}',
                        ),
                        _MetricCard(
                          icon: Icons.event_available_outlined,
                          label: 'Active bookings',
                          value: '$activeBookings',
                        ),
                        _MetricCard(
                          icon: Icons.payments_outlined,
                          label: 'Confirmed revenue',
                          value: '\$${totalRevenue.toStringAsFixed(0)}',
                        ),
                        _MetricCard(
                          icon: Icons.people_alt_outlined,
                          label: 'Registered users',
                          value: '${users.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Pending approvals',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _PendingPreview(venues: venues),
                    const SizedBox(height: 24),
                    Text('Latest activity',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _ActivityPreview(bookings: bookings, venues: venues),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const Spacer(),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    )),
          ],
        ),
      ),
    );
  }
}

class _PendingPreview extends StatelessWidget {
  final List<Venue> venues;
  const _PendingPreview({required this.venues});

  @override
  Widget build(BuildContext context) {
    final pending = venues.where((v) => !v.isApprovedByAdmin).toList();
    if (pending.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('All venues approved'),
        ),
      );
    }
    return Column(
      children: [
        for (final v in pending.take(3))
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.hourglass_top, color: Colors.white),
              ),
              title: Text(v.title),
              subtitle: Text(v.location),
              trailing: FilledButton.tonal(
                onPressed: () =>
                    context.read<VenueProvider>().approve(v.id, true),
                child: const Text('Approve'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  final List<Booking> bookings;
  final List<Venue> venues;
  const _ActivityPreview({required this.bookings, required this.venues});

  @override
  Widget build(BuildContext context) {
    final recent = [...bookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sliced = recent.take(5).toList();
    if (sliced.isEmpty) {
      return const Card(
          child: ListTile(
              leading: Icon(Icons.insights_outlined),
              title: Text('No activity yet')));
    }
    final venueMap = {for (final v in venues) v.id: v};
    return Column(
      children: [
        for (final b in sliced)
          Card(
            child: ListTile(
              leading: Icon(
                b.status == BookingStatus.confirmed
                    ? Icons.check_circle_outline
                    : b.status == BookingStatus.cancelled
                        ? Icons.cancel_outlined
                        : Icons.schedule_outlined,
                color: b.status == BookingStatus.confirmed
                    ? Colors.green
                    : b.status == BookingStatus.cancelled
                        ? Colors.red
                        : Colors.orange,
              ),
              title: Text(
                  '${b.clientName} · ${venueMap[b.venueId]?.title ?? '—'}'),
              subtitle: Text('${b.dates.length} day(s) · ${b.status.label}'),
              trailing: Text('\$${b.totalPrice.toStringAsFixed(0)}'),
            ),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// Approvals

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Venue>>(
      stream: context.read<VenueProvider>().watchAll(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingView();
        final venues = snap.data!;
        if (venues.isEmpty) {
          return const EmptyView(
            icon: Icons.verified_outlined,
            title: 'Nothing to review',
            message: 'When owners submit venues, they will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: venues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final v = venues[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(v.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        Switch(
                          value: v.isApprovedByAdmin,
                          onChanged: (val) =>
                              context.read<VenueProvider>().approve(v.id, val),
                        ),
                      ],
                    ),
                    Text(v.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            )),
                    const SizedBox(height: 6),
                    Text(v.description,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final u in v.units)
                          Chip(label: Text('${u.name} · ${u.capacity}')),
                      ],
                    ),
                  ],
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
// Users

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return StreamBuilder<List<AppUser>>(
      stream: auth.watchAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingView();
        final users = snap.data!..sort((a, b) => a.email.compareTo(b.email));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final u = users[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (u.displayName ?? u.email).characters.first.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(u.displayName ?? u.email,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(u.email),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    DropdownButton<UserRole>(
                      value: u.role,
                      underline: const SizedBox(),
                      onChanged: (r) {
                        if (r != null) auth.changeUserRole(u.uid, r);
                      },
                      items: const [
                        DropdownMenuItem(
                            value: UserRole.client, child: Text('Client')),
                        DropdownMenuItem(
                            value: UserRole.owner, child: Text('Owner')),
                        DropdownMenuItem(
                            value: UserRole.admin, child: Text('Admin')),
                      ],
                    ),
                    IconButton(
                      tooltip: u.suspended ? 'Reactivate' : 'Suspend',
                      icon: Icon(u.suspended
                          ? Icons.lock_open_outlined
                          : Icons.block_outlined),
                      onPressed: () =>
                          auth.setUserSuspended(u.uid, !u.suspended),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
