import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prayer_time.dart';

/// A compact card displaying a single prayer time with its name, time, and
/// an enable/disable toggle.
class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.prayer,
    required this.onToggle,
  });

  final PrayerTimeData prayer;

  /// Called when the user toggles auto-reply for this prayer.
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormat = DateFormat.jm(); // e.g. "5:30 AM"

    final isHighlighted = prayer.isActive || prayer.isUpcoming;
    final isCurrentlyActive = prayer.isActive;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentlyActive
              ? const Color(0xFF4CAF50)
              : isHighlighted
                  ? const Color(0xFF00695C).withValues(alpha: 0.4)
                  : colorScheme.outlineVariant,
          width: isCurrentlyActive ? 2 : 1,
        ),
        color: isCurrentlyActive
            ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
            : colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prayer name
            Text(
              prayer.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isCurrentlyActive
                    ? const Color(0xFF2E7D32)
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),

            // Time
            Text(
              timeFormat.format(prayer.time),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),

            // Duration label
            Text(
              '${prayer.durationMinutes} min',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),

            const Spacer(),

            // Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isCurrentlyActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Transform.scale(
                  scale: 0.7,
                  child: Switch.adaptive(
                    value: prayer.enabled,
                    activeThumbColor: const Color(0xFF00695C),
                    onChanged: onToggle,
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
