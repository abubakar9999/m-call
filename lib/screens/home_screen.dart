import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/mode_provider.dart';
import '../providers/prayer_provider.dart';
import '../widgets/active_mode_banner.dart';
import '../widgets/call_log_tile.dart';
import '../widgets/mode_card.dart';
import '../widgets/prayer_time_card.dart';
import 'mode_detail_screen.dart';

/// The main dashboard screen of M Call.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateToHistory,
  });

  /// Callback to switch to the history tab in the main shell.
  final VoidCallback onNavigateToHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    final modeProvider = context.watch<ModeProvider>();
    final prayerProvider = context.watch<PrayerProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    final activeMode = modeProvider.activeMode;
    final modes = modeProvider.modes;
    final prayerTimes = prayerProvider.todayPrayers;
    final recentLogs = historyProvider.entries.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'M Call',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Custom Mode',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ModeDetailScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await prayerProvider.refreshPrayerTimes();
          await historyProvider.loadHistory();
          await modeProvider.loadModes();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Active Mode Banner or Free Status ──
            if (activeMode != null) ...[
              ActiveModeBanner(
                mode: activeMode,
                onStop: () => modeProvider.deactivateMode(),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.6),
                      colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('✨', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You're Available",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All incoming calls ring normally. Tap any mode below when busy.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Prayer Times Section (Namaz) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🕌 ', style: TextStyle(fontSize: 18)),
                    Text(
                      'Prayer Times Today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (prayerProvider.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () => prayerProvider.refreshPrayerTimes(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (prayerTimes != null)
              SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: prayerTimes.all.map((prayer) {
                    return PrayerTimeCard(
                      prayer: prayer,
                      onToggle: (enabled) {
                        // When user toggles a prayer time
                      },
                    );
                  }).toList(),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap refresh to compute today\'s prayer times from your location.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => prayerProvider.loadPrayerTimes(),
                      child: const Text('Locate'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Modes Grid Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Busy Modes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ModeDetailScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Mode'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mode Cards List
            ...modes.map((mode) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ModeCard(
                  mode: mode,
                  onToggle: (activate) {
                    if (activate) {
                      modeProvider.activateMode(mode);
                    } else {
                      modeProvider.deactivateMode();
                    }
                  },
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModeDetailScreen(mode: mode),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 20),

            // ── Recent Activity Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Auto-Replies',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recentLogs.isNotEmpty)
                  TextButton(
                    onPressed: onNavigateToHistory,
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentLogs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.mark_chat_unread_outlined,
                      size: 36,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No auto-replies sent yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When callers reach you during a busy mode, logs will appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentLogs.map((entry) => CallLogTile(entry: entry)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

