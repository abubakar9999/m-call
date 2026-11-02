import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular countdown timer widget.
///
/// Displays a circular progress indicator with the remaining time (MM:SS) in
/// the centre and the mode name below. The progress colour transitions from
/// green → yellow → red as time runs out.
class CountdownTimerWidget extends StatefulWidget {
  const CountdownTimerWidget({
    super.key,
    required this.totalDuration,
    required this.modeName,
    this.endTime,
    this.size = 200,
  });

  /// Total duration of the mode.
  final Duration totalDuration;

  /// Display name of the active mode.
  final String modeName;

  /// Absolute end time. If provided, used to compute the remaining duration
  /// rather than counting down from [totalDuration].
  final DateTime? endTime;

  /// Diameter of the circle.
  final double size;

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    if (widget.endTime != null) {
      final diff = widget.endTime!.difference(DateTime.now());
      _remaining = diff.isNegative ? Duration.zero : diff;
    } else {
      _remaining = widget.totalDuration;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Colour transitions: green → yellow → red
  // ---------------------------------------------------------------------------

  Color _progressColor() {
    final total = widget.totalDuration.inSeconds;
    if (total == 0) return Colors.green;
    final fraction = _remaining.inSeconds / total; // 1.0 → 0.0
    if (fraction > 0.5) return const Color(0xFF4CAF50); // green
    if (fraction > 0.2) return const Color(0xFFFFC107); // amber
    return const Color(0xFFF44336); // red
  }

  String _formatTime(Duration d) {
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
    final theme = Theme.of(context);
    final total = widget.totalDuration.inSeconds;
    final progress = total > 0 ? _remaining.inSeconds / total : 0.0;
    final color = _progressColor();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              color: color.withValues(alpha: 0.15),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Animated progress ring
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => CustomPaint(
                painter: _ArcPainter(
                  progress: value,
                  color: color,
                  strokeWidth: 10,
                ),
              ),
            ),
          ),

          // Centre text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_remaining),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.modeName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws a rounded arc for the progress ring.
class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from 12 o'clock (-π/2) and sweep clockwise.
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
