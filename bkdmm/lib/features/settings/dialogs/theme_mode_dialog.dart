import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/utils/responsive_utils.dart';

/// Theme mode selection dialog with TDesign styling
class ThemeModeDialog extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onChanged;

  const ThemeModeDialog({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.small);

    return TDAlertDialog(
      title: 'Theme Mode',
      content: '',
      contentWidget: SizedBox(
        width: dialogWidth,
        child: Column(
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
        ..leftIconColor =
            isSelected ? tdTheme.brandNormalColor : tdTheme.textColorSecondary
        ..rightIconColor = tdTheme.brandNormalColor,
      rightIcon: isSelected ? TDIcons.check : null,
      onClick: (_) {
        onChanged(id);
        Navigator.pop(context);
      },
    );
  }
}