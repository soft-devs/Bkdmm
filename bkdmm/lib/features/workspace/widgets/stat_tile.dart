import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Statistics tile widget for displaying icon-label-value rows
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tdTheme.textColorSecondary),
          const SizedBox(width: 8),
          TDText(
            label,
            font: tdTheme.fontBodySmall,
            textColor: tdTheme.textColorSecondary,
          ),
          const Spacer(),
          TDText(
            value,
            font: tdTheme.fontBodySmall,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}