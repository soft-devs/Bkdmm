import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'dart:io';

import 'package:bkdmm/shared/models/models.dart';
import 'package:bkdmm/shared/utils/responsive_utils.dart';
import '../widgets/recent_project_tile.dart';

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
  String? _error;
  String? _validatingPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentProjects = widget.recentProjects ?? <ProjectHistory>[];

    // Responsive dialog dimensions using utility
    final dialogSize = ResponsiveUtils.getDialogSize(context, DialogSizePreset.project);

    return TDAlertDialog(
      title: 'Open Project',
      contentWidget: SizedBox(
        width: dialogSize.width,
        height: dialogSize.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browse button
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TDButton(
                text: 'Browse for Project File',
                icon: _isLoading && _validatingPath != null
                    ? null
                    : TDIcons.folder_open,
                theme: TDButtonTheme.primary,
                type: TDButtonType.fill,
                onTap: _isLoading ? null : _browseForProject,
                isBlock: true,
              ),
            ),

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      TDIcons.close_circle,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TDButton(
                      icon: TDIcons.close,
                      type: TDButtonType.text,
                      theme: TDButtonTheme.defaultTheme,
                      size: TDButtonSize.small,
                      onTap: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ],

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
                    final isValidating = _validatingPath == project.path;

                    return RecentProjectTile(
                      project: project,
                      isSelected: isSelected,
                      isValidating: isValidating,
                      onTap: () => _selectAndValidateProject(project.path),
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
                      TDIcons.folder_open,
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
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: _isLoading ? null : () => Navigator.of(context).pop(),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Open',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: _selectedPath != null && !_isLoading ? _openSelectedProject : null,
      ),
    );
  }

  /// Validate if a file is a valid project file
  Future<bool> _validateProjectFile(String filePath) async {
    try {
      // Check file extension
      if (!filePath.endsWith('.bkdmm.json')) {
        _error = 'Invalid file type. Please select a .bkdmm.json file.';
        return false;
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        _error = 'File does not exist: $filePath';
        return false;
      }

      // Try to read and parse the file
      final content = await file.readAsString();
      if (content.isEmpty) {
        _error = 'File is empty';
        return false;
      }

      // Basic JSON structure validation
      // The actual project parsing will be done by ProjectNotifier
      return true;
    } catch (e) {
      _error = 'Failed to validate file: $e';
      return false;
    }
  }

  Future<void> _browseForProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _validatingPath = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bkdmm.json', 'json'],
        dialogTitle: 'Open Project',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          // Validate the file
          final isValid = await _validateProjectFile(filePath);
          if (isValid && mounted) {
            Navigator.of(context).pop(filePath);
          } else {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to browse files: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectAndValidateProject(String path) async {
    setState(() {
      _validatingPath = path;
      _isLoading = true;
      _error = null;
    });

    try {
      final isValid = await _validateProjectFile(path);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _validatingPath = null;
          if (isValid) {
            _selectedPath = path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _validatingPath = null;
        });
      }
    }
  }

  Future<void> _removeRecent(String path) async {
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