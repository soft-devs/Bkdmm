import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../constants/app_constants.dart';

/// Settings view - Application settings configuration
///
/// Categories:
/// - Appearance: Theme mode, accent color, font size
/// - Editor: Default database, auto-save, line numbers
/// - Default Fields: Default fields for new tables
/// - Data Types: Link to data type management
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              // Theme Mode
              _SettingsTile(
                title: 'Theme Mode',
                subtitle: _getThemeModeLabel(settings.themeMode),
                leading: Icon(
                  _getThemeModeIcon(settings.themeMode),
                  color: colorScheme.primary,
                ),
                onTap: () => _showThemeModeDialog(),
              ),
              // Accent Color
              _SettingsTile(
                title: 'Accent Color',
                subtitle: 'Customize the app accent color',
                leading: Icon(
                  Icons.colorize,
                  color: colorScheme.primary,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => _showAccentColorDialog(),
              ),
              // Font Size
              _SettingsTile(
                title: 'Font Size',
                subtitle: 'Editor font size: ${settings.editorFontSize.toInt()}',
                leading: Icon(
                  Icons.text_fields,
                  color: colorScheme.primary,
                ),
                onTap: () => _showFontSizeDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Editor Section
          _SettingsSection(
            title: 'Editor',
            icon: Icons.edit_outlined,
            children: [
              // Default Database Type
              _SettingsTile(
                title: 'Default Database Type',
                subtitle: settings.defaultDatabase ?? 'Not set',
                leading: Icon(
                  Icons.storage,
                  color: colorScheme.primary,
                ),
                onTap: () => _showDatabaseTypeDialog(),
              ),
              // Auto-save Interval
              _SettingsTile(
                title: 'Auto-save Interval',
                subtitle: _getAutoSaveLabel(settings.autoSaveInterval),
                leading: Icon(
                  Icons.save,
                  color: colorScheme.primary,
                ),
                onTap: () => _showAutoSaveDialog(),
              ),
              // Show Line Numbers
              _SettingsSwitchTile(
                title: 'Show Line Numbers',
                subtitle: 'Display line numbers in code preview',
                value: settings.showLineNumbers,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setShowLineNumbers(value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Default Fields Section
          _SettingsSection(
            title: 'Default Fields',
            icon: Icons.list_alt,
            description: 'Configure default fields for new tables',
            children: [
              _SettingsSwitchTile(
                title: 'REVISION',
                subtitle: 'Add revision number field',
                value: settings.defaultFieldsRevision,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDefaultFieldsRevision(value);
                },
              ),
              _SettingsSwitchTile(
                title: 'CREATED_BY',
                subtitle: 'Add creator field',
                value: settings.defaultFieldsCreatedBy,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDefaultFieldsCreatedBy(value);
                },
              ),
              _SettingsSwitchTile(
                title: 'CREATED_TIME',
                subtitle: 'Add creation timestamp field',
                value: settings.defaultFieldsCreatedTime,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDefaultFieldsCreatedTime(value);
                },
              ),
              _SettingsSwitchTile(
                title: 'UPDATED_BY',
                subtitle: 'Add updater field',
                value: settings.defaultFieldsUpdatedBy,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedBy(value);
                },
              ),
              _SettingsSwitchTile(
                title: 'UPDATED_TIME',
                subtitle: 'Add update timestamp field',
                value: settings.defaultFieldsUpdatedTime,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedTime(value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Type Settings Section
          _SettingsSection(
            title: 'Data Types',
            icon: Icons.data_object,
            children: [
              _SettingsTile(
                title: 'Manage Data Types',
                subtitle: 'Configure custom data types',
                leading: Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary,
                ),
                onTap: () => _navigateToDataTypes(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reset Section
          _SettingsSection(
            title: 'Reset',
            icon: Icons.restore,
            children: [
              _SettingsTile(
                title: 'Reset to Defaults',
                subtitle: 'Restore all settings to default values',
                leading: Icon(
                  Icons.refresh,
                  color: colorScheme.error,
                ),
                onTap: () => _showResetConfirmation(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  IconData _getThemeModeIcon(String mode) {
    switch (mode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  String _getAutoSaveLabel(int seconds) {
    if (seconds == 0) {
      return 'Disabled';
    } else if (seconds < 60) {
      return '$seconds seconds';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => _ThemeModeDialog(
        currentValue: ref.read(settingsProvider).themeMode,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setThemeMode(value);
        },
      ),
    );
  }

  void _showAccentColorDialog() {
    showDialog(
      context: context,
      builder: (context) => _AccentColorDialog(
        onChanged: (color) {
          ref.read(settingsProvider.notifier).setAccentColor(color);
        },
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => _FontSizeDialog(
        currentValue: ref.read(settingsProvider).editorFontSize,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setEditorFontSize(value);
        },
      ),
    );
  }

  void _showDatabaseTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => _DatabaseTypeDialog(
        currentValue: ref.read(settingsProvider).defaultDatabase,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setDefaultDatabase(value);
        },
      ),
    );
  }

  void _showAutoSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => _AutoSaveDialog(
        currentValue: ref.read(settingsProvider).autoSaveInterval,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setAutoSaveInterval(value);
        },
      ),
    );
  }

  void _navigateToDataTypes() {
    // TODO: Navigate to data type management page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data type management coming soon')),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// Settings section widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Divider(height: 1),
          // Settings items
          ...children,
        ],
      ),
    );
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Settings switch tile widget
class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40), // Align with other tiles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Theme mode selection dialog
class _ThemeModeDialog extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _ThemeModeDialog({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Theme Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeModeOption(
            icon: Icons.brightness_auto,
            title: 'System',
            subtitle: 'Follow system settings',
            value: 'system',
            groupValue: currentValue,
            onChanged: (value) {
              onChanged(value);
              Navigator.pop(context);
            },
          ),
          _ThemeModeOption(
            icon: Icons.light_mode,
            title: 'Light',
            subtitle: 'Always use light theme',
            value: 'light',
            groupValue: currentValue,
            onChanged: (value) {
              onChanged(value);
              Navigator.pop(context);
            },
          ),
          _ThemeModeOption(
            icon: Icons.dark_mode,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            value: 'dark',
            groupValue: currentValue,
            onChanged: (value) {
              onChanged(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Theme mode option widget
class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = value == groupValue;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
      onTap: () => onChanged(value),
    );
  }
}

/// Accent color selection dialog
class _AccentColorDialog extends StatelessWidget {
  final ValueChanged<Color> onChanged;

  const _AccentColorDialog({
    required this.onChanged,
  });

  static const List<Color> _accentColors = [
    Color(0xFF6750A4), // Purple (default M3)
    Color(0xFF0061A4), // Blue
    Color(0xFF006E1C), // Green
    Color(0xFFBA1A1A), // Red
    Color(0xFF984061), // Pink
    Color(0xFF7C5800), // Orange
    Color(0xFF006A6A), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Accent Color'),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _accentColors.length,
          itemBuilder: (context, index) {
            final color = _accentColors[index];
            final isSelected = color.value == colorScheme.primary.value;

            return InkWell(
              onTap: () {
                onChanged(color);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Font size selection dialog
class _FontSizeDialog extends StatefulWidget {
  final double currentValue;
  final ValueChanged<double> onChanged;

  const _FontSizeDialog({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Font Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sample Text',
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: _value),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _value,
                  min: 10,
                  max: 24,
                  divisions: 14,
                  label: _value.toInt().toString(),
                  onChanged: (value) {
                    setState(() => _value = value);
                  },
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          Text(
            '${_value.toInt()} pt',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onChanged(_value);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Database type selection dialog
class _DatabaseTypeDialog extends StatelessWidget {
  final String? currentValue;
  final ValueChanged<String?> onChanged;

  const _DatabaseTypeDialog({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Default Database Type'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppConstants.supportedDatabases.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Option to clear selection
              return ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Not Set'),
                subtitle: const Text('No default database'),
                trailing: currentValue == null
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  onChanged(null);
                  Navigator.pop(context);
                },
              );
            }

            final db = AppConstants.supportedDatabases[index - 1];
            return ListTile(
              leading: Icon(
                Icons.storage,
                color: currentValue == db
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(db),
              trailing: currentValue == db
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                onChanged(db);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Auto-save interval selection dialog
class _AutoSaveDialog extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;

  const _AutoSaveDialog({
    required this.currentValue,
    required this.onChanged,
  });

  static const List<int> _intervals = [0, 30, 60, 120, 300];

  String _getLabel(int seconds) {
    if (seconds == 0) {
      return 'Disabled';
    } else if (seconds < 60) {
      return '$seconds seconds';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Auto-save Interval'),
      content: SizedBox(
        width: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _intervals.length,
          itemBuilder: (context, index) {
            final interval = _intervals[index];
            return ListTile(
              leading: Icon(
                interval == 0 ? Icons.timer_off : Icons.timer,
                color: currentValue == interval
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(_getLabel(interval)),
              trailing: currentValue == interval
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                onChanged(interval);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
