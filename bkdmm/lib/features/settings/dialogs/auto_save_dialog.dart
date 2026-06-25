import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/utils/responsive_utils.dart';

/// Auto-save interval selection dialog with TDesign styling
class AutoSaveDialog extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;

  const AutoSaveDialog({
    super.key,
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
    final dialogWidth = ResponsiveUtils.getDialogWidth(context, DialogSizePreset.small);

    return TDAlertDialog(
      title: 'Auto-save Interval',
      content: '',
      contentWidget: SizedBox(
        width: dialogWidth,
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