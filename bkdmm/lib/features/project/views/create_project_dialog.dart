import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

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

    return AlertDialog(
      title: const Text('Create New Project'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  if (value.contains(RegExp(r'[<>:"/\\|?*]'))) {
                    return 'Project name contains invalid characters';
                  }
                  return null;
                },
                autofocus: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter project description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: 16),

              // File path field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pathController,
                      decoration: const InputDecoration(
                        labelText: 'Save Location *',
                        hintText: 'Choose save location',
                        prefixIcon: Icon(Icons.save_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Save location is required';
                        }
                        if (!value.endsWith('.bkdmm.json')) {
                          return 'File must end with .bkdmm.json';
                        }
                        return null;
                      },
                      onChanged: (_) => _clearError(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _pickSaveLocation,
                    icon: const Icon(Icons.folder_open_outlined),
                    tooltip: 'Browse',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick location buttons
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _setQuickLocation('Documents'),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('Documents'),
                  ),
                  TextButton.icon(
                    onPressed: () => _setQuickLocation('Desktop'),
                    icon: const Icon(Icons.desktop_windows, size: 16),
                    label: const Text('Desktop'),
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
                        Icons.error_outline,
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
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isCreating ? null : _createProject,
          icon: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
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
    if (!_formKey.currentState!.validate()) {
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
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Project name is required';
              }
              return null;
            },
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
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
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await CreateProjectDialog.show(context);
        if (result != null) {
          onCreated?.call(result);
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('New Project'),
    );
  }
}