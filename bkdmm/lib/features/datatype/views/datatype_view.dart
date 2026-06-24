import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../shared/models/models.dart';
import '../../../shared/constants/default_data_types.dart';
import '../../../shared/providers/providers.dart';
import '../providers/datatype_provider.dart';
import 'datatype_edit_dialog.dart';

/// Data type management view
class DataTypeView extends ConsumerStatefulWidget {
  const DataTypeView({super.key});

  @override
  ConsumerState<DataTypeView> createState() => _DataTypeViewState();
}

class _DataTypeViewState extends ConsumerState<DataTypeView> {
  String _searchQuery = '';
  bool _showDefaultTypes = true;
  bool _showCustomTypes = true;
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    // Initialize data types from current project
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromProject();
    });
  }

  void _initializeFromProject() {
    final project = ref.read(currentProjectProvider);
    if (project != null) {
      ref.read(dataTypeNotifierProvider.notifier).initialize(project.dataTypeDomains);
    }
  }

  List<DataType> _filterTypes(List<DataType> types) {
    if (_searchQuery.isEmpty) return types;
    final query = _searchQuery.toLowerCase();
    return types.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.chnname.toLowerCase().contains(query) ||
          (t.remark?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(dataTypeNotifierProvider);

    final defaultTypes = _filterTypes(state.defaultTypes);
    final customTypes = _filterTypes(state.customTypes);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, colorScheme, state),

          // Search and filter bar
          _buildSearchBar(theme, colorScheme),

          // Content
          Expanded(
            child: state.dataTypes.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : _buildTypeList(theme, colorScheme, defaultTypes, customTypes),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    DataTypeState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TDIcons.data_object,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Data Type Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.dataTypes.length} types',
              style: theme.textTheme.labelSmall,
            ),
          ),
          if (state.isDirty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Modified',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          const Spacer(),
          // Action buttons
          TDButton(
            text: 'Restore Defaults',
            theme: TDButtonTheme.defaultTheme,
            icon: TDIcons.restore,
            onTap: () => _showRestoreDefaultsDialog(),
          ),
          const SizedBox(width: 8),
          TDButton(
            text: 'Add Type',
            theme: TDButtonTheme.primary,
            icon: TDIcons.add,
            onTap: () => _showAddDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TDInput(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search types...',
                prefixIcon: const Icon(TDIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter toggles
          FilterChip(
            label: const Text('Default Types'),
            selected: _showDefaultTypes,
            onSelected: (selected) {
              setState(() {
                _showDefaultTypes = selected;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Custom Types'),
            selected: _showCustomTypes,
            onSelected: (selected) {
              setState(() {
                _showCustomTypes = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TDIcons.data_object_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No data types found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Restore Defaults" to load default types',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<DataType> defaultTypes,
    List<DataType> customTypes,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default types section
        if (_showDefaultTypes && defaultTypes.isNotEmpty) ...[
          _buildSectionHeader(
            'Default Types',
            '${defaultTypes.length}',
            TDIcons.bookmark,
            colorScheme,
          ),
          const SizedBox(height: 8),
          ...defaultTypes.map((type) => _buildTypeCard(type, theme, colorScheme)),
          const SizedBox(height: 24),
        ],

        // Custom types section
        if (_showCustomTypes && customTypes.isNotEmpty) ...[
          _buildSectionHeader(
            'Custom Types',
            '${customTypes.length}',
            TDIcons.extension,
            colorScheme,
          ),
          const SizedBox(height: 8),
          ...customTypes.map((type) => _buildTypeCard(type, theme, colorScheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String count,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    DataType type,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDefault = DefaultDataTypes.isDefaultType(type.id);
    final isSelected = _selectedTypeId == type.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTypeId = isSelected ? null : type.id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(type.name),
                      size: 20,
                      color: isDefault
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              type.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type.chnname,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (type.remark != null && type.remark!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              type.remark!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(TDIcons.more_vert),
                    onSelected: (action) => _handleTypeAction(type, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(TDIcons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(TDIcons.copy),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(TDIcons.delete, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Type mappings
              if (isSelected) ...[
                const SizedBox(height: 16),
                _buildTypeMappings(type, theme, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeMappings(
    DataType type,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Database Mappings',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DatabaseCodes.all.map((dbCode) {
            final dbType = type.apply[dbCode];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DatabaseCodes.getDisplayName(dbCode),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dbType ?? '-',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (type.java != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Java: ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type.java!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getTypeIcon(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'idorkey':
        return TDIcons.key;
      case 'name':
        return TDIcons.label;
      case 'intro':
        return TDIcons.short_text;
      case 'longtext':
        return TDIcons.notes;
      case 'integer':
        return TDIcons.filter_1;
      case 'long':
        return TDIcons.filter_9_plus;
      case 'money':
        return TDIcons.attach_money;
      case 'datetime':
        return TDIcons.schedule;
      case 'yesno':
        return TDIcons.check_box;
      case 'dict':
        return TDIcons.book;
      default:
        return TDIcons.data_object;
    }
  }

  void _handleTypeAction(DataType type, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(type);
        break;
      case 'duplicate':
        _duplicateType(type);
        break;
      case 'delete':
        _showDeleteDialog(type);
        break;
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => DataTypeEditDialog(
        onSave: (newType) {
          final notifier = ref.read(dataTypeNotifierProvider.notifier);
          final created = notifier.createNewDataType(
            name: newType.name,
            chnname: newType.chnname,
            remark: newType.remark,
            apply: newType.apply,
            java: newType.java,
          );
          if (notifier.addDataType(created)) {
            _updateProject();
          }
        },
      ),
    );
  }

  void _showEditDialog(DataType type) {
    showDialog(
      context: context,
      builder: (context) => DataTypeEditDialog(
        existingType: type,
        onSave: (updated) {
          if (ref.read(dataTypeNotifierProvider.notifier).updateDataType(type.id, updated)) {
            _updateProject();
          }
        },
      ),
    );
  }

  void _duplicateType(DataType type) {
    ref.read(dataTypeNotifierProvider.notifier).duplicateDataType(type.id);
    _updateProject();
  }

  void _showDeleteDialog(DataType type) {
    final project = ref.read(currentProjectProvider);
    final modules = project?.modules ?? [];

    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: const Text('Delete Data Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${type.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        actions: [
          TDButton(
            text: 'Cancel',
            theme: TDButtonTheme.defaultTheme,
            onTap: () => Navigator.pop(context),
          ),
          TDButton(
            text: 'Delete',
            theme: TDButtonTheme.danger,
            onTap: () {
              final usage = ref
                  .read(dataTypeNotifierProvider.notifier)
                  .deleteDataType(type.id, modules);

              if (usage != null && usage.isNotEmpty) {
                // Type is in use, show warning
                Navigator.pop(context);
                _showUsageWarning(type, usage);
              } else if (usage == null) {
                // Deleted successfully
                Navigator.pop(context);
                _updateProject();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUsageWarning(DataType type, Map<String, List<String>> usage) {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: const Text('Type In Use'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The type "${type.name}" is used in the following fields:'),
              const SizedBox(height: 16),
              ...usage.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(TDIcons.table_chart, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.key}: ${entry.value.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Do you want to delete it anyway? Fields using this type may break.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TDButton(
            text: 'Cancel',
            theme: TDButtonTheme.defaultTheme,
            onTap: () => Navigator.pop(context),
          ),
          TDButton(
            text: 'Delete Anyway',
            theme: TDButtonTheme.danger,
            onTap: () {
              ref.read(dataTypeNotifierProvider.notifier).forceDeleteDataType(type.id);
              Navigator.pop(context);
              _updateProject();
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreDefaultsDialog() {
    showDialog(
      context: context,
      builder: (context) => TDAlertDialog(
        title: const Text('Restore Defaults'),
        content: const Text(
          'This will restore all default data types to their original values. Custom types will not be affected.',
        ),
        actions: [
          TDButton(
            text: 'Cancel',
            theme: TDButtonTheme.defaultTheme,
            onTap: () => Navigator.pop(context),
          ),
          TDButton(
            text: 'Restore',
            theme: TDButtonTheme.primary,
            onTap: () {
              ref.read(dataTypeNotifierProvider.notifier).restoreDefaults();
              Navigator.pop(context);
              _updateProject();
            },
          ),
        ],
      ),
    );
  }

  void _updateProject() {
    final project = ref.read(currentProjectProvider);
    if (project == null) return;

    final domains = ref.read(dataTypeNotifierProvider.notifier).toDataTypeDomains();
    final updated = project.copyWith(
      dataTypeDomains: domains,
      updatedAt: DateTime.now(),
    );
    ref.read(projectProvider.notifier).updateProject(updated);
  }
}
