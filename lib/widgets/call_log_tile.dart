import 'package:flutter/material.dart';

import '../models/call_log_entry.dart';

/// A list tile for showing one call-log entry with the caller info, platform
/// icon, mode badge, relative timestamp, and message preview.
class CallLogTile extends StatelessWidget {
  const CallLogTile({super.key, required this.entry});

  final CallLogEntry entry;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  IconData _platformIcon(CallPlatform p) {
    switch (p) {
      case CallPlatform.phone:
        return Icons.phone;
      case CallPlatform.whatsapp:
        return Icons.chat;
      case CallPlatform.messenger:
        return Icons.messenger;
    }
  }

  Color _platformColor(CallPlatform p) {
    switch (p) {
      case CallPlatform.phone:
        return const Color(0xFF00695C);
      case CallPlatform.whatsapp:
        return const Color(0xFF25D366);
      case CallPlatform.messenger:
        return const Color(0xFF0084FF);
    }
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pColor = _platformColor(entry.platform);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform icon circle
          CircleAvatar(
            radius: 22,
            backgroundColor: pColor.withValues(alpha: 0.12),
            child: Icon(_platformIcon(entry.platform), color: pColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _relativeTime(entry.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Mode badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.modeName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF00695C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Message preview
                Text(
                  entry.messageSent,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
