import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/venue.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/state_views.dart';
import '../../widgets/venue_card.dart';
import '../auth/login_screen.dart';
import 'venue_detail_screen.dart';

/// Public venue discovery grid. Also used as the landing page for guests.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _query = '';
  final Set<VenueCategory> _categoryFilter = {};
  int _minCapacity = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final venueProv = context.read<VenueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Venues'),
        actions: [
          if (auth.user == null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign in'),
            )
          else
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'signout') {
                  await context.read<AuthProvider>().signOut();
                  if (!mounted) return;
                  setState(() {});
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'profile',
                  enabled: false,
                  child: Text('Signed in as ${auth.user!.email}'),
                ),
                const PopupMenuItem(value: 'signout', child: Text('Sign out')),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (auth.user!.displayName ?? auth.user!.email)
                        .characters
                        .first
                        .toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search venues or locations…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final cat in VenueCategory.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(cat.label),
                      selected: _categoryFilter.contains(cat),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _categoryFilter.add(cat);
                        } else {
                          _categoryFilter.remove(cat);
                        }
                      }),
                    ),
                  ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: const Icon(Icons.groups_outlined, size: 18),
                    label: Text(_minCapacity == 0
                        ? 'Any capacity'
                        : 'Capacity ≥ $_minCapacity'),
                    onPressed: () async {
                      final v = await showModalBottomSheet<int>(
                        context: context,
                        builder: (_) => _CapacityPicker(initial: _minCapacity),
                      );
                      if (v != null) setState(() => _minCapacity = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Venue>>(
              stream: venueProv.watchAll(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingView(label: 'Loading venues…');
                }
                if (snap.hasError) {
                  return ErrorView(message: 'Failed to load venues:\n${snap.error}');
                }
                final all = snap.data ?? const <Venue>[];
                final filtered = all.where((v) {
                  if (!v.isApprovedByAdmin) return false;
                  if (_query.trim().isNotEmpty) {
                    final q = _query.toLowerCase();
                    if (!v.title.toLowerCase().contains(q) &&
                        !v.location.toLowerCase().contains(q)) {
                      return false;
                    }
                  }
                  if (_categoryFilter.isNotEmpty &&
                      !_categoryFilter.contains(v.category)) {
                    return false;
                  }
                  if (v.maxCapacity < _minCapacity) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No venues match',
                    message:
                        'Try clearing filters or searching for a different name or location.',
                  );
                }

                return LayoutBuilder(
                  builder: (ctx, cons) {
                    final cross = cons.maxWidth > 1200
                        ? 4
                        : cons.maxWidth > 900
                            ? 3
                            : cons.maxWidth > 600
                                ? 2
                                : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (ctx, i) {
                        final v = filtered[i];
                        return VenueCard(
                          venue: v,
                          onTap: () => _openVenue(context, v),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openVenue(BuildContext context, Venue v) async {
    if (!v.isPublic) {
      final code = v.accessCode ?? '';
      final ok = await PinDialog.prompt(
        context,
        venueTitle: v.title,
        expectedCode: code,
      );
      if (!ok) return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: v.id)),
    );
  }
}

class _CapacityPicker extends StatefulWidget {
  final int initial;
  const _CapacityPicker({required this.initial});

  @override
  State<_CapacityPicker> createState() => _CapacityPickerState();
}

class _CapacityPickerState extends State<_CapacityPicker> {
  late double _val;

  @override
  void initState() {
    super.initState();
    _val = widget.initial.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Minimum capacity',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              _val == 0 ? 'Any' : '≥ ${_val.toInt()} guests',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Slider(
              value: _val,
              min: 0,
              max: 1000,
              divisions: 20,
              label: _val == 0 ? 'Any' : _val.toInt().toString(),
              onChanged: (v) => setState(() => _val = v),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 0),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _val.toInt()),
                    child: const Text('Apply'),
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
