# features/modeling 已知坑点

## 1. ER 图节点 ID 重复问题

### 问题现象
ER 图显示异常，节点重叠或消失，连线指向错误。

### 根本原因
旧代码使用 `entity.title` 作为节点 ID，当不同模块有同名表时会导致 ID 冲突。

### 解决方案
始终使用 `entity.id` 作为节点唯一标识：

```dart
// 正确
@override
String get id => entity.id;

// GraphNode.moduleName 存储实体 ID
final graphNode = GraphNode(
  title: '${entity.title}:0',
  x: x,
  y: y,
  moduleName: entity.id,  // 存储 entity.id
);
```

### 相关文件
- `lib/features/modeling/er_diagram/models/er_diagram_models.dart`
- `lib/features/modeling/er_diagram/core/graph_sync.dart`

---

## 2. 字段/索引空 ID 问题

### 问题现象
新建字段或索引后，保存时出现异常或数据丢失。

### 根本原因
UI 层创建的 `Field`/`Index` 对象可能没有生成有效 ID。

### 解决方案
在保存前检查并生成 ID：

```dart
onAddField: (fieldData) {
  // 确保 ID 有效
  final newField = fieldData.id.isEmpty
      ? fieldData.copyWith(id: IdGenerator.generate())
      : fieldData;
  // ... 保存逻辑
},
```

### 相关文件
- `lib/features/modeling/entity_editor/views/entity_editor_view.dart` (第 467-471 行)

---

## 3. GraphView 布局算法不更新节点位置

### 问题现象
调用 `SugiyamaAlgorithm.run()` 后，节点位置未更新到状态。

### 根本原因
GraphView 的布局算法只更新内部 Node 对象的位置，不会自动同步到 ERDiagramState。

### 解决方案
布局完成后，提取位置并更新状态：

```dart
void _autoLayout() {
  final algorithm = SugiyamaAlgorithm(config);
  algorithm.run(_graphSync.graph, 500, 400);

  // 提取布局后的位置
  final positions = <String, Offset>{};
  for (final node in _graphSync.graph.nodes) {
    final nodeId = node.key?.value.toString() ?? '';
    positions[nodeId] = Offset(node.x, node.y);
  }

  // 更新状态
  final notifier = ref.read(erDiagramProvider(widget.moduleId).notifier);
  notifier.applyLayout(positions);

  // 重新同步
  _graphSync.syncFromState(ref.read(erDiagramProvider(widget.moduleId)));
}
```

### 相关文件
- `lib/features/modeling/er_diagram/widgets/er_diagram_canvas.dart` (第 440-473 行)

---

## 4. Provider Family 刷新时机

### 问题现象
ER 图或实体编辑器数据未及时更新。

### 根本原因
`Provider.family` 创建的 Provider 实例不会自动监听其他 Provider 的变化。

### 解决方案
在 Notifier 构造函数中设置监听：

```dart
ERDiagramNotifier(this.ref, this.moduleId) : super(...) {
  // 监听项目状态变化
  ref.listen<ProjectState>(
    projectNotifierProvider,
    (previous, next) {
      if (_shouldReload(previous, next)) {
        _loadFromModule();
      }
    },
  );
}
```

### 相关文件
- `lib/features/modeling/er_diagram/providers/er_diagram_provider.dart` (第 35-51 行)

---

## 5. GraphView Node 相等性判断

### 问题现象
相同 ID 的节点被视为同一个节点，导致图结构异常。

### 根本原因
GraphView 的 `Node.Id(id)` 使用 `id.hashCode` 作为相等性判断依据。

### 解决方案
确保每个节点的 ID 唯一：

```dart
Node _createGraphNode(ERNode erNode) {
  // 使用 entity.id 确保唯一性
  final node = Node.Id(erNode.id);
  node.position = erNode.position;
  node.size = erNode.size;
  return node;
}
```

### 相关文件
- `lib/features/modeling/er_diagram/core/graph_sync.dart` (第 94-99 行)

---

## 6. 字段锚点位置更新延迟

### 问题现象
节点拖拽时，连线未跟随移动。

### 根本原因
节点位置更新后，锚点位置未同步更新。

### 解决方案
在 `onNodeDragUpdate` 中更新锚点：

```dart
void _onNodeDragUpdate(String nodeId, DragUpdateDetails details) {
  // 更新 graphview 节点位置
  graphNode.position = Offset(newX, newY);

  // 更新锚点位置
  _graphSync.anchorRegistry.updateNodeAnchors(
    nodeId,
    erNode.entity,
    Offset(newX, newY),
  );

  setState(() {});  // 触发重绘
}
```

### 相关文件
- `lib/features/modeling/er_diagram/widgets/er_diagram_canvas.dart` (第 491-517 行)

---

## 7. EntityEditProvider 状态孤立

### 问题现象
直接修改 `EntityEditState` 后，项目数据未同步更新。

### 根本原因
`EntityEditNotifier` 需要手动调用 `_syncToProject()` 同步数据。

### 解决方案
确保所有修改操作都调用同步方法：

```dart
void updateField(String fieldId, Field updatedField) {
  // ... 更新逻辑
  state = state.copyWith(entity: updatedEntity, isDirty: true);
  _syncToProject();  // 必须调用
}
```

### 相关文件
- `lib/features/modeling/entity_editor/providers/entity_provider.dart` (第 104-114 行)

---

## 8. 数据库类型映射不完整

### 问题现象
某些抽象类型在 DDL 预览中显示为原始类型名。

### 根本原因
`CodePreview._getDatabaseType()` 只处理了预定义的类型映射。

### 解决方案
添加默认回退逻辑：

```dart
String _getMySQLType(Field field) {
  switch (field.type.toLowerCase()) {
    // 预定义类型...
    default:
      // 回退：使用原始类型名
      return field.type.toUpperCase();
  }
}
```

### 相关文件
- `lib/features/modeling/entity_editor/widgets/code_preview.dart` (第 195-221 行)

---

## 9. 交互模式切换状态丢失

### 问题现象
从编辑模式切换回移动模式后，选中状态丢失。

### 根本原因
`_interactionMode` 是组件本地状态，切换时不保留选择信息。

### 解决方案
选择状态应存储在 Provider 中，而非组件状态：

```dart
// 当前方案（组件状态）
InteractionMode _interactionMode = InteractionMode.move;
final Set<String> _selectedNodeIds = {};

// 更好的方案（Provider 状态）
// 使用 ERDiagramState.selection 存储选择信息
```

### 改进建议
考虑将交互模式和选择状态移至 Provider 管理。

---

## 10. ERDiagramState.fromModule 兼容旧数据

### 问题现象
打开旧项目时，ER 图节点显示异常。

### 根本原因
旧版本数据使用 `entity.title` 作为节点标识，新版本使用 `entity.id`。

### 解决方案
在 `fromModule` 中添加兼容逻辑：

```dart
factory ERDiagramState.fromModule(Module module) {
  // 优先通过 moduleName（存储 entity.id）查找
  if (graphNode.moduleName != null) {
    entity = module.entities.where((e) => e.id == graphNode.moduleName).firstOrNull;
  }

  // 兼容旧数据：通过 title 查找
  if (entity == null) {
    final entityTitle = graphNode.title.split(':').first;
    entity = module.entities.where((e) => e.title == entityTitle).firstOrNull;
  }
}
```

### 相关文件
- `lib/features/modeling/er_diagram/models/er_diagram_models.dart` (第 271-297 行)

---

## 开发建议

### 1. 始终使用 ID 而非名称
- 字段、索引、实体、模块都应使用 `id` 作为唯一标识
- 名称可能重复或变更，ID 保证唯一且不可变

### 2. Provider 状态同步
- Feature 模块的 Notifier 应监听 `projectNotifierProvider` 变化
- 修改操作后调用 `_syncToProject()` 同步到上层

### 3. GraphView 双向同步
- 布局算法不会自动更新状态，需要手动提取位置
- 节点位置变化后更新锚点注册表

### 4. 测试边界情况
- 空 ID 字段/索引
- 同名实体/字段
- 空模块/空项目
- 旧版本数据兼容