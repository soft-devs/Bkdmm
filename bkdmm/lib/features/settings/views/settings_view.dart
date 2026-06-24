import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
    final tdTheme = TDTheme.of(context);
    final settings = ref.watch(settingsProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            icon: TDIcons.palette,
            children: [
              // Theme Mode
              _SettingsTile(
                title: 'Theme Mode',
                subtitle: _getThemeModeLabel(settings.themeMode),
                leading: Icon(
                  _getThemeModeIcon(settings.themeMode),
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                onTap: () => _showThemeModeDialog(),
              ),
              // Accent Color
              _SettingsTile(
                title: 'Accent Color',
                subtitle: 'Customize the app accent color',
                leading: Icon(
                  TDIcons.color_invert,
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: tdTheme.brandNormalColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tdTheme.componentStrokeColor,
                      width: 1,
                    ),
                  ),
                ),
                onTap: () => _showAccentColorDialog(),
              ),
              // Font Size
              _SettingsTile(
                title: 'Font Size',
                subtitle: 'Editor font size: ${settings.editorFontSize.toInt()}',
                leading: Icon(
                  TDIcons.textformat_bold,
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                onTap: () => _showFontSizeDialog(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Editor Section
          _SettingsSection(
            title: 'Editor',
            icon: TDIcons.edit,
            children: [
              // Default Database Type
              _SettingsTile(
                title: 'Default Database Type',
                subtitle: settings.defaultDatabase ?? 'Not set',
                leading: Icon(
                  TDIcons.data_base,
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                onTap: () => _showDatabaseTypeDialog(),
              ),
              // Auto-save Interval
              _SettingsTile(
                title: 'Auto-save Interval',
                subtitle: _getAutoSaveLabel(settings.autoSaveInterval),
                leading: Icon(
                  TDIcons.time,
                  size: 24,
                  color: tdTheme.brandNormalColor,
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
            icon: TDIcons.list,
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
            icon: TDIcons.data,
            children: [
              _SettingsTile(
                title: 'Manage Data Types',
                subtitle: 'Configure custom data types',
                leading: Icon(
                  TDIcons.chevron_right,
                  size: 24,
                  color: tdTheme.brandNormalColor,
                ),
                onTap: () => _navigateToDataTypes(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reset Section
          _SettingsSection(
            title: 'Reset',
            icon: TDIcons.refresh,
            children: [
              _SettingsTile(
                title: 'Reset to Defaults',
                subtitle: 'Restore all settings to default values',
                leading: Icon(
                  TDIcons.close_circle,
                  size: 24,
                  color: tdTheme.errorNormalColor,
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
        return TDIcons.sun_rising;
      case 'dark':
        return TDIcons.moon;
      default:
        return TDIcons.brightness;
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
    TDToast.showText('Data type management coming soon', context: context);
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: 'Reset Settings',
        content: 'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        leftBtn: TDDialogButtonOptions(
          title: 'Cancel',
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: 'Reset',
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            ref.read(settingsProvider.notifier).resetToDefaults();
            Navigator.pop(context);
            TDToast.showSuccess('Settings reset to defaults', context: context);
          },
        ),
      ),
    );
  }
}

/// Settings section widget with TDesign styling
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
    final tdTheme = TDTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusLarge),
        border: Border.all(
          color: tdTheme.componentStrokeColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: tdTheme.brandNormalColor),
                const SizedBox(width: 12),
                TDText(
                  title,
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TDText(
                description!,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorSecondary,
              ),
            ),
          TDDivider(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: description != null ? 8 : 0),
          ),
          // Settings items
          ...children,
        ],
      ),
    );
  }
}

/// Settings tile widget with TDesign styling
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
    final tdTheme = TDTheme.of(context);

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
                  TDText(
                    title,
                    font: tdTheme.fontBodyMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 2),
                  TDText(
                    subtitle,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
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

/// Settings switch tile widget with TDesign styling
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
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 40), // Align with other tiles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  title,
                  font: tdTheme.fontBodyMedium,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 2),
                TDText(
                  subtitle,
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),
          TDSwitch(
            isOn: value,
            size: TDSwitchSize.medium,
            onChanged: (newValue) {
              onChanged(newValue);
              return false; // Return false to let internal state update automatically
            },
          ),
        ],
      ),
    );
  }
}

/// Theme mode selection dialog with TDesign styling
class _ThemeModeDialog extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const _ThemeModeDialog({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return TDAlertDialog(
      title: 'Theme Mode',
      content: '',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context: context,
            tdTheme: tdTheme,
            id: 'system',
            title: 'System',
            subtitle: 'Follow system settings',
            icon: TDIcons.brightness,
          ),
          _buildThemeOption(
            context: context,
            tdTheme: tdTheme,
            id: 'light',
            title: 'Light',
            subtitle: 'Always use light theme',
            icon: TDIcons.sun_rising,
          ),
          _buildThemeOption(
            context: context,
            tdTheme: tdTheme,
            id: 'dark',
            title: 'Dark',
            subtitle: 'Always use dark theme',
            icon: TDIcons.moon,
          ),
        ],
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required TDThemeData tdTheme,
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = currentValue == id;

    return TDCell(
      leftIcon: icon,
      title: title,
      description: subtitle,
      arrow: false,
      style: TDCellStyle(context: context)
        ..leftIconColor = isSelected ? tdTheme.brandNormalColor : tdTheme.textColorSecondary
        ..rightIconColor = tdTheme.brandNormalColor,
      rightIcon: isSelected ? TDIcons.check : null,
      onClick: (_) {
        onChanged(id);
        Navigator.pop(context);
      },
    );
  }
}

/// Accent color selection dialog with TDesign styling
class _AccentColorDialog extends StatelessWidget {
  final ValueChanged<Color> onChanged;

  const _AccentColorDialog({
    required this.onChanged,
  });

  static const List<Color> _accentColors = [
    Color(0xFF0052D9), // TDesign brand blue
    Color(0xFF366EF4), // TDesign brand hover blue
    Color(0xFF618DFF), // TDesign brand lighter blue
    Color(0xFF2BA471), // TDesign success green
    Color(0xFF008858), // TDesign success normal green
    Color(0xFFE37318), // TDesign warning orange
    Color(0xFFD54941), // TDesign error red
    Color(0xFFAD352F), // TDesign error normal red
  ];

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return TDAlertDialog(
      title: 'Accent Color',
      content: '',
      contentWidget: SizedBox(
        width: 364, // 280 * 1.3
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
            final isSelected = color.toARGB32 == tdTheme.brandNormalColor.toARGB32;

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
                          color: tdTheme.textColorPrimary,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        TDIcons.check,
                        size: 16,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? tdTheme.textColorAnti
                            : tdTheme.textColorPrimary,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
    );
  }
}

/// Font size selection dialog with TDesign styling
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
    final tdTheme = TDTheme.of(context);

    return TDAlertDialog(
      title: 'Font Size',
      content: '',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TDText(
            'Sample Text',
            font: tdTheme.fontBodyLarge,
            textColor: tdTheme.textColorPrimary,
            style: TextStyle(fontSize: _value),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TDText(
                'A',
                font: tdTheme.fontMarkSmall,
                textColor: tdTheme.textColorSecondary,
              ),
              Expanded(
                child: TDSlider(
                  value: _value,
                  sliderThemeData: TDSliderThemeData(
                    min: 10,
                    max: 24,
                    divisions: 14,
                  ),
                  onChanged: (value) {
                    setState(() => _value = value);
                  },
                ),
              ),
              TDText(
                'A',
                font: tdTheme.fontMarkMedium,
                textColor: tdTheme.textColorSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TDText(
            '${_value.toInt()} pt',
            font: tdTheme.fontBodyMedium,
            textColor: tdTheme.textColorPrimary,
          ),
        ],
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Apply',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: () {
          widget.onChanged(_value);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Database type selection dialog with TDesign styling
class _DatabaseTypeDialog extends StatelessWidget {
  final String? currentValue;
  final ValueChanged<String?> onChanged;

  const _DatabaseTypeDialog({
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return TDAlertDialog(
      title: 'Default Database Type',
      content: '',
      contentWidget: SizedBox(
        width: 390, // 300 * 1.3
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppConstants.supportedDatabases.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Option to clear selection
              final isSelected = currentValue == null;
              final cellStyle = TDCellStyle(context: context);
              if (isSelected) {
                cellStyle.rightIconColor = tdTheme.brandNormalColor;
              }
              return TDCell(
                leftIcon: TDIcons.close,
                title: 'Not Set',
                description: 'No default database',
                arrow: false,
                onClick: (_) {
                  onChanged(null);
                  Navigator.pop(context);
                },
                rightIcon: isSelected ? TDIcons.check : null,
                style: cellStyle,
              );
            }

            final db = AppConstants.supportedDatabases[index - 1];
            final isSelected = currentValue == db;
            final cellStyle = TDCellStyle(context: context);
            if (isSelected) {
              cellStyle.leftIconColor = tdTheme.brandNormalColor;
              cellStyle.rightIconColor = tdTheme.brandNormalColor;
            } else {
              cellStyle.leftIconColor = tdTheme.textColorSecondary;
            }
            return TDCell(
              leftIcon: TDIcons.data_base,
              title: db,
              arrow: false,
              onClick: (_) {
                onChanged(db);
                Navigator.pop(context);
              },
              rightIcon: isSelected ? TDIcons.check : null,
              style: cellStyle,
            );
          },
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
    );
  }
}

/// Auto-save interval selection dialog with TDesign styling
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
    final tdTheme = TDTheme.of(context);

    return TDAlertDialog(
      title: 'Auto-save Interval',
      content: '',
      contentWidget: SizedBox(
        width: 390, // 300 * 1.3
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _intervals.length,
          itemBuilder: (context, index) {
            final interval = _intervals[index];
            final isSelected = currentValue == interval;

            final cellStyle = TDCellStyle(context: context);
            if (isSelected) {
              cellStyle.leftIconColor = tdTheme.brandNormalColor;
              cellStyle.rightIconColor = tdTheme.brandNormalColor;
            } else {
              cellStyle.leftIconColor = tdTheme.textColorSecondary;
            }

            return TDCell(
              leftIcon: TDIcons.time,
              title: _getLabel(interval),
              arrow: false,
              onClick: (_) {
                onChanged(interval);
                Navigator.pop(context);
              },
              rightIcon: isSelected ? TDIcons.check : null,
              style: cellStyle,
            );
          },
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: () => Navigator.pop(context),
      ),
    );
  }
}