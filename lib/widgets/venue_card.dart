import 'package:flutter/material.dart';

import '../models/venue.dart';

class VenueCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.venue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: venue.imageUrl.isEmpty
                      ? Container(
                          color: cs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_outlined,
                              size: 48, color: cs.outline),
                        )
                      : Image.network(
                          venue.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image_outlined,
                                size: 48, color: cs.outline),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: cs.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        ),
                ),
                if (!venue.isPublic)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _Badge(
                      color: cs.secondaryContainer,
                      textColor: cs.onSecondaryContainer,
                      icon: Icons.lock_rounded,
                      label: 'PIN',
                    ),
                  ),
                if (!venue.isApprovedByAdmin)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(
                      color: cs.errorContainer,
                      textColor: cs.onErrorContainer,
                      icon: Icons.hourglass_top,
                      label: 'Pending review',
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: cs.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Chip(icon: Icons.category_outlined, label: venue.category.label),
                      const SizedBox(width: 6),
                      _Chip(
                          icon: Icons.groups_2_outlined,
                          label: '${venue.maxCapacity} max'),
                      const Spacer(),
                      Text(
                        'From \$${venue.minPricePerDay.toStringAsFixed(0)}/day',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  const _Badge({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
