import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Property field widget displaying label-value pairs
class PropertyField extends StatelessWidget {
  final String label;
  final String value;

  const PropertyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TDText(
            label,
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const SizedBox(height: 2),
          TDText(
            value,
            font: tdTheme.fontBodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}