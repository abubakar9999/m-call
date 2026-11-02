import 'package:flutter/material.dart';

import '../models/busy_mode.dart';

/// A FloatingActionButton that expands into a speed-dial showing all available
/// modes. Tapping a mode icon triggers immediate activation.
class QuickActivateFab extends StatefulWidget {
  const QuickActivateFab({
    super.key,
    required this.modes,
    required this.onModeSelected,
  });

  final List<BusyMode> modes;
  final ValueChanged<BusyMode> onModeSelected;

  @override
  State<QuickActivateFab> createState() => _QuickActivateFabState();
}

class _QuickActivateFabState extends State<QuickActivateFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inactiveModes =
        widget.modes.where((m) => !m.isActive).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed-dial items
        if (_isExpanded)
          ...inactiveModes.map((mode) {
            final idx = inactiveModes.indexOf(mode);
            return TweenAnimationBuilder<double>(
              key: ValueKey(mode.id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + idx * 50),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        mode.name,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini-FAB
                    FloatingActionButton.small(
                      heroTag: 'fab_mode_${mode.id}',
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _toggle();
                        widget.onModeSelected(mode);
                      },
                      child: Text(mode.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            );
          }),

        // Main FAB
        FloatingActionButton(
          heroTag: 'fab_main',
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _controller.value * 0.75 * 3.14159,
              child: Icon(
                _isExpanded ? Icons.close : Icons.flash_on_rounded,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
