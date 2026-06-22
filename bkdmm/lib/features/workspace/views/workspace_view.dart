import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Workspace view - Main project editing interface
///
/// Displays the project
/// - Module list (sidebar)
/// - Entity diagram (canvas)
/// - Properties panel
class WorkspaceView extends ConsumerStatefulWidget {
  const WorkspaceView({super.key});

  @override
  ConsumerState<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends ConsumerState<WorkspaceView> {
  int _selectedModuleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    if (project == null) {
      // No project loaded, return to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: project.name,
      isLoading: projectState.isLoading,
      actions: [
        // Save button
        if (projectState.isDirty)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
            tooltip: 'Save',
          ),
        // More actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save_as',
              child: ListTile(
                leading: Icon(Icons.save_as),
                title: Text('Save As...'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'close',
              child: ListTile(
                leading: Icon(Icons.close),
                title: Text('Close Project'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Project Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      body: Row(
        children: [
          // Module list sidebar
          _buildModuleSidebar(project, theme, colorScheme),

          // Main canvas area
          Expanded(
            child: _buildCanvasArea(project, theme, colorScheme),
          ),

          // Properties panel (optional, can be toggled)
          // For now, just show a placeholder
          SizedBox(
            width: 280,
            child: _buildPropertiesPanel(project, theme, colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addModule,
        tooltip: 'Add Module',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildModuleSidebar(
    dynamic project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final modules = project.modules as List;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modules',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (modules.isNotEmpty)
                  Text(
                    '${modules.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Module list
          Expanded(
            child: modules.isEmpty
                ? _buildEmptyModulesState(theme, colorScheme)
                : ListView.builder(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      final isSelected = _selectedModuleIndex == index;

                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.view_module,
                            size: 18,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          module.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${(module.entities as List).length} entities',
                          style: theme.textTheme.bodySmall,
                        ),
                        selected: isSelected,
                        onTap: () {
                          setState(() => _selectedModuleIndex = index);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyModulesState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_module_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No modules yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addModule,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Module'),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(
    dynamic project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final modules = project.modules as List;

    if (modules.isEmpty) {
      return _buildEmptyCanvas(theme, colorScheme);
    }

    if (_selectedModuleIndex >= modules.length) {
      _selectedModuleIndex = 0;
    }

    final selectedModule = modules[_selectedModuleIndex];
    final entities = selectedModule.entities as List;

    if (entities.isEmpty) {
      return _buildEmptyModuleCanvas(selectedModule.name, theme, colorScheme);
    }

    return Container(
      color: colorScheme.surface,
      child: CustomPaint(
        painter: _GridPainter(colorScheme),
        child: Stack(
          children: [
            // Placeholder for entity nodes
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 64,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Module: ${selectedModule.name}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${entities.length} entities',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCanvas(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Start building your model',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a module to begin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addModule,
            icon: const Icon(Icons.add),
            label: const Text('Add Module'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyModuleCanvas(
    String moduleName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Module: $moduleName',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No entities in this module',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addEntity,
            icon: const Icon(Icons.add),
            label: const Text('Add Entity'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(
    dynamic project,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Properties',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),

          // Project info
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Project name
                _PropertyField(
                  label: 'Project Name',
                  value: project.name,
                ),
                const SizedBox(height: 12),

                // Description
                _PropertyField(
                  label: 'Description',
                  value: project.description ?? 'No description',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Version
                _PropertyField(
                  label: 'Version',
                  value: project.version,
                ),
                const SizedBox(height: 12),

                // Created
                _PropertyField(
                  label: 'Created',
                  value: _formatDateTime(project.createdAt),
                ),
                const SizedBox(height: 12),

                // Updated
                _PropertyField(
                  label: 'Last Modified',
                  value: _formatDateTime(project.updatedAt),
                ),
                const SizedBox(height: 24),

                // Statistics
                Text(
                  'Statistics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _StatTile(
                  icon: Icons.view_module,
                  label: 'Modules',
                  value: '${(project.modules as List).length}',
                ),
                const SizedBox(height: 8),
                _StatTile(
                  icon: Icons.table_chart,
                  label: 'Entities',
                  value: '${_countEntities(project.modules)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countEntities(List modules) {
    int count = 0;
    for (final module in modules) {
      count += (module.entities as List).length;
    }
    return count;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveProject() async {
    try {
      await ref.read(projectProvider.notifier).saveProject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save_as':
        _saveProjectAs();
        break;
      case 'close':
        _closeProject();
        break;
      case 'settings':
        _showProjectSettings();
        break;
    }
  }

  Future<void> _saveProjectAs() async {
    // TODO: Implement save as dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save As coming soon')),
    );
  }

  Future<void> _closeProject() async {
    final projectState = ref.read(projectProvider);

    // Check for unsaved changes
    if (projectState.isDirty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save changes?'),
          content: const Text(
            'The project has unsaved changes. Do you want to save before closing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveProject();
      }
    }

    // Close project and navigate back
    ref.read(projectProvider.notifier).closeProject();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showProjectSettings() {
    // TODO: Implement project settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project settings coming soon')),
    );
  }

  Future<void> _addModule() async {
    final moduleName = await showDialog<String>(
      context: context,
      builder: (context) => _AddModuleDialog(),
    );

    if (moduleName != null && moduleName.isNotEmpty && mounted) {
      // Create a new module with the given name
      final project = ref.read(projectProvider).project;
      if (project != null) {
        // Create a basic module - actual implementation would use proper Module class
        // This is a placeholder that would be replaced with proper module creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Module "$moduleName" would be added')),
        );
      }
    }
  }

  Future<void> _addEntity() async {
    // TODO: Implement add entity dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add entity coming soon')),
    );
  }
}

/// Property field widget
class _PropertyField extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _PropertyField({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Stat tile widget
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Add module dialog
class _AddModuleDialog extends StatefulWidget {
  @override
  State<_AddModuleDialog> createState() => _AddModuleDialogState();
}

class _AddModuleDialogState extends State<_AddModuleDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Module'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Module Name',
          hintText: 'Enter module name',
          prefixIcon: Icon(Icons.view_module),
        ),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? () => _submit(_controller.text) : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit(String value) {
    if (value.trim().isNotEmpty) {
      Navigator.pop(context, value.trim());
    }
  }
}

/// Grid painter for canvas background
class _GridPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _GridPainter(this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
