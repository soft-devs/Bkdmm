import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/core/i18n/i18n.dart';
import 'package:bkdmm/core/i18n/locale_provider.dart';
import 'package:bkdmm/shared/providers/providers.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';

/// Global settings view
class GlobalSettingsView extends ConsumerWidget {
  const GlobalSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final localeState = ref.watch(appLocaleProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Appearance Section
        SettingsSection(
          title: l10n.appearance,
          icon: TDIcons.palette,
          children: [
            // Language
            SettingsTile(
              title: l10n.language,
              subtitle: localeState.displayName,
              leading: Icon(
                TDIcons.translate,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showLanguageDialog(context, ref),
            ),
            // Theme Mode
            SettingsTile(
              title: l10n.themeMode,
              subtitle: _getThemeModeLabel(settings.themeMode, l10n),
              leading: Icon(
                _getThemeModeIcon(settings.themeMode),
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showThemeModeDialog(context, ref),
            ),
            // Accent Color
            SettingsTile(
              title: l10n.accentColor,
              subtitle: l10n.customizeAccentColor,
              leading: Icon(
                TDIcons.color_invert,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: settings.accentColorValue ?? tdTheme.brandNormalColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tdTheme.componentStrokeColor,
                    width: 1,
                  ),
                ),
              ),
              onTap: () => _showAccentColorDialog(context, ref),
            ),
            // Font Size
            SettingsTile(
              title: l10n.fontSize,
              subtitle: l10n.editorFontSize(settings.editorFontSize.toInt()),
              leading: Icon(
                TDIcons.textformat_bold,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showFontSizeDialog(context, ref),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Editor Section
        SettingsSection(
          title: l10n.editor,
          icon: TDIcons.edit,
          children: [
            // Default Database Type
            SettingsTile(
              title: l10n.defaultDatabaseType,
              subtitle: settings.defaultDatabase ?? l10n.notSet,
              leading: Icon(
                TDIcons.data_base,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showDatabaseTypeDialog(context, ref),
            ),
            // Auto-save Interval
            SettingsTile(
              title: l10n.autoSaveInterval,
              subtitle: _getAutoSaveLabel(settings.autoSaveInterval, l10n),
              leading: Icon(
                TDIcons.time,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _showAutoSaveDialog(context, ref),
            ),
            // Show Line Numbers
            SettingsSwitchTile(
              title: l10n.showLineNumbers,
              subtitle: l10n.displayLineNumbers,
              value: settings.showLineNumbers,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setShowLineNumbers(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Default Fields Section (Global defaults)
        SettingsSection(
          title: l10n.defaultFieldsGlobal,
          icon: TDIcons.list,
          description: l10n.defaultFieldsDescription,
          children: [
            SettingsSwitchTile(
              title: 'REVISION',
              subtitle: l10n.addRevisionField,
              value: settings.defaultFieldsRevision,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsRevision(value);
              },
            ),
            SettingsSwitchTile(
              title: 'CREATED_BY',
              subtitle: l10n.addCreatorField,
              value: settings.defaultFieldsCreatedBy,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsCreatedBy(value);
              },
            ),
            SettingsSwitchTile(
              title: 'CREATED_TIME',
              subtitle: l10n.addCreationTimestampField,
              value: settings.defaultFieldsCreatedTime,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsCreatedTime(value);
              },
            ),
            SettingsSwitchTile(
              title: 'UPDATED_BY',
              subtitle: l10n.addUpdaterField,
              value: settings.defaultFieldsUpdatedBy,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedBy(value);
              },
            ),
            SettingsSwitchTile(
              title: 'UPDATED_TIME',
              subtitle: l10n.addUpdateTimestampField,
              value: settings.defaultFieldsUpdatedTime,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDefaultFieldsUpdatedTime(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Data Type Settings Section
        SettingsSection(
          title: l10n.dataTypes,
          icon: TDIcons.data,
          children: [
            SettingsTile(
              title: l10n.manageDataTypes,
              subtitle: l10n.configureCustomDataTypes,
              leading: Icon(
                TDIcons.chevron_right,
                size: 24,
                color: tdTheme.brandNormalColor,
              ),
              onTap: () => _navigateToDataTypes(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Reset Section
        SettingsSection(
          title: l10n.reset,
          icon: TDIcons.refresh,
          children: [
            SettingsTile(
              title: l10n.resetToDefaults,
              subtitle: l10n.restoreAllSettingsToDefault,
              leading: Icon(
                TDIcons.close_circle,
                size: 24,
                color: tdTheme.errorNormalColor,
              ),
              onTap: () => _showResetConfirmation(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  String _getThemeModeLabel(String mode, dynamic l10n) {
    switch (mode) {
      case 'light':
        return l10n.lightMode;
      case 'dark':
        return l10n.darkMode;
      default:
        return l10n.systemDefault;
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

  String _getAutoSaveLabel(int seconds, dynamic l10n) {
    if (seconds == 0) {
      return l10n.disabled;
    } else if (seconds < 60) {
      return '$seconds ${l10n.seconds}';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes ${l10n.minutes}';
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.read(appLocaleProvider).locale;

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: l10n.language,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: supportedLocales.map((locale) {
            final isSelected = locale.languageCode == currentLocale.languageCode;
            return InkWell(
              onTap: () {
                ref.read(appLocaleProvider.notifier).setLocale(locale);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localeNames[locale] ?? locale.languageCode,
                        style: TextStyle(
                          color: isSelected
                              ? TDTheme.of(context).brandNormalColor
                              : TDTheme.of(context).textColorPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        TDIcons.check,
                        size: 20,
                        color: TDTheme.of(context).brandNormalColor,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        leftBtn: TDDialogButtonOptions(
          title: l10n.cancel,
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: null,
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ThemeModeDialog(
        currentValue: ref.read(settingsProvider).themeMode,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setThemeMode(value);
        },
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AccentColorDialog(
        onChanged: (color) {
          ref.read(settingsProvider.notifier).setAccentColor(color);
        },
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => FontSizeDialog(
        currentValue: ref.read(settingsProvider).editorFontSize,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setEditorFontSize(value);
        },
      ),
    );
  }

  void _showDatabaseTypeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DatabaseTypeDialog(
        currentValue: ref.read(settingsProvider).defaultDatabase,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setDefaultDatabase(value);
        },
      ),
    );
  }

  void _showAutoSaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AutoSaveDialog(
        currentValue: ref.read(settingsProvider).autoSaveInterval,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).setAutoSaveInterval(value);
        },
      ),
    );
  }

  void _navigateToDataTypes(BuildContext context) {
    TDToast.showText(context.l10n.dataTypeManagementComingSoon, context: context);
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: l10n.resetSettings,
        content: l10n.resetSettingsConfirm,
        leftBtn: TDDialogButtonOptions(
          title: l10n.cancel,
          theme: TDButtonTheme.defaultTheme,
          type: TDButtonType.text,
          action: () => Navigator.pop(context),
        ),
        rightBtn: TDDialogButtonOptions(
          title: l10n.reset,
          theme: TDButtonTheme.danger,
          type: TDButtonType.fill,
          action: () {
            ref.read(settingsProvider.notifier).resetToDefaults();
            Navigator.pop(context);
            TDToast.showSuccess(l10n.settingsResetSuccess, context: context);
          },
        ),
      ),
    );
  }
}
