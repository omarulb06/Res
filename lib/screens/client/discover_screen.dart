import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/venue.dart';
import '../../providers/auth_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/settings_sheet.dart';
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

  String _categoryLabel(S s, VenueCategory c) => switch (c) {
        VenueCategory.indoor => s.categoryIndoor,
        VenueCategory.outdoor => s.categoryOutdoor,
        VenueCategory.mixed => s.categoryMixed,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final auth = context.watch<AuthProvider>();
    final venueProv = context.read<VenueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.discoverVenues),
        actions: [
          const SettingsAppBarAction(),
          if (auth.user == null)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login_rounded),
              label: Text(s.signIn),
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
                  child: Text('${s.signedInAs} ${auth.user!.email}'),
                ),
                PopupMenuItem(value: 'signout', child: Text(s.signOut)),
              ],
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
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
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
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
                      label: Text(_categoryLabel(s, cat)),
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
                        ? s.anyCapacity
                        : '${s.capacityAtLeast} $_minCapacity'),
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
                  return LoadingView(label: s.loadingVenues);
                }
                if (snap.hasError) {
                  return ErrorView(message: '${s.failedToLoadVenues}:\n${snap.error}');
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
                  return EmptyView(
                    icon: Icons.search_off_rounded,
                    title: s.noVenuesMatch,
                    message: s.noVenuesMatchHint,
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
    final s = S.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.minCapacity,
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              _val == 0 ? s.any : '≥ ${_val.toInt()} ${s.guests}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Slider(
              value: _val,
              min: 0,
              max: 1000,
              divisions: 20,
              label: _val == 0 ? s.any : _val.toInt().toString(),
              onChanged: (v) => setState(() => _val = v),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 0),
                    child: Text(s.clear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _val.toInt()),
                    child: Text(s.apply),
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
