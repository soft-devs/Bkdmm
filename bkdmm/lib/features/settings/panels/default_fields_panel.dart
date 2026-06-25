import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/providers/providers.dart';
import '../widgets/widgets.dart';

/// Default fields settings panel for project settings
class DefaultFieldsPanel extends ConsumerWidget {
  const DefaultFieldsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tdTheme = TDTheme.of(context);
    final projectSettings = ref.watch(projectSettingsProvider);
    final globalSettings = ref.watch(settingsProvider);

    if (projectSettings == null) {
      return Center(
        child: TDText(
          'No project loaded',
          textColor: tdTheme.textColorSecondary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(TDIcons.info_circle, size: 16, color: tdTheme.brandNormalColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TDText(
                    'Project settings can inherit from global defaults. Turn off inheritance to customize.',
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inheritance toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
            ),
            child: Row(
              children: [
                Icon(TDIcons.link, size: 20, color: tdTheme.brandNormalColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TDText(
                        'Inherit from Global Settings',
                        font: tdTheme.fontBodyMedium,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 4),
                      TDText(
                        'Use global default fields settings',
                        font: tdTheme.fontBodySmall,
                        textColor: tdTheme.textColorSecondary,
                      ),
                    ],
                  ),
                ),
                TDSwitch(
                  isOn: projectSettings.inheritDefaultFields,
                  size: TDSwitchSize.medium,
                  onChanged: (v) {
                    ref.read(projectSettingsProvider.notifier).setInheritDefaultFields(v);
                    return false;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Field settings (only if not inheriting)
          if (!projectSettings.inheritDefaultFields)
            SettingsSection(
              title: 'Default Fields',
              icon: TDIcons.list,
              description: 'Configure default fields for new tables in this project',
              children: [
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'REVISION',
                  subtitle: 'Revision number field',
                  projectValue: projectSettings.defaultFieldsRevision,
                  globalValue: globalSettings.defaultFieldsRevision,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsRevision(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'CREATED_BY',
                  subtitle: 'Creator field',
                  projectValue: projectSettings.defaultFieldsCreatedBy,
                  globalValue: globalSettings.defaultFieldsCreatedBy,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsCreatedBy(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'CREATED_TIME',
                  subtitle: 'Creation timestamp',
                  projectValue: projectSettings.defaultFieldsCreatedTime,
                  globalValue: globalSettings.defaultFieldsCreatedTime,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsCreatedTime(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'UPDATED_BY',
                  subtitle: 'Updater field',
                  projectValue: projectSettings.defaultFieldsUpdatedBy,
                  globalValue: globalSettings.defaultFieldsUpdatedBy,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsUpdatedBy(v),
                ),
                _buildFieldSwitch(
                  context: context,
                  ref: ref,
                  title: 'UPDATED_TIME',
                  subtitle: 'Update timestamp',
                  projectValue: projectSettings.defaultFieldsUpdatedTime,
                  globalValue: globalSettings.defaultFieldsUpdatedTime,
                  onChanged: (v) => ref.read(projectSettingsProvider.notifier).setDefaultFieldsUpdatedTime(v),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Reset button
          TDButton(
            text: 'Reset to Inherit',
            icon: TDIcons.refresh,
            theme: TDButtonTheme.defaultTheme,
            type: TDButtonType.outline,
            size: TDButtonSize.medium,
            onTap: () => ref.read(projectSettingsProvider.notifier).resetToDefaults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSwitch({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool? projectValue,
    required bool globalValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final tdTheme = TDTheme.of(context);
    final displayValue = projectValue ?? globalValue;
    final isUsingGlobal = projectValue == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TDText(
                      title,
                      font: tdTheme.fontBodyMedium,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isUsingGlobal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tdTheme.bgColorSecondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TDText(
                          'Global',
                          font: tdTheme.fontMarkExtraSmall,
                          textColor: tdTheme.brandNormalColor,
                        ),
                      ),
                    ],
                  ],
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
            isOn: displayValue,
            size: TDSwitchSize.medium,
            onChanged: (v) {
              onChanged(v);
              return false;
            },
          ),
        ],
      ),
    );
  }
}
