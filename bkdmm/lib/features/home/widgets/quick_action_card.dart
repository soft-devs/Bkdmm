import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Quick action card widget using TDTheme colors and TDText.
///
/// Displays a clickable card with icon, label, and description.
/// Used in the home view for quick actions like creating/opening projects.
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.tdTheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final TDThemeData tdTheme;
  final VoidCallback? onTap;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tdTheme = widget.tdTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        scale: _isHovered ? 1.02 : 1.0,
        child: Material(
          color: _isHovered
              ? tdTheme.bgColorContainerHover
              : tdTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tdTheme.brandLightColor,
                      borderRadius: BorderRadius.circular(tdTheme.radiusExtraLarge),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: tdTheme.brandNormalColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TDText(
                    widget.label,
                    font: tdTheme.fontTitleSmall,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  TDText(
                    widget.description,
                    font: tdTheme.fontBodySmall,
                    textColor: tdTheme.textColorSecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}