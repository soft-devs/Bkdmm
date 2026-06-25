import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../../constants/app_constants.dart';

/// Database type selection dialog with TDesign styling
class DatabaseTypeDialog extends StatelessWidget {
  final String? currentValue;
  final ValueChanged<String?> onChanged;

  const DatabaseTypeDialog({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 375.0; // 300 * 1.25
    final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

    return TDAlertDialog(
      title: 'Default Database Type',
      content: '',
      contentWidget: SizedBox(
        width: dialogWidth,
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
