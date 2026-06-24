import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/models.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      history.path,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(history.lastOpenedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? _buildPopupMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
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
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new),
              SizedBox(width: 12),
              Text('Open'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                isFavorite ? Icons.star : Icons.star_outline,
              ),
              const SizedBox(width: 12),
              Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            ],
          ),
        ),
        if (onDuplicate != null)
          const PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.content_copy),
                SizedBox(width: 12),
                Text('Duplicate'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 12),
              Text('Remove from List'),
            ],
          ),
        ),
      ],
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
    this.icon = Icons.description,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? _formatTimestamp(timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
            ],
          ),
        ),
      ),
    );
  }
}