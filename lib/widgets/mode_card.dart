import 'package:flutter/material.dart';

import '../models/busy_mode.dart';

/// A Material 3 card for displaying a single [BusyMode].
///
/// Shows the mode's icon, name, status indicator, message preview, duration
/// badge, and a toggle switch. Tapping the card body opens the mode detail
/// screen for editing.
class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.mode,
    required this.onToggle,
    required this.onTap,
  });

  final BusyMode mode;

  /// Called when the user flips the activation switch.
  final ValueChanged<bool> onToggle;

  /// Called when the user taps the card body to edit the mode.
  final VoidCallback onTap;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const _radius = 16.0;
  static const _activeBorderColor = Color(0xFF2E7D32);
  static const _activeGlowColor = Color(0x2A4CAF50);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = mode.isActive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: isActive ? _activeBorderColor : colorScheme.outlineVariant,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _activeGlowColor,
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------ Top row: Icon + Status dot + Switch ------
                Row(
                  children: [
                    // Mode emoji icon
                    Text(
                      mode.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    // Status dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(),
                    // Toggle switch
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: isActive,
                        activeThumbColor: const Color(0xFF00695C),
                        onChanged: onToggle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ------ Mode name ------
                Text(
                  mode.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // ------ Message preview ------
                Text(
                  mode.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // ------ Duration badge ------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF00695C).withValues(alpha: 0.12)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(mode.durationMinutes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? const Color(0xFF00695C)
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
