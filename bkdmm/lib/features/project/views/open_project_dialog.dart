import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/models.dart';

/// Open project dialog - Dialog for opening existing projects
///
/// Provides options to:
/// - Browse for project files
/// - Select from recent projects
/// - Preview project details before opening
class OpenProjectDialog extends StatefulWidget {
  /// List of recent projects to display
  final List<ProjectHistory>? recentProjects;

  /// Callback when a project is selected
  final void Function(String filePath)? onProjectSelected;

  const OpenProjectDialog({
    super.key,
    this.recentProjects,
    this.onProjectSelected,
  });

  /// Show the dialog and return the selected file path
  static Future<String?> show(
    BuildContext context, {
    List<ProjectHistory>? recentProjects,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => OpenProjectDialog(
        recentProjects: recentProjects,
      ),
    );
  }

  @override
  State<OpenProjectDialog> createState() => _OpenProjectDialogState();
}

class _OpenProjectDialogState extends State<OpenProjectDialog> {
  String? _selectedPath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentProjects = widget.recentProjects ?? <ProjectHistory>[];

    return AlertDialog(
      title: const Text('Open Project'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browse button
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _browseForProject,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Browse for Project File'),
              ),
            ),

            // Divider with label
            if (recentProjects.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Recent Projects',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Recent projects list
              Expanded(
                child: ListView.builder(
                  itemCount: recentProjects.length,
                  itemBuilder: (context, index) {
                    final project = recentProjects[index];
                    final isSelected = _selectedPath == project.path;

                    return _RecentProjectTile(
                      project: project,
                      isSelected: isSelected,
                      onTap: () => _selectProject(project.path),
                      onDelete: () => _removeRecent(project.path),
                    );
                  },
                ),
              ),
            ],

            // Empty state
            if (recentProjects.isEmpty) ...[
              const Spacer(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent projects',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse for a project file to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selectedPath != null && !_isLoading
              ? _openSelectedProject
              : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.open_in_new),
          label: const Text('Open'),
        ),
      ],
    );
  }

  Future<void> _browseForProject() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bkdmm.json'],
        dialogTitle: 'Open Project',
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          if (mounted) {
            Navigator.of(context).pop(path);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProject(String path) {
    setState(() => _selectedPath = path);
  }

  void _removeRecent(String path) {
    // This would typically call a service to remove from history
    // For now, just deselect if it was selected
    if (_selectedPath == path) {
      setState(() => _selectedPath = null);
    }
  }

  void _openSelectedProject() {
    if (_selectedPath != null) {
      widget.onProjectSelected?.call(_selectedPath!);
      Navigator.of(context).pop(_selectedPath);
    }
  }
}

/// Recent project list tile
class _RecentProjectTile extends StatelessWidget {
  final ProjectHistory project;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentProjectTile({
    required this.project,
    required this.isSelected,
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
          child: Icon(
            Icons.description_outlined,
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
        trailing: IconButton(
          icon: const Icon(Icons.close),
          iconSize: 18,
          onPressed: onDelete,
          tooltip: 'Remove from list',
        ),
        onTap: onTap,
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

/// Quick open project button
class QuickOpenProjectButton extends StatelessWidget {
  /// Callback when a project is selected
  final void Function(String filePath)? onProjectOpened;

  const QuickOpenProjectButton({
    super.key,
    this.onProjectOpened,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bkdmm.json'],
          dialogTitle: 'Open Project',
        );

        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            onProjectOpened?.call(path);
          }
        }
      },
      icon: const Icon(Icons.folder_open_outlined),
      tooltip: 'Open Project',
    );
  }
}

/// Project file picker widget for embedding in other views
class ProjectFilePicker extends StatefulWidget {
  /// Currently selected file path
  final String? selectedPath;

  /// Callback when a file is selected
  final void Function(String? path)? onPathChanged;

  /// Label for the picker
  final String label;

  const ProjectFilePicker({
    super.key,
    this.selectedPath,
    this.onPathChanged,
    this.label = 'Project File',
  });

  @override
  State<ProjectFilePicker> createState() => _ProjectFilePickerState();
}

class _ProjectFilePickerState extends State<ProjectFilePicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedPath);
  }

  @override
  void didUpdateWidget(ProjectFilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPath != widget.selectedPath) {
      _controller.text = widget.selectedPath ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.description_outlined),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_outlined),
          tooltip: 'Browse',
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: 'Select ${widget.label}',
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        _controller.text = path;
        widget.onPathChanged?.call(path);
      }
    }
  }
}

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
              Icons.history,
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
          leading: const Icon(Icons.description_outlined),
          title: Text(project.name),
          subtitle: Text(
            project.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            onPressed: () => onRemove?.call(project),
          ),
          onTap: () => onProjectTap?.call(project),
        );
      },
    );
  }
}