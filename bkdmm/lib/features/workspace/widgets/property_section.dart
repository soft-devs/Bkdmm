import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Property section header widget
class PropertySection extends StatelessWidget {
  final String title;

  const PropertySection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TDText(
        title,
        font: tdTheme.fontTitleSmall,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}