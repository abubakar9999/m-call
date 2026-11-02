import 'dart:async';

import 'package:flutter/material.dart';

import '../models/busy_mode.dart';

/// A banner displayed at the top of the home screen when a mode is active.
///
/// Shows the mode name, icon (with a pulsing animation), a live countdown
/// timer, and a "Stop" button.
class ActiveModeBanner extends StatefulWidget {
  const ActiveModeBanner({
    super.key,
    required this.mode,
    required this.onStop,
  });

  final BusyMode mode;
  final VoidCallback onStop;

  @override
  State<ActiveModeBanner> createState() => _ActiveModeBannerState();
}

class _ActiveModeBannerState extends State<ActiveModeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the icon.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _computeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    final end = widget.mode.endTime;
    if (end == null) {
      _remaining = Duration(minutes: widget.mode.durationMinutes);
    } else {
      final diff = end.difference(DateTime.now());
      _remaining = diff.isNegative ? Duration.zero : diff;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              // Pulsing icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Text(
                  widget.mode.icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(width: 16),
              // Mode name + countdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.mode.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCountdown(_remaining),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stop button
              FilledButton.icon(
                onPressed: widget.onStop,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: const Text('Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
