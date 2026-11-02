import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/mode_provider.dart';
import '../widgets/quick_activate_fab.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// The root navigation shell that hosts the bottom navigation tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<ModeProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final todayCount = historyProvider.todayCount;

    final screens = [
      HomeScreen(
        onNavigateToHistory: () => setState(() => _currentIndex = 1),
      ),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0 && modeProvider.modes.isNotEmpty
          ? QuickActivateFab(
              modes: modeProvider.modes,
              onModeSelected: (mode) => modeProvider.activateMode(mode),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text('$todayCount'),
              child: const Icon(Icons.history_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text('$todayCount'),
              child: const Icon(Icons.history),
            ),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

