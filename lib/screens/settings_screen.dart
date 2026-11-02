import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/call_service.dart';
import '../utils/constants.dart';

/// Screen for configuring application settings, permissions, and preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await Future.wait([
      Permission.phone.status,
      Permission.sms.status,
      Permission.location.status,
      Permission.notification.status,
    ]);

    if (mounted) {
      setState(() {
        _permissionStatuses = {
          Permission.phone: statuses[0],
          Permission.sms: statuses[1],
          Permission.location: statuses[2],
          Permission.notification: statuses[3],
        };
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (mounted) {
      setState(() {
        _permissionStatuses[permission] = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Platform Auto-Reply Toggles ──
          _SectionHeader(title: 'Auto-Reply Platforms'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.phone, color: Color(0xFF00695C)),
                  title: const Text('Phone Calls (SMS)'),
                  subtitle: const Text('Auto-reject and send SMS reply'),
                  value: settings.phoneAutoReply,
                  onChanged: (val) {
                    settingsProvider.updateSettings(
                      settings.copyWith(phoneAutoReply: val),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('WhatsApp Calls'),
                  subtitle: const Text('Auto-reply to WhatsApp call notifications'),
                  value: settings.whatsappAutoReply,
                  onChanged: (val) {
                    settingsProvider.updateSettings(
                      settings.copyWith(whatsappAutoReply: val),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.messenger, color: Color(0xFF0084FF)),
                  title: const Text('Messenger Calls'),
                  subtitle: const Text('Auto-reply to Messenger call notifications'),
                  value: settings.messengerAutoReply,
                  onChanged: (val) {
                    settingsProvider.updateSettings(
                      settings.copyWith(messengerAutoReply: val),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Prayer Settings ──
          _SectionHeader(title: 'Namaz Calculation'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mosque, color: Color(0xFF00695C)),
                title: const Text('Calculation Method'),
                subtitle: Text(
                  _methodLabel(settings.calculationMethod),
                  style: theme.textTheme.bodySmall,
                ),
                trailing: DropdownButton<String>(
                  value: settings.calculationMethod,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'karachi', child: Text('Karachi')),
                    DropdownMenuItem(
                      value: 'muslimWorldLeague',
                      child: Text('Muslim World League'),
                    ),
                    DropdownMenuItem(
                      value: 'northAmerica',
                      child: Text('ISNA (North America)'),
                    ),
                    DropdownMenuItem(value: 'egyptian', child: Text('Egyptian')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      settingsProvider.updateSettings(
                        settings.copyWith(calculationMethod: val),
                      );
                      context.read<PrayerProvider>().loadPrayerTimes();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Appearance & Notifications ──
          _SectionHeader(title: 'Preferences'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: settings.darkMode,
                  onChanged: (val) => settingsProvider.toggleDarkMode(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Show Notifications'),
                  subtitle: const Text('Status updates and missed call alerts'),
                  value: settings.showNotifications,
                  onChanged: (val) {
                    settingsProvider.updateSettings(
                      settings.copyWith(showNotifications: val),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'bn', label: Text('বাংলা')),
                    ],
                    selected: {settings.language},
                    onSelectionChanged: (val) {
                      settingsProvider.setLanguage(val.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Permissions Center ──
          _SectionHeader(title: 'Required Permissions'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _PermissionTile(
                  title: 'Phone Calls',
                  subtitle: 'To detect and reject incoming calls during prayer',
                  icon: Icons.phone_android,
                  status: _permissionStatuses[Permission.phone],
                  onRequest: () => _requestPermission(Permission.phone),
                ),
                const Divider(height: 1),
                _PermissionTile(
                  title: 'SMS',
                  subtitle: 'To send auto-reply messages to phone callers',
                  icon: Icons.sms_outlined,
                  status: _permissionStatuses[Permission.sms],
                  onRequest: () => _requestPermission(Permission.sms),
                ),
                const Divider(height: 1),
                _PermissionTile(
                  title: 'Location',
                  subtitle: 'To compute accurate local prayer times',
                  icon: Icons.my_location,
                  status: _permissionStatuses[Permission.location],
                  onRequest: () => _requestPermission(Permission.location),
                ),
                const Divider(height: 1),
                _PermissionTile(
                  title: 'Notifications',
                  subtitle: 'To display background status and reminders',
                  icon: Icons.notifications_none,
                  status: _permissionStatuses[Permission.notification],
                  onRequest: () => _requestPermission(Permission.notification),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread_outlined),
                  title: const Text('WhatsApp & Messenger Access'),
                  subtitle: const Text('Enable Notification Listener in device settings to auto-reply to app calls', style: TextStyle(fontSize: 12)),
                  trailing: FilledButton.tonal(
                    onPressed: () => CallService().openNotificationSettings(),
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── App Info ──
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'karachi':
        return 'University of Islamic Sciences, Karachi';
      case 'muslimWorldLeague':
        return 'Muslim World League';
      case 'northAmerica':
        return 'Islamic Society of North America (ISNA)';
      case 'egyptian':
        return 'Egyptian General Authority of Survey';
      default:
        return method;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.onRequest,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PermissionStatus? status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final isGranted = status?.isGranted ?? false;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isGranted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : FilledButton.tonal(
              onPressed: onRequest,
              child: const Text('Allow'),
            ),
    );
  }
}

