import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:bkdmm/shared/models/models.dart';

/// Recent project list tile
class RecentProjectTile extends StatelessWidget {
  final ProjectHistory project;
  final bool isSelected;
  final bool isValidating;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecentProjectTile({
    super.key,
    required this.project,
    required this.isSelected,
    this.isValidating = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isValidating
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.primary,
                  ),
                )
              : Icon(
                  TDIcons.file,
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.primary,
                ),
        ),
        title: Text(
          project.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? colorScheme.onPrimaryContainer : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatDateTime(project.lastOpenedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.5)
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: TDButton(
          icon: TDIcons.close,
          type: TDButtonType.text,
          theme: TDButtonTheme.defaultTheme,
          size: TDButtonSize.small,
          onTap: onDelete,
        ),
        onTap: isValidating ? null : onTap,
      ),
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