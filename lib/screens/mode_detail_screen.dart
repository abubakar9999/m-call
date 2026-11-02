import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/busy_mode.dart';
import '../providers/mode_provider.dart';
import '../utils/helpers.dart';

/// Screen for editing an existing [BusyMode] or creating a new custom mode.
class ModeDetailScreen extends StatefulWidget {
  const ModeDetailScreen({super.key, this.mode});

  /// The mode to edit. If `null`, a new custom mode is being created.
  final BusyMode? mode;

  @override
  State<ModeDetailScreen> createState() => _ModeDetailScreenState();
}

class _ModeDetailScreenState extends State<ModeDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _messageController;
  late String _selectedIcon;
  late int _durationMinutes;
  late bool _replyToPhone;
  late bool _replyToWhatsApp;
  late bool _replyToMessenger;
  late bool _autoSchedule;

  static const List<String> _emojiOptions = [
    '🕌', '💼', '😴', '📚', '🚗', '✈️', '🏋️', '🍳', '📖', '🎯', '💻', '⚡', '☕', '🎧', '🎮', '🏥'
  ];

  bool get _isCreating => widget.mode == null;
  bool get _isCustom => _isCreating || widget.mode?.type == BusyModeType.custom;

  @override
  void initState() {
    super.initState();
    final mode = widget.mode;
    _nameController = TextEditingController(text: mode?.name ?? '');
    _messageController = TextEditingController(
      text: mode?.message ??
          'I am currently busy in {mode_name}. Will call back in {time} minutes.',
    );
    _selectedIcon = mode?.icon ?? '⚡';
    _durationMinutes = mode?.durationMinutes ?? 30;
    _replyToPhone = mode?.replyToPhone ?? true;
    _replyToWhatsApp = mode?.replyToWhatsApp ?? true;
    _replyToMessenger = mode?.replyToMessenger ?? true;
    _autoSchedule = mode?.autoSchedule ?? false;

    _messageController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _insertChipText(String tag) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, tag);
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + tag.length),
      );
    } else {
      _messageController.text = '$text $tag';
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the mode')),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an auto-reply message')),
      );
      return;
    }

    final modeProvider = context.read<ModeProvider>();

    if (_isCreating) {
      final newMode = BusyMode(
        id: Helpers.generateId(),
        type: BusyModeType.custom,
        name: name,
        icon: _selectedIcon,
        message: message,
        durationMinutes: _durationMinutes,
        replyToPhone: _replyToPhone,
        replyToWhatsApp: _replyToWhatsApp,
        replyToMessenger: _replyToMessenger,
        autoSchedule: _autoSchedule,
      );
      await modeProvider.addCustomMode(newMode);
    } else {
      final updated = widget.mode!.copyWith(
        name: name,
        icon: _selectedIcon,
        message: message,
        durationMinutes: _durationMinutes,
        replyToPhone: _replyToPhone,
        replyToWhatsApp: _replyToWhatsApp,
        replyToMessenger: _replyToMessenger,
        autoSchedule: _autoSchedule,
      );
      await modeProvider.updateMode(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Mode'),
        content: Text('Are you sure you want to delete "${widget.mode?.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && widget.mode != null) {
      await context.read<ModeProvider>().deleteCustomMode(widget.mode!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modeName = _nameController.text.isEmpty ? 'Mode' : _nameController.text;
    final previewText = Helpers.processMessage(
      _messageController.text,
      remainingTime: _durationMinutes,
      modeName: modeName,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreating ? 'New Busy Mode' : 'Edit Mode'),
        actions: [
          if (!_isCreating && _isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Mode',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Icon Picker
          Text('Select Icon', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojiOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final emoji = _emojiOptions[index];
                final isSelected = emoji == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameController,
            enabled: _isCustom,
            decoration: InputDecoration(
              labelText: 'Mode Name',
              hintText: 'e.g. Gym, Coding, Reading',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_selectedIcon, style: const TextStyle(fontSize: 20)),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration', style: theme.textTheme.titleSmall),
              Text(
                Helpers.formatDuration(_durationMinutes),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47, // 5 minute steps
            label: Helpers.formatDuration(_durationMinutes),
            onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
          ),
          const SizedBox(height: 16),

          // Auto-reply message
          Text('Auto-Reply Message', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Message to send automatically...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Tag chips
          Row(
            children: [
              Text('Insert tag: ', style: theme.textTheme.bodySmall),
              const SizedBox(width: 4),
              ActionChip(
                label: const Text('{time}'),
                onPressed: () => _insertChipText('{time}'),
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('{mode_name}'),
                onPressed: () => _insertChipText('{mode_name}'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Preview Card
          Text('Message Preview', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_chat_read_outlined, size: 20, color: Color(0xFF00695C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    previewText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Platform toggles
          Text('Respond To Calls From', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.phone, color: Color(0xFF00695C)),
                  title: const Text('Phone Calls (SMS)'),
                  subtitle: const Text('Auto-reject and send SMS'),
                  value: _replyToPhone,
                  onChanged: (val) => setState(() => _replyToPhone = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('WhatsApp Calls'),
                  subtitle: const Text('Auto-reply via notification'),
                  value: _replyToWhatsApp,
                  onChanged: (val) => setState(() => _replyToWhatsApp = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.messenger, color: Color(0xFF0084FF)),
                  title: const Text('Messenger Calls'),
                  subtitle: const Text('Auto-reply via notification'),
                  value: _replyToMessenger,
                  onChanged: (val) => setState(() => _replyToMessenger = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(_isCreating ? 'Create Mode' : 'Save Changes'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

