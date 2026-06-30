import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/widgets/td_popup_menu.dart';

/// A list tile widget for displaying project history items.
///
/// Provides a consistent layout for history items with:
/// - Leading icon/avatar
/// - Title and subtitle
/// - Timestamp
/// - Optional trailing action menu
class HistoryListTile extends StatelessWidget {
  /// Creates a history list tile.
  const HistoryListTile({
    super.key,
    required this.history,
    required this.onTap,
    required this.onDelete,
    this.onFavorite,
    this.onDuplicate,
    this.isFavorite = false,
    this.trailing,
  });

  /// The project history item to display.
  final ProjectHistory history;

  /// Callback when the tile is tapped.
  final VoidCallback onTap;

  /// Callback when delete is requested.
  final VoidCallback onDelete;

  /// Callback when favorite is toggled.
  final VoidCallback? onFavorite;

  /// Callback when duplicate is requested.
  final VoidCallback? onDuplicate;

  /// Whether this item is marked as favorite.
  final bool isFavorite;

  /// Optional custom trailing widget (replaces menu button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tdTheme.brandLightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  TDIcons.file,
                  color: tdTheme.brandNormalColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TDText(
                      history.name,
                      font: tdTheme.fontBodyLarge,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    TDText(
                      history.path,
                      font: tdTheme.fontBodySmall,
                      textColor: tdTheme.fontGyColor3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    TDText(
                      _formatDateTime(history.lastOpenedAt),
                      font: tdTheme.fontBodySmall,
                      textColor: tdTheme.fontGyColor4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? _buildPopupMenu(context, tdTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, TDThemeData tdTheme) {
    return TDPopupMenuButton(
      icon: TDIcons.more,
      iconColor: tdTheme.fontGyColor3,
      items: [
        TDPopupMenuItem(
          value: 'open',
          icon: TDIcons.folder_open,
          label: 'Open',
        ),
        TDPopupMenuItem(
          value: 'favorite',
          icon: isFavorite ? TDIcons.star_filled : TDIcons.star,
          label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        ),
        if (onDuplicate != null)
          TDPopupMenuItem(
            value: 'duplicate',
            icon: TDIcons.copy,
            label: 'Duplicate',
          ),
        TDPopupMenuItem(
          value: 'delete',
          icon: TDIcons.delete,
          label: 'Remove from List',
          iconColor: tdTheme.errorNormalColor,
          textColor: tdTheme.errorNormalColor,
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'open':
            onTap();
            break;
          case 'favorite':
            onFavorite?.call();
            break;
          case 'duplicate':
            onDuplicate?.call();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }
}

/// A simplified history list tile for basic use cases.
class HistoryListTileSimple extends StatelessWidget {
  /// Creates a simple history list tile.
  const HistoryListTileSimple({
    super.key,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.icon = TDIcons.file,
    this.onTap,
    this.onDelete,
  });

  /// The title of the history item.
  final String title;

  /// When the item was last modified.
  final DateTime timestamp;

  /// Optional subtitle.
  final String? subtitle;

  /// The icon to display.
  final IconData icon;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Callback when delete is requested.
  final VoidCallback? onDelete;

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Modified ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Modified ${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return 'Modified ${difference.inDays} days ago';
    } else {
      return 'Modified on ${time.month}/${time.day}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        border: Border.all(color: tdTheme.componentBorderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tdTheme.brandLightColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: tdTheme.brandNormalColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TDText(
                      title,
                      font: tdTheme.fontBodyLarge,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 4),
                    TDText(
                      subtitle ?? _formatTimestamp(timestamp),
                      font: tdTheme.fontBodyMedium,
                      textColor: tdTheme.fontGyColor3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onDelete != null)
                TDButton(
                  icon: TDIcons.close,
                  theme: TDButtonTheme.defaultTheme,
                  type: TDButtonType.text,
                  size: TDButtonSize.small,
                  onTap: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
