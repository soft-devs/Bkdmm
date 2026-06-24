import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// TDesign styled popup menu item
class TDPopupMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final bool isDivider;

  const TDPopupMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.isDivider = false,
  });

  const TDPopupMenuItem.divider()
      : value = '',
        icon = TDIcons.more,
        label = '',
        iconColor = null,
        textColor = null,
        isDivider = true;
}

/// Shows a TDesign styled popup menu
///
/// This is a replacement for Material's PopupMenuButton using TDesign components.
/// Uses a modal barrier with a positioned list of TDCell items.
void showTDPopupMenu({
  required BuildContext context,
  required Offset position,
  required List<TDPopupMenuItem> items,
  required void Function(String value) onSelected,
  double width = 180,
}) {
  final tdTheme = TDTheme.of(context);
  final screenSize = MediaQuery.of(context).size;

  // Calculate position to ensure menu stays within screen bounds
  final left = (position.dx + width > screenSize.width)
      ? screenSize.width - width - 8  // Align to right edge with padding
      : position.dx;
  final top = position.dy;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (dialogContext) {
      return Stack(
        children: [
          // Invisible barrier to detect taps outside menu
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu content
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: tdTheme.bgColorContainer,
                  borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                  border: Border.all(
                    color: tdTheme.componentBorderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tdTheme.grayColor10.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.map((item) {
                      if (item.isDivider) {
                        return TDDivider(
                          margin: EdgeInsets.zero,
                        );
                      }
                      return InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          onSelected(item.value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 18,
                                color: item.iconColor ?? tdTheme.textColorPrimary,
                              ),
                              const SizedBox(width: 12),
                              TDText(
                                item.label,
                                font: tdTheme.fontBodyMedium,
                                textColor: item.textColor ?? tdTheme.textColorPrimary,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// TDesign styled dropdown button that shows a popup menu on tap
///
/// Similar to PopupMenuButton but uses TDesign styling.
class TDPopupMenuButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String? tooltip;
  final List<TDPopupMenuItem> items;
  final void Function(String value) onSelected;

  const TDPopupMenuButton({
    super.key,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.iconSize = 18,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
    final effectiveIconColor = iconColor ?? tdTheme.textColorPrimary;

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: () {
          // Get the button's position
          final renderBox = context.findRenderObject() as RenderBox;
          final offset = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final screenSize = MediaQuery.of(context).size;

          // Calculate menu position - show below button, align to right edge if needed
          final menuWidth = 180.0;
          final left = (offset.dx + size.width / 2 + menuWidth / 2 > screenSize.width)
              ? screenSize.width - menuWidth - 8  // Align to right edge
              : offset.dx + size.width / 2 - menuWidth / 2;  // Center under button
          final top = offset.dy + size.height + 4;

          // Show menu
          showTDPopupMenu(
            context: context,
            position: Offset(left, top),
            items: items,
            onSelected: onSelected,
            width: menuWidth,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: iconSize,
            color: effectiveIconColor,
          ),
        ),
      ),
    );
  }
}

/// Context menu for right-click actions
class TDContextMenuArea extends StatelessWidget {
  final Widget child;
  final List<TDPopupMenuItem> items;
  final void Function(String value) onSelected;

  const TDContextMenuArea({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showTDPopupMenu(
          context: context,
          position: details.globalPosition,
          items: items,
          onSelected: onSelected,
        );
      },
      child: child,
    );
  }
}