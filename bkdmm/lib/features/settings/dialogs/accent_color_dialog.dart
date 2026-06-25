import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Accent color selection dialog with TDesign styling
class AccentColorDialog extends StatelessWidget {
  final ValueChanged<Color> onChanged;

  const AccentColorDialog({
    super.key,
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
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 280.0;
    final dialogWidth = (screenWidth * 0.85).clamp(baseWidth, baseWidth * 1.3);

    return TDAlertDialog(
      title: 'Accent Color',
      content: '',
      contentWidget: SizedBox(
        width: dialogWidth,
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
            final isSelected =
                color.toARGB32 == tdTheme.brandNormalColor.toARGB32;

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
