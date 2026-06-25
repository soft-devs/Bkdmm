import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../shared/models/models.dart';

/// Recent projects list widget
class RecentProjectsList extends StatelessWidget {
  /// List of recent projects
  final List<ProjectHistory> projects;

  /// Callback when a project is tapped
  final void Function(ProjectHistory project)? onProjectTap;

  /// Callback when remove is requested
  final void Function(ProjectHistory project)? onRemove;

  /// Maximum number of projects to show
  final int maxItems;

  const RecentProjectsList({
    super.key,
    required this.projects,
    this.onProjectTap,
    this.onRemove,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayProjects = projects.take(maxItems).toList();

    if (displayProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TDIcons.history,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent projects',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: displayProjects.length,
      itemBuilder: (context, index) {
        final project = displayProjects[index];
        return ListTile(
          leading: const Icon(TDIcons.file),
          title: Text(project.name),
          subtitle: Text(
            project.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TDButton(
            icon: TDIcons.close,
            type: TDButtonType.text,
            theme: TDButtonTheme.defaultTheme,
            size: TDButtonSize.small,
            onTap: () => onRemove?.call(project),
          ),
          onTap: () => onProjectTap?.call(project),
        );
      },
    );
  }
}