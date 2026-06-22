import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../providers/entity_provider.dart';
import '../widgets/field_table.dart';
import '../widgets/index_editor.dart';
import '../widgets/code_preview.dart';

/// Entity editor view - Main editor for database tables
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────────────────┐
/// │ Entity Header: TableName[中文名]        [Save]     │
/// ├─────────────────────────────────────────────────────┤
/// │ [摘要] [字段] [索引] [代码预览]                      │
/// ├─────────────────────────────────────────────────────┤
/// │                                                     │
/// │   Tab Content:                                      │
/// │   - 摘要: Basic info form                           │
/// │   - 字段: Syncfusion DataGrid with fields           │
/// │   - 索引: Index management UI                       │
/// │   - 代码预览: Generated DDL preview                 │
/// │                                                     │
/// └─────────────────────────────────────────────────────┘
/// ```
class EntityEditorView extends ConsumerStatefulWidget {
  final Entity entity;
  final String moduleId;

  const EntityEditorView({
    super.key,
    required this.entity,
    required this.moduleId,
  });

  @override
  ConsumerState<EntityEditorView> createState() => _EntityEditorViewState();
}

class _EntityEditorViewState extends ConsumerState<EntityEditorView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _chnnameController;
  late TextEditingController _remarkController;
  bool _hasLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    _titleController = TextEditingController(text: widget.entity.title);
    _chnnameController = TextEditingController(text: widget.entity.chnname);
    _remarkController = TextEditingController(text: widget.entity.remark ?? '');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _titleController.dispose();
    _chnnameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Could trigger any tab-specific logic here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectState = ref.watch(projectProvider);
    final project = projectState.project;

    // Get the current entity from project (to get updates)
    Entity currentEntity = widget.entity;
    if (project != null) {
      for (final module in project.modules) {
        if (module.id == widget.moduleId) {
          final found = module.entities.where((e) => e.id == widget.entity.id).firstOrNull;
          if (found != null) {
            currentEntity = found;
            // Update controllers if entity changed externally
            if (_titleController.text != found.title) {
              _titleController.text = found.title;
            }
            if (_chnnameController.text != found.chnname) {
              _chnnameController.text = found.chnname;
            }
            if (_remarkController.text != (found.remark ?? '')) {
              _remarkController.text = found.remark ?? '';
            }
          }
          break;
        }
      }
    }

    return Column(
      children: [
        // Entity header
        _buildEntityHeader(currentEntity, theme, colorScheme, projectState),

        // Tab bar
        Container(
          color: colorScheme.surfaceContainerLow,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: 'Summary'),
              Tab(icon: Icon(Icons.list_alt), text: 'Fields'),
              Tab(icon: Icon(Icons.sort), text: 'Indexes'),
              Tab(icon: Icon(Icons.code), text: 'Preview'),
            ],
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: colorScheme.outlineVariant,
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(currentEntity, theme, colorScheme),
              _buildFieldsTab(currentEntity, theme, colorScheme),
              _buildIndexesTab(currentEntity, theme, colorScheme),
              _buildPreviewTab(currentEntity, theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntityHeader(
    Entity entity,
    ThemeData theme,
    ColorScheme colorScheme,
    ProjectState projectState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Entity icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.table_chart,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),

          // Entity title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entity.chnname,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list_alt, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${entity.fields.length} fields',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.sort, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${entity.indexes.length} indexes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Save indicator
          if (projectState.isDirty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(
    Entity entity,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Table Name (English)',
                            hintText: 'e.g., user',
                            prefixIcon: Icon(Icons.code),
                          ),
                          onChanged: (value) => _markDirty(),
                          onSubmitted: (value) => _saveBasicInfo(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _chnnameController,
                          decoration: const InputDecoration(
                            labelText: 'Chinese Name',
                            hintText: 'e.g., 用户表',
                            prefixIcon: Icon(Icons.translate),
                          ),
                          onChanged: (value) => _markDirty(),
                          onSubmitted: (value) => _saveBasicInfo(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _remarkController,
                    decoration: const InputDecoration(
                      labelText: 'Remark',
                      hintText: 'Table description',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _markDirty(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_hasLocalChanges)
                        OutlinedButton(
                          onPressed: _resetBasicInfo,
                          child: const Text('Reset'),
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _hasLocalChanges ? _saveBasicInfo : null,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.list_alt,
                          label: 'Fields',
                          value: entity.fields.length.toString(),
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.key,
                          label: 'Primary Keys',
                          value: entity.primaryKeys.length.toString(),
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.sort,
                          label: 'Indexes',
                          value: entity.indexes.length.toString(),
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fields Preview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fields Preview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Fields'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (entity.fields.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.list_alt_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No fields defined yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('PK')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Chinese Name')),
                      ],
                      rows: entity.fields.take(10).map((field) {
                        return DataRow(
                          cells: [
                            DataCell(field.pk
                                ? Icon(Icons.key, size: 16, color: colorScheme.primary)
                                : const SizedBox()),
                            DataCell(Text(field.name)),
                            DataCell(Text(field.type)),
                            DataCell(Text(field.chnname)),
                          ],
                        );
                      }).toList(),
                    ),
                  if (entity.fields.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'And ${entity.fields.length - 10} more fields...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsTab(
    Entity entity,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final dataTypes = ref.watch(dataTypeProvider);

    return FieldTable(
      fields: entity.fields,
      dataTypes: dataTypes,
      onAddField: (field) {
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, fields: [...entity.fields, field]),
        );
      },
      onUpdateField: (fieldId, updatedField) {
        final updatedFields = entity.fields.map((f) {
          return f.id == fieldId ? updatedField : f;
        }).toList();
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, fields: updatedFields),
        );
      },
      onDeleteField: (fieldId) {
        final updatedFields = entity.fields.where((f) => f.id != fieldId).toList();
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, fields: updatedFields),
        );
      },
      onReorderFields: (oldIndex, newIndex) {
        final fields = List<Field>.from(entity.fields);
        final field = fields.removeAt(oldIndex);
        fields.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, field);
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, fields: fields),
        );
      },
    );
  }

  Widget _buildIndexesTab(
    Entity entity,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return IndexEditor(
      indexes: entity.indexes,
      availableFields: entity.fields,
      onAddIndex: (index) {
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, indexes: [...entity.indexes, index]),
        );
      },
      onUpdateIndex: (indexId, updatedIndex) {
        final updatedIndexes = entity.indexes.map((i) {
          return i.id == indexId ? updatedIndex : i;
        }).toList();
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, indexes: updatedIndexes),
        );
      },
      onDeleteIndex: (indexId) {
        final updatedIndexes = entity.indexes.where((i) => i.id != indexId).toList();
        ref.read(projectNotifierProvider.notifier).updateModule(
          widget.moduleId,
          _getUpdatedModule(entity, indexes: updatedIndexes),
        );
      },
    );
  }

  Widget _buildPreviewTab(
    Entity entity,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final databases = ref.watch(databaseProvider);

    return CodePreview(
      entity: entity,
      databases: databases,
      selectedDatabase: 'MYSQL',
      onDatabaseChanged: (db) {
        // Could store preference per entity
      },
    );
  }

  Module _getUpdatedModule(Entity entity, {List<Field>? fields, List<Index>? indexes}) {
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) throw StateError('No project loaded');

    final module = project.modules.firstWhere(
      (m) => m.id == widget.moduleId,
      orElse: () => throw StateError('Module not found'),
    );

    final updatedEntities = module.entities.map((e) {
      if (e.id == entity.id) {
        return entity.copyWith(
          fields: fields ?? e.fields,
          indexes: indexes ?? e.indexes,
          updatedAt: DateTime.now(),
        );
      }
      return e;
    }).toList();

    return module.copyWith(
      entities: updatedEntities,
      updatedAt: DateTime.now(),
    );
  }

  void _markDirty() {
    if (!_hasLocalChanges) {
      setState(() => _hasLocalChanges = true);
    }
  }

  void _saveBasicInfo() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    final project = ref.read(projectNotifierProvider).project;
    if (project == null) return;

    final modules = project.modules.map((m) {
      if (m.id == widget.moduleId) {
        final entities = m.entities.map((e) {
          if (e.id == widget.entity.id) {
            return e.copyWith(
              title: _titleController.text.trim(),
              chnname: _chnnameController.text.trim(),
              remark: _remarkController.text.trim().isNotEmpty
                  ? _remarkController.text.trim()
                  : null,
              updatedAt: DateTime.now(),
            );
          }
          return e;
        }).toList();
        return m.copyWith(entities: entities, updatedAt: DateTime.now());
      }
      return m;
    }).toList();

    final updatedProject = project.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );
    projectNotifier.updateProject(updatedProject);

    setState(() => _hasLocalChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entity updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetBasicInfo() {
    _titleController.text = widget.entity.title;
    _chnnameController.text = widget.entity.chnname;
    _remarkController.text = widget.entity.remark ?? '';
    setState(() => _hasLocalChanges = false);
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}