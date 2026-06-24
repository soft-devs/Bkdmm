import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../providers/entity_provider.dart';
import '../widgets/field_table.dart';
import '../widgets/index_editor.dart';
import '../widgets/code_preview.dart';

/// Entity editor view - Main editor for database tables
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
  }

  @override
  Widget build(BuildContext context) {
    final tdTheme = TDTheme.of(context);
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
        _buildEntityHeader(currentEntity, tdTheme, projectState),

        // Tab bar
        Container(
          color: tdTheme.bgColorSecondaryContainer,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(TDIcons.info_circle, color: tdTheme.textColorSecondary), text: 'Summary'),
              Tab(icon: Icon(TDIcons.view_list, color: tdTheme.textColorSecondary), text: 'Fields'),
              Tab(icon: Icon(TDIcons.filter, color: tdTheme.textColorSecondary), text: 'Indexes'),
              Tab(icon: Icon(TDIcons.code, color: tdTheme.textColorSecondary), text: 'Preview'),
            ],
            labelColor: tdTheme.brandNormalColor,
            unselectedLabelColor: tdTheme.textColorSecondary,
            indicatorColor: tdTheme.brandNormalColor,
            dividerColor: tdTheme.componentBorderColor,
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(currentEntity, tdTheme),
              _buildFieldsTab(currentEntity),
              _buildIndexesTab(currentEntity),
              _buildPreviewTab(currentEntity),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntityHeader(
    Entity entity,
    TDThemeData tdTheme,
    ProjectState projectState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tdTheme.bgColorContainer,
        border: Border(
          bottom: BorderSide(color: tdTheme.componentBorderColor),
        ),
      ),
      child: Row(
        children: [
          // Entity icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tdTheme.brandLightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              TDIcons.table,
              color: tdTheme.brandNormalColor,
            ),
          ),
          const SizedBox(width: 12),

          // Entity title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  entity.title,
                  font: tdTheme.fontTitleMedium,
                  fontWeight: FontWeight.w600,
                ),
                TDText(
                  entity.chnname,
                  font: tdTheme.fontBodySmall,
                  textColor: tdTheme.textColorSecondary,
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tdTheme.bgColorSecondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TDIcons.view_list, size: 14, color: tdTheme.textColorSecondary),
                const SizedBox(width: 4),
                TDText(
                  '${entity.fields.length} fields',
                  font: tdTheme.fontMarkExtraSmall,
                  textColor: tdTheme.textColorSecondary,
                ),
                const SizedBox(width: 12),
                Icon(TDIcons.filter, size: 14, color: tdTheme.textColorSecondary),
                const SizedBox(width: 4),
                TDText(
                  '${entity.indexes.length} indexes',
                  font: tdTheme.fontMarkExtraSmall,
                  textColor: tdTheme.textColorSecondary,
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
                color: tdTheme.brandLightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(TDIcons.circle, size: 8, color: tdTheme.brandNormalColor),
                  const SizedBox(width: 4),
                  TDText(
                    'Unsaved',
                    font: tdTheme.fontMarkExtraSmall,
                    textColor: tdTheme.brandNormalColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(Entity entity, TDThemeData tdTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          Container(
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  'Basic Information',
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TDInput(
                        controller: _titleController,
                        leftLabel: 'Table Name (English)',
                        hintText: 'e.g., user',
                        leftIcon: const Icon(TDIcons.code),
                        backgroundColor: Colors.transparent,
                        onChanged: (value) => _markDirty(),
                        onSubmitted: (value) => _saveBasicInfo(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TDInput(
                        controller: _chnnameController,
                        leftLabel: 'Chinese Name',
                        hintText: 'e.g., 用户表',
                        leftIcon: const Icon(TDIcons.translate),
                        backgroundColor: Colors.transparent,
                        onChanged: (value) => _markDirty(),
                        onSubmitted: (value) => _saveBasicInfo(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TDInput(
                  controller: _remarkController,
                  leftLabel: 'Remark',
                  hintText: 'Table description',
                  leftIcon: const Icon(TDIcons.edit),
                  backgroundColor: Colors.transparent,
                  maxLines: 3,
                  onChanged: (value) => _markDirty(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_hasLocalChanges)
                      TDButton(
                        text: 'Reset',
                        theme: TDButtonTheme.defaultTheme,
                        type: TDButtonType.outline,
                        onTap: _resetBasicInfo,
                      ),
                    const SizedBox(width: 8),
                    TDButton(
                      text: 'Save Changes',
                      icon: TDIcons.save,
                      theme: TDButtonTheme.primary,
                      type: TDButtonType.fill,
                      disabled: !_hasLocalChanges,
                      onTap: _saveBasicInfo,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Card
          Container(
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  'Statistics',
                  font: tdTheme.fontTitleSmall,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: TDIcons.view_list,
                        label: 'Fields',
                        value: entity.fields.length.toString(),
                        color: tdTheme.brandNormalColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: TDIcons.lock_on,
                        label: 'Primary Keys',
                        value: entity.primaryKeys.length.toString(),
                        color: tdTheme.successColor5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: TDIcons.filter,
                        label: 'Indexes',
                        value: entity.indexes.length.toString(),
                        color: tdTheme.warningColor5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fields Preview Card
          Container(
            decoration: BoxDecoration(
              color: tdTheme.bgColorContainer,
              borderRadius: BorderRadius.circular(tdTheme.radiusDefault),
              border: Border.all(color: tdTheme.componentBorderColor),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TDText(
                      'Fields Preview',
                      font: tdTheme.fontTitleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                    TDButton(
                      text: 'Edit Fields',
                      icon: TDIcons.edit,
                      theme: TDButtonTheme.defaultTheme,
                      type: TDButtonType.text,
                      onTap: () => _tabController.animateTo(1),
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
                            TDIcons.view_list,
                            size: 48,
                            color: tdTheme.textColorSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          TDText(
                            'No fields defined yet',
                            font: tdTheme.fontBodyMedium,
                            textColor: tdTheme.textColorSecondary,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(tdTheme.bgColorSecondaryContainer),
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
                              ? Icon(TDIcons.lock_on, size: 16, color: tdTheme.brandNormalColor)
                              : const SizedBox()),
                          DataCell(TDText(field.name, font: tdTheme.fontBodySmall)),
                          DataCell(TDText(field.type, font: tdTheme.fontBodySmall)),
                          DataCell(TDText(field.chnname, font: tdTheme.fontBodySmall)),
                        ],
                      );
                    }).toList(),
                  ),
                if (entity.fields.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TDText(
                      'And ${entity.fields.length - 10} more fields...',
                      font: tdTheme.fontBodySmall,
                      textColor: tdTheme.textColorSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsTab(Entity entity) {
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

  Widget _buildIndexesTab(Entity entity) {
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

  Widget _buildPreviewTab(Entity entity) {
    final databases = ref.watch(databaseProvider);

    return CodePreview(
      entity: entity,
      databases: databases,
      selectedDatabase: 'MYSQL',
      onDatabaseChanged: (db) {},
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

    TDToast.showText('Entity updated', context: context);
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
    final tdTheme = TDTheme.of(context);

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
              TDText(
                label,
                font: tdTheme.fontBodySmall,
                textColor: tdTheme.textColorSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TDText(
            value,
            font: tdTheme.fontHeadlineMedium,
            fontWeight: FontWeight.bold,
            textColor: color,
          ),
        ],
      ),
    );
  }
}