import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Font size selection dialog with TDesign styling
class FontSizeDialog extends StatefulWidget {
  final double currentValue;
  final ValueChanged<double> onChanged;

  const FontSizeDialog({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  State<FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<FontSizeDialog> {
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
