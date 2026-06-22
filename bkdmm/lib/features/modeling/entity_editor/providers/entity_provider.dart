import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../../../utils/id_generator.dart';

/// Entity editing state
class EntityEditState {
  /// The entity being edited
  final Entity entity;

  /// The module ID containing this entity
  final String moduleId;

  /// Whether the entity has unsaved changes
  final bool isDirty;

  /// Currently selected tab index (0: summary, 1: fields, 2: indexes, 3: preview)
  final int selectedTab;

  /// Selected database for code preview
  final String selectedDatabase;

  const EntityEditState({
    required this.entity,
    required this.moduleId,
    this.isDirty = false,
    this.selectedTab = 0,
    this.selectedDatabase = 'MYSQL',
  });

  EntityEditState copyWith({
    Entity? entity,
    String? moduleId,
    bool? isDirty,
    int? selectedTab,
    String? selectedDatabase,
  }) {
    return EntityEditState(
      entity: entity ?? this.entity,
      moduleId: moduleId ?? this.moduleId,
      isDirty: isDirty ?? this.isDirty,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedDatabase: selectedDatabase ?? this.selectedDatabase,
    );
  }
}

/// Notifier for managing entity editing
class EntityEditNotifier extends StateNotifier<EntityEditState> {
  final Ref ref;

  EntityEditNotifier(this.ref, Entity initialEntity, String moduleId)
      : super(EntityEditState(
          entity: initialEntity,
          moduleId: moduleId,
        ));

  /// Update entity basic info
  void updateBasicInfo({
    String? title,
    String? chnname,
    String? remark,
  }) {
    final updatedEntity = state.entity.copyWith(
      title: title ?? state.entity.title,
      chnname: chnname ?? state.entity.chnname,
      remark: remark ?? state.entity.remark,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Add a new field
  void addField({
    String? name,
    String? type,
    String? chnname,
    bool pk = false,
    bool notNull = false,
    bool autoIncrement = false,
    String? remark,
  }) {
    final newField = Field(
      id: IdGenerator.generate(),
      name: name ?? 'field_${state.entity.fields.length + 1}',
      type: type ?? 'String',
      chnname: chnname ?? 'New Field',
      pk: pk,
      notNull: notNull,
      autoIncrement: autoIncrement,
      remark: remark,
    );
    final updatedFields = [...state.entity.fields, newField];
    final updatedEntity = state.entity.copyWith(
      fields: updatedFields,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Update a field
  void updateField(String fieldId, Field updatedField) {
    final updatedFields = state.entity.fields.map((f) {
      return f.id == fieldId ? updatedField : f;
    }).toList();
    final updatedEntity = state.entity.copyWith(
      fields: updatedFields,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Delete a field
  void deleteField(String fieldId) {
    final updatedFields = state.entity.fields
        .where((f) => f.id != fieldId)
        .toList();
    final updatedEntity = state.entity.copyWith(
      fields: updatedFields,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Reorder fields
  void reorderFields(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.entity.fields.length) return;
    if (newIndex < 0 || newIndex > state.entity.fields.length) return;

    final fields = List<Field>.from(state.entity.fields);
    final field = fields.removeAt(oldIndex);
    fields.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, field);

    final updatedEntity = state.entity.copyWith(
      fields: fields,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Add a new index
  void addIndex({
    String? name,
    List<String>? fields,
    IndexType type = IndexType.normal,
    String? remark,
  }) {
    final newIndex = Index(
      id: IdGenerator.generate(),
      name: name ?? 'idx_${state.entity.indexes.length + 1}',
      fields: fields ?? [],
      type: type,
      remark: remark,
    );
    final updatedIndexes = [...state.entity.indexes, newIndex];
    final updatedEntity = state.entity.copyWith(
      indexes: updatedIndexes,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Update an index
  void updateIndex(String indexId, Index updatedIndex) {
    final updatedIndexes = state.entity.indexes.map((i) {
      return i.id == indexId ? updatedIndex : i;
    }).toList();
    final updatedEntity = state.entity.copyWith(
      indexes: updatedIndexes,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Delete an index
  void deleteIndex(String indexId) {
    final updatedIndexes = state.entity.indexes
        .where((i) => i.id != indexId)
        .toList();
    final updatedEntity = state.entity.copyWith(
      indexes: updatedIndexes,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(entity: updatedEntity, isDirty: true);
    _syncToProject();
  }

  /// Change selected tab
  void selectTab(int tabIndex) {
    state = state.copyWith(selectedTab: tabIndex);
  }

  /// Change selected database for preview
  void selectDatabase(String databaseCode) {
    state = state.copyWith(selectedDatabase: databaseCode);
  }

  /// Save entity to project (mark as clean)
  void markClean() {
    state = state.copyWith(isDirty: false);
  }

  /// Reset entity to original state
  void resetEntity(Entity originalEntity) {
    state = EntityEditState(
      entity: originalEntity,
      moduleId: state.moduleId,
      isDirty: false,
      selectedTab: state.selectedTab,
      selectedDatabase: state.selectedDatabase,
    );
  }

  /// Sync changes to the project provider
  void _syncToProject() {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    final project = ref.read(projectNotifierProvider).project;

    if (project == null) return;

    // Find the module containing this entity
    final modules = project.modules.map((m) {
      if (m.id == state.moduleId) {
        // Update the entity in this module
        final entities = m.entities.map((e) {
          return e.id == state.entity.id ? state.entity : e;
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
  }
}

/// Provider family for entity editing - one provider per entity
final entityEditProvider = StateNotifierProvider.family<EntityEditNotifier, EntityEditState, (Entity, String)>(
  (ref, params) {
    final entity = params.$1;
    final moduleId = params.$2;
    return EntityEditNotifier(ref, entity, moduleId);
  },
);

/// Provider for getting data types
final dataTypeProvider = Provider<List<DataType>>((ref) {
  // Get default data types from project notifier
  return ref.read(projectNotifierProvider.notifier).getDefaultDataTypes();
});

/// Provider for available databases
final databaseProvider = Provider<List<DatabaseTemplate>>((ref) {
  // Return default database templates
  return [
    DatabaseTemplate(
      code: 'MYSQL',
      name: 'MySQL',
      defaultDatabase: true,
      template: TemplateConfig(
        createTableTemplate: '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{type}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} AUTO_INCREMENT{{/autoIncrement}}{{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}}{{#remark}} COMMENT '{{remark}}'{{/remark}},
{{/fields}}
) COMMENT '{{tableComment}}';''',
        deleteTableTemplate: 'DROP TABLE IF EXISTS {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate: 'ALTER TABLE {{tableName}} ADD COLUMN {{name}} {{type}};',
        updateFieldTemplate: 'ALTER TABLE {{tableName}} MODIFY COLUMN {{name}} {{type}};',
        deleteFieldTemplate: 'ALTER TABLE {{tableName}} DROP COLUMN {{name}};',
        createIndexTemplate: 'CREATE {{#unique}}UNIQUE{{/unique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}} ON {{tableName}};',
      ),
    ),
    DatabaseTemplate(
      code: 'POSTGRESQL',
      name: 'PostgreSQL',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{type}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}},
{{/fields}}
);
COMMENT ON TABLE {{tableName}} IS '{{tableComment}}';''',
        deleteTableTemplate: 'DROP TABLE IF EXISTS {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate: 'ALTER TABLE {{tableName}} ADD COLUMN {{name}} {{type}};',
        updateFieldTemplate: 'ALTER TABLE {{tableName}} ALTER COLUMN {{name}} TYPE {{type}};',
        deleteFieldTemplate: 'ALTER TABLE {{tableName}} DROP COLUMN {{name}};',
        createIndexTemplate: 'CREATE {{#unique}}UNIQUE{{/unique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}};',
      ),
    ),
    DatabaseTemplate(
      code: 'ORACLE',
      name: 'Oracle',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{type}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}},
{{/fields}}
);''',
        deleteTableTemplate: 'DROP TABLE {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate: 'ALTER TABLE {{tableName}} ADD {{name}} {{type}};',
        updateFieldTemplate: 'ALTER TABLE {{tableName}} MODIFY {{name}} {{type}};',
        deleteFieldTemplate: 'ALTER TABLE {{tableName}} DROP COLUMN {{name}};',
        createIndexTemplate: 'CREATE {{#unique}}UNIQUE{{/unique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}};',
      ),
    ),
    DatabaseTemplate(
      code: 'SQLSERVER',
      name: 'SQL Server',
      defaultDatabase: false,
      template: TemplateConfig(
        createTableTemplate: '''CREATE TABLE {{tableName}} (
{{#fields}}
  {{name}} {{type}}{{#pk}} PRIMARY KEY{{/pk}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} IDENTITY(1,1){{/autoIncrement}}{{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}},
{{/fields}}
);''',
        deleteTableTemplate: 'DROP TABLE {{tableName}};',
        rebuildTableTemplate: '',
        createFieldTemplate: 'ALTER TABLE {{tableName}} ADD {{name}} {{type}};',
        updateFieldTemplate: 'ALTER TABLE {{tableName}} ALTER COLUMN {{name}} {{type}};',
        deleteFieldTemplate: 'ALTER TABLE {{tableName}} DROP COLUMN {{name}};',
        createIndexTemplate: 'CREATE {{#unique}}UNIQUE{{/unique}} INDEX {{indexName}} ON {{tableName}}({{fields}});',
        deleteIndexTemplate: 'DROP INDEX {{indexName}} ON {{tableName}};',
      ),
    ),
  ];
});