import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Color dot widget for displaying a color indicator
class ColorDot extends StatelessWidget {
  final Color color;

  const ColorDot({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
    );
  }
}
