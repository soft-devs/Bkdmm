# 数据表编辑器

> **阅读时机**: 开发表编辑、字段配置、索引管理功能时

---

## 功能概述

数据表编辑器是核心功能模块，提供：
- 数据表字段配置
- 索引管理
- 代码预览
- 多表编辑(Tab切换)

---

## UI 组件设计

### 表编辑器主组件 (使用 Riverpod)

```dart
// lib/features/modeling/entity_editor/entity_editor.dart

class EntityEditor extends ConsumerStatefulWidget {
  final String entityId;
  final String moduleId;

  const EntityEditor({
    required this.entityId,
    required this.moduleId,
    super.key,
  });

  @override
  ConsumerState<EntityEditor> createState() => _EntityEditorState();
}

class _EntityEditorState extends ConsumerState<EntityEditor> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final entityAsync = ref.watch(entityProvider(widget.entityId));

    return entityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
      data: (entity) => Column(
        children: [
          _buildHeader(context, entity),
          _buildTabBar(context),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildSummaryTab(context, entity),
                _buildFieldsTab(context, ref, entity),
                _buildIndexesTab(context, ref, entity),
                _buildCodePreviewTab(context, entity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Entity entity) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entity.title}[${entity.chnname}]',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (entity.remark != null)
                  Text(
                    entity.remark!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveEntity(context, ref),
            tooltip: '保存',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      onTap: (index) => setState(() => _currentTab = index),
      tabs: const [
        Tab(text: '摘要'),
        Tab(text: '字段'),
        Tab(text: '索引'),
        Tab(text: '代码预览'),
      ],
    );
  }
}
```
```

### 字段编辑表格 (使用 Syncfusion DataGrid)

```dart
// lib/features/modeling/entity_editor/fields_table.dart

import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FieldsTable extends ConsumerStatefulWidget {
  final String entityId;
  final List<Field> fields;

  const FieldsTable({
    required this.entityId,
    required this.fields,
    super.key,
  });

  @override
  ConsumerState<FieldsTable> createState() => _FieldsTableState();
}

class _FieldsTableState extends ConsumerState<FieldsTable> {
  late FieldDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = FieldDataSource(
      fields: widget.fields,
      onFieldsChanged: _onFieldsChanged,
    );
  }

  @override
  void didUpdateWidget(FieldsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _dataSource.updateFields(widget.fields);
    }
  }

  void _onFieldsChanged(List<Field> newFields) {
    ref.read(entityNotifierProvider(widget.entityId).notifier)
        .updateFields(newFields);
  }

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: _dataSource,
      columns: [
        GridColumn(
          columnName: 'pk',
          label: const Center(child: Text('主键')),
          width: 60,
        ),
        GridColumn(
          columnName: 'name',
          label: const Center(child: Text('字段名')),
          width: 150,
        ),
        GridColumn(
          columnName: 'type',
          label: const Center(child: Text('数据类型')),
          width: 150,
        ),
        GridColumn(
          columnName: 'chnname',
          label: const Center(child: Text('中文名')),
          width: 150,
        ),
        GridColumn(
          columnName: 'notNull',
          label: const Center(child: Text('非空')),
          width: 60,
        ),
        GridColumn(
          columnName: 'autoIncrement',
          label: const Center(child: Text('自增')),
          width: 60,
        ),
        GridColumn(
          columnName: 'remark',
          label: const Center(child: Text('备注')),
          width: 200,
        ),
      ],
      allowEditing: true,
      selectionMode: SelectionMode.multiple,
      navigationMode: GridNavigationMode.cell,
      onQueryRowHeight: (details) => 40,
      tableSummaryRows: [
        GridTableSummaryRow(
          showSummaryInRow: true,
          title: '共 {fieldCount} 个字段',
          columns: [
            GridSummaryColumn(
              name: 'fieldCount',
              columnName: 'name',
              summaryType: GridSummaryType.count,
            ),
          ],
          position: GridTableSummaryRowPosition.bottom,
        ),
      ],
    );
  }
}

class FieldDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  List<Field> _fields = [];
  final void Function(List<Field>) onFieldsChanged;

  FieldDataSource({
    required List<Field> fields,
    required this.onFieldsChanged,
  }) {
    _fields = fields;
    _buildRows();
  }

  void updateFields(List<Field> fields) {
    _fields = fields;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = _fields.asMap().entries.map((entry) {
      final field = entry.value;
      return DataGridRow(cells: [
        DataGridCell(columnName: 'pk', value: field.pk),
        DataGridCell(columnName: 'name', value: field.name),
        DataGridCell(columnName: 'type', value: field.type),
        DataGridCell(columnName: 'chnname', value: field.chnname),
        DataGridCell(columnName: 'notNull', value: field.notNull),
        DataGridCell(columnName: 'autoIncrement', value: field.autoIncrement),
        DataGridCell(columnName: 'remark', value: field.remark ?? ''),
      ]);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        switch (cell.columnName) {
          case 'pk':
          case 'notNull':
          case 'autoIncrement':
            return Checkbox(
              value: cell.value as bool,
              onChanged: (v) => _updateCell(row, cell.columnName, v ?? false),
            );
          case 'type':
            return _buildTypeSelector(cell.value as String, row);
          default:
            return TextFormField(
              initialValue: cell.value.toString(),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) => _updateCell(row, cell.columnName, v),
            );
        }
      }).toList(),
    );
  }

  Widget _buildTypeSelector(String currentType, DataGridRow row) {
    final dataTypes = ref.read(dataTypesProvider);

    return DropdownButtonFormField<String>(
      value: currentType,
      isExpanded: true,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
      items: dataTypes.map((dt) {
        return DropdownMenuItem(
          value: dt.code,
          child: Text('${dt.chnname} (${dt.code})'),
        );
      }).toList(),
      onChanged: (v) => _updateCell(row, 'type', v!),
    );
  }

  void _updateCell(DataGridRow row, String columnName, dynamic value) {
    final index = _rows.indexOf(row);
    if (index < 0) return;

    final field = _fields[index];
    Field newField;

    switch (columnName) {
      case 'pk':
        newField = field.copyWith(pk: value as bool);
        break;
      case 'name':
        newField = field.copyWith(name: value as String);
        break;
      case 'type':
        newField = field.copyWith(type: value as String);
        break;
      case 'chnname':
        newField = field.copyWith(chnname: value as String);
        break;
      case 'notNull':
        newField = field.copyWith(notNull: value as bool);
        break;
      case 'autoIncrement':
        newField = field.copyWith(autoIncrement: value as bool);
        break;
      case 'remark':
        newField = field.copyWith(remark: value as String);
        break;
      default:
        return;
    }

    _fields[index] = newField;
    _buildRows();
    notifyListeners();
    onFieldsChanged(_fields);
  }
}
```

### 索引编辑组件 (使用 Riverpod + Freezed)

```dart
// lib/features/modeling/entity_editor/index_editor.dart

class IndexEditor extends ConsumerWidget {
  final String entityId;
  final List<Index> indexes;
  final List<Field> availableFields;

  const IndexEditor({
    required this.entityId,
    required this.indexes,
    required this.availableFields,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新增索引'),
                onPressed: () => _addIndex(context, ref),
              ),
              const Spacer(),
              Text('共 ${indexes.length} 个索引'),
            ],
          ),
        ),

        // 索引列表
        Expanded(
          child: indexes.isEmpty
              ? const Center(child: Text('暂无索引，点击"新增索引"添加'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: indexes.length,
                  itemBuilder: (context, index) {
                    return _buildIndexCard(context, ref, indexes[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIndexCard(
    BuildContext context,
    WidgetRef ref,
    Index idx,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: idx.name,
                    decoration: const InputDecoration(
                      labelText: '索引名称',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _updateIndexName(context, ref, index, v),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButtonFormField<IndexType>(
                  value: idx.type,
                  decoration: const InputDecoration(
                    labelText: '索引类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: IndexType.normal,
                      child: Text('普通索引'),
                    ),
                    DropdownMenuItem(
                      value: IndexType.unique,
                      child: Text('唯一索引'),
                    ),
                    DropdownMenuItem(
                      value: IndexType.fulltext,
                      child: Text('全文索引'),
                    ),
                  ],
                  onChanged: (v) => _updateIndexType(context, ref, index, v!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteIndex(context, ref, index),
                  tooltip: '删除索引',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '索引字段:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableFields.map((field) {
                final isSelected = idx.fields.contains(field.name);
                return FilterChip(
                  label: Text(field.name),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  onSelected: (selected) => _toggleIndexField(
                    context,
                    ref,
                    index,
                    field.name,
                    selected,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addIndex(BuildContext context, WidgetRef ref) {
    final newIndex = Index(
      id: const Uuid().v4(),
      name: 'idx_${availableFields.firstOrNull?.name ?? 'new'}',
      fields: [],
      type: IndexType.normal,
    );

    ref.read(entityNotifierProvider(entityId).notifier)
        .addIndex(newIndex);
  }

  void _updateIndexName(
    BuildContext context,
    WidgetRef ref,
    int index,
    String name,
  ) {
    final newIndex = indexes[index].copyWith(name: name);
    ref.read(entityNotifierProvider(entityId).notifier)
        .updateIndex(index, newIndex);
  }

  void _updateIndexType(
    BuildContext context,
    WidgetRef ref,
    int index,
    IndexType type,
  ) {
    final newIndex = indexes[index].copyWith(type: type);
    ref.read(entityNotifierProvider(entityId).notifier)
        .updateIndex(index, newIndex);
  }

  void _toggleIndexField(
    BuildContext context,
    WidgetRef ref,
    int index,
    String fieldName,
    bool selected,
  ) {
    final currentFields = List<String>.from(indexes[index].fields);
    if (selected) {
      currentFields.add(fieldName);
    } else {
      currentFields.remove(fieldName);
    }

    final newIndex = indexes[index].copyWith(fields: currentFields);
    ref.read(entityNotifierProvider(entityId).notifier)
        .updateIndex(index, newIndex);
  }

  void _deleteIndex(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除索引 "${indexes[index].name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(entityNotifierProvider(entityId).notifier)
                  .removeIndex(index);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
```

---

## 工具函数

### 数据表操作

```dart
// lib/features/modeling/services/table_service.dart

class TableService {
  /// 新增数据表
  Entity createEntity({
    required String title,
    required String chnname,
    required List<Field> defaultFields,
  }) {
    return Entity(
      id: _generateId(),
      title: title,
      chnname: chnname,
      fields: [...defaultFields],
      indexes: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 校验表名
  String? validateTableName(String name, List<Entity> existingEntities) {
    if (name.isEmpty) return '表名不能为空';
    
    // 特殊字符检查
    if (RegExp(r'[/&:]').hasMatch(name)) {
      return '表名不能包含 /、&、: 特殊字符';
    }
    
    // 唯一性检查
    if (existingEntities.any((e) => e.title == name)) {
      return '表名已存在';
    }
    
    return null;
  }
  
  /// 校验字段名
  String? validateFieldName(String name, List<Field> existingFields) {
    if (name.isEmpty) return '字段名不能为空';
    
    if (RegExp(r'[/&:]').hasMatch(name)) {
      return '字段名不能包含 /、&、: 特殊字符';
    }
    
    if (existingFields.any((f) => f.name == name)) {
      return '字段名已存在';
    }
    
    return null;
  }
}
```

---

## Tab 管理

```dart
// lib/shared/providers/tab_provider.dart

class EditorTab {
  final String id;
  final TabType type;
  final String title;
  final String moduleId;
  final String? entityId;
  
  EditorTab({
    required this.id,
    required this.type,
    required this.title,
    required this.moduleId,
    this.entityId,
  });
}

enum TabType {
  entity,
  relation,
  template,
}

final tabsProvider = StateNotifierProvider<TabsNotifier, TabsState>((ref) {
  return TabsNotifier();
});

class TabsState {
  final List<EditorTab> tabs;
  final String? activeTabId;
  
  const TabsState({
    this.tabs = const [],
    this.activeTabId,
  });
}

class TabsNotifier extends StateNotifier<TabsState> {
  void openTab(EditorTab tab) {
    // 检查是否已存在
    final existing = state.tabs.firstWhere(
      (t) => t.id == tab.id,
      orElse: () => null,
    );
    
    if (existing != null) {
      // 激活已存在的 Tab
      state = TabsState(tabs: state.tabs, activeTabId: existing.id);
    } else {
      // 添加新 Tab
      state = TabsState(
        tabs: [...state.tabs, tab],
        activeTabId: tab.id,
      );
    }
  }
  
  void closeTab(String tabId) {
    final newTabs = state.tabs.where((t) => t.id != tabId).toList();
    String? newActiveId = state.activeTabId;
    
    if (state.activeTabId == tabId) {
      final closedIndex = state.tabs.indexWhere((t) => t.id == tabId);
      if (newTabs.isNotEmpty) {
        newActiveId = newTabs[min(closedIndex, newTabs.length - 1)].id;
      } else {
        newActiveId = null;
      }
    }
    
    state = TabsState(tabs: newTabs, activeTabId: newActiveId);
  }
}
```

---

## 已知坑点

1. **表名特殊字符**: 不能包含 `/`、`&`、`:`
2. **字段名特殊字符**: 同上限制
3. **保存时校验**: 先校验表名唯一性，再校验字段
4. **Tab 组件引用**: 通过 Map 存储实例
5. **数据更新机制**: 需要深拷贝避免引用问题

---

## 相关文档

- [数据模型设计](../../data-model/README.md)
- [数据类型系统](../datatype/README.md)
- [代码生成](../codegen/README.md)