import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/venue.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/state_views.dart';
import 'reservation_screen.dart';

class VenueDetailScreen extends StatelessWidget {
  final String venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: StreamBuilder<List<Venue>>(
        stream: context.read<VenueProvider>().watchAll(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final venue = (snap.data ?? const <Venue>[])
              .where((v) => v.id == venueId)
              .cast<Venue?>()
              .firstWhere((_) => true, orElse: () => null);

          if (venue == null) {
            return const EmptyView(
              icon: Icons.sentiment_dissatisfied,
              title: 'Venue not found',
              message: 'This listing may have been removed by its owner.',
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(venue.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black45),
                          ])),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (venue.imageUrl.isNotEmpty)
                        Image.network(venue.imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                          return Container(color: cs.surfaceContainerHighest);
                        }),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 18, color: cs.outline),
                          const SizedBox(width: 6),
                          Expanded(child: Text(venue.location)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                              icon: Icons.category_outlined,
                              label: venue.category.label),
                          _InfoPill(
                              icon: Icons.groups_2_outlined,
                              label: 'Up to ${venue.maxCapacity} guests'),
                          _InfoPill(
                              icon: Icons.payments_outlined,
                              label:
                                  'From \$${venue.minPricePerDay.toStringAsFixed(0)}/day'),
                          if (!venue.isPublic)
                            const _InfoPill(
                                icon: Icons.lock_rounded,
                                label: 'Private'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('About this venue',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(venue.description,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      Text('Available Units',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final u in venue.units)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(Icons.meeting_room_outlined,
                                  color: cs.onPrimaryContainer),
                            ),
                            title: Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('Capacity: ${u.capacity} guests'),
                            trailing: Text(
                              '\$${u.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReservationScreen(venueId: venueId),
              ),
            ),
            icon: const Icon(Icons.event_available_rounded),
            label: const Text('Reserve dates'),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
