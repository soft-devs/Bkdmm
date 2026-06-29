import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Settings section widget with TDesign styling
class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusLarge),
        border: Border.all(
          color: tdTheme.componentStrokeColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: tdTheme.brandNormalColor),
                const SizedBox(width: 12),
                TDText(
                  title,
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TDText(
                description!,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorSecondary,
              ),
            ),
          TDDivider(
            margin: EdgeInsets.symmetric(
                horizontal: 16, vertical: description != null ? 8 : 0),
          ),
          // Settings items
          ...children,
        ],
      ),
    );
  }
}
