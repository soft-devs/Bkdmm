import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Create project dialog - Dialog for creating new projects
///
/// Provides a form for users to:
/// - Enter project name and description
/// - Choose save location
/// - Configure initial project settings
class CreateProjectDialog extends StatefulWidget {
  /// Default project name
  final String? defaultName;

  /// Default save path
  final String? defaultPath;

  /// Callback when project is created
  final void Function(String name, String? description, String filePath)? onCreate;

  const CreateProjectDialog({
    super.key,
    this.defaultName,
    this.defaultPath,
    this.onCreate,
  });

  /// Show the dialog and return the result
  static Future<CreateProjectResult?> show(
    BuildContext context, {
    String? defaultName,
    String? defaultPath,
  }) {
    return showDialog<CreateProjectResult>(
      context: context,
      builder: (context) => CreateProjectDialog(
        defaultName: defaultName,
        defaultPath: defaultPath,
      ),
    );
  }

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pathController = TextEditingController();

  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.defaultName ?? '';
    _pathController.text = widget.defaultPath ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TDAlertDialog(
      title: 'Create New Project',
      contentWidget: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project name field
              TDInput(
                controller: _nameController,
                leftLabel: 'Project Name *',
                hintText: 'Enter project name',
                backgroundColor: Colors.transparent,
                leftIcon: const Icon(TDIcons.folder),
                onChanged: (_) => _clearError(),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Description field (multiline)
              TDInput(
                controller: _descriptionController,
                leftLabel: 'Description',
                hintText: 'Enter project description (optional)',
                backgroundColor: Colors.transparent,
                leftIcon: const Icon(TDIcons.edit),
                maxLines: 3,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 16),

              // File path field
              Row(
                children: [
                  Expanded(
                    child: TDInput(
                      controller: _pathController,
                      leftLabel: 'Save Location *',
                      hintText: 'Choose save location',
                      backgroundColor: Colors.transparent,
                      leftIcon: const Icon(TDIcons.save),
                      onChanged: (_) => _clearError(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TDButton(
                    onTap: _pickSaveLocation,
                    icon: TDIcons.folder_open,
                    type: TDButtonType.outline,
                    theme: TDButtonTheme.defaultTheme,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick location buttons
              Wrap(
                spacing: 8,
                children: [
                  TDButton(
                    onTap: () => _setQuickLocation('Documents'),
                    icon: TDIcons.file,
                    text: 'Documents',
                    type: TDButtonType.text,
                    theme: TDButtonTheme.defaultTheme,
                    size: TDButtonSize.small,
                  ),
                  TDButton(
                    onTap: () => _setQuickLocation('Desktop'),
                    icon: TDIcons.desktop,
                    text: 'Desktop',
                    type: TDButtonType.text,
                    theme: TDButtonTheme.defaultTheme,
                    size: TDButtonSize.small,
                  ),
                ],
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      leftBtn: TDDialogButtonOptions(
        title: 'Cancel',
        theme: TDButtonTheme.defaultTheme,
        type: TDButtonType.text,
        action: _isCreating ? null : () => Navigator.of(context).pop(),
      ),
      rightBtn: TDDialogButtonOptions(
        title: 'Create',
        theme: TDButtonTheme.primary,
        type: TDButtonType.fill,
        action: _isCreating ? null : _createProject,
      ),
    );
  }

  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _pickSaveLocation() async {
    final projectName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'project';

    // Sanitize project name for filename
    final sanitized = projectName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: 'Choose Save Location',
      fileName: '$sanitized.bkdmm.json',
    );

    if (result != null) {
      // Ensure file ends with .bkdmm.json
      String finalPath = result;
      if (!finalPath.endsWith('.bkdmm.json')) {
        finalPath = '$finalPath.bkdmm.json';
      }
      setState(() {
        _pathController.text = finalPath;
      });
    }
  }

  Future<void> _setQuickLocation(String location) async {
    String? basePath;

    // Try to get common folder paths
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select $location Folder',
      );
      basePath = result;
    } catch (_) {
      // Ignore errors
    }

    if (basePath != null) {
      final projectName = _nameController.text.isNotEmpty
          ? _nameController.text
          : 'project';
      setState(() {
        _pathController.text = '$basePath/$projectName.bkdmm.json';
      });
    }
  }

  Future<void> _createProject() async {
    // Manual validation since TDInput doesn't have built-in validator
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Project name is required');
      return;
    }
    if (_nameController.text.contains(RegExp(r'[<>:"/\\|?*]'))) {
      setState(() => _error = 'Project name contains invalid characters');
      return;
    }
    if (_pathController.text.trim().isEmpty) {
      setState(() => _error = 'Save location is required');
      return;
    }
    if (!_pathController.text.endsWith('.bkdmm.json')) {
      setState(() => _error = 'File must end with .bkdmm.json');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final filePath = _pathController.text.trim();

      // Call the callback if provided
      widget.onCreate?.call(name, description.isEmpty ? null : description, filePath);

      // Return result
      if (mounted) {
        Navigator.of(context).pop(CreateProjectResult(
          name: name,
          description: description.isEmpty ? null : description,
          filePath: filePath,
        ));
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create project: $e';
        _isCreating = false;
      });
    }
  }
}

/// Result of the create project dialog
class CreateProjectResult {
  /// Project name
  final String name;

  /// Project description
  final String? description;

  /// File path
  final String filePath;

  CreateProjectResult({
    required this.name,
    this.description,
    required this.filePath,
  });
}

/// Simple create project form for embedding in other widgets
class CreateProjectForm extends StatefulWidget {
  /// Callback when form is submitted
  final void Function(String name, String? description)? onSubmit;

  /// Initial project name
  final String? initialName;

  const CreateProjectForm({
    super.key,
    this.onSubmit,
    this.initialName,
  });

  @override
  State<CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<CreateProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TDInput(
            controller: _nameController,
            leftLabel: 'Project Name',
            hintText: 'Enter project name',
            backgroundColor: Colors.transparent,
            leftIcon: const Icon(TDIcons.folder),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TDInput(
            controller: _descriptionController,
            leftLabel: 'Description (optional)',
            hintText: 'Enter project description',
            backgroundColor: Colors.transparent,
            leftIcon: const Icon(TDIcons.edit),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          TDButton(
            text: 'Create Project',
            theme: TDButtonTheme.primary,
            type: TDButtonType.fill,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_nameController.text.trim().isNotEmpty) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      widget.onSubmit?.call(name, description.isEmpty ? null : description);
    }
  }
}

/// Quick project creation button with dialog
class QuickCreateProjectButton extends StatelessWidget {
  /// Callback when project is created
  final void Function(CreateProjectResult result)? onCreated;

  const QuickCreateProjectButton({
    super.key,
    this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    return TDButton(
      onTap: () async {
        final result = await CreateProjectDialog.show(context);
        if (result != null) {
          onCreated?.call(result);
        }
      },
      icon: TDIcons.add,
      text: 'New Project',
      theme: TDButtonTheme.primary,
      type: TDButtonType.fill,
    );
  }
}
