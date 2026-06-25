# features/modeling 数据模型说明

## 核心数据结构

### 1. Entity（实体/表）

```dart
class Entity {
  final String id;           // 唯一标识
  final String title;        // 表代码（英文）
  final String chnname;      // 表中文名
  final String? remark;      // 表备注
  final List<Field> fields;  // 字段列表
  final List<Index> indexes; // 索引列表
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**重要方法：**
- `primaryKeys` - 获取主键字段列表
- `validateFieldIds()` - 验证字段 ID 唯一性
- `validateIndexIds()` - 验证索引 ID 唯一性
- `hasEmptyFieldIds()` - 检查是否有空 ID 字段

### 2. Field（字段）

```dart
class Field {
  final String id;              // 字段唯一标识
  final String name;            // 字段名
  final String type;            // 数据类型（抽象类型 code）
  final String chnname;         // 字段中文名
  final String? remark;         // 字段备注
  final bool pk;                // 是否主键
  final bool notNull;           // 是否非空
  final bool autoIncrement;     // 是否自增
  final String? defaultValue;   // 默认值
  final int? length;            // 长度
  final int? decimal;           // 小数位数
}
```

**数据类型映射：**
- 抽象类型（如 `IdOrKey`, `Name`, `Intro`）在 CodePreview 中映射为数据库特定类型
- 例如：`IdOrKey` -> MySQL `VARCHAR(32)`, Oracle `VARCHAR2(32)`

### 3. Index（索引）

```dart
class Index {
  final String id;            // 索引唯一标识
  final String name;          // 索引名称
  final List<String> fieldIds;// 索引字段 ID 列表
  final IndexType type;       // 索引类型
  final String? remark;       // 索引备注
}

enum IndexType {
  normal,    // 普通索引
  unique,    // 唯一索引
  fulltext,  // 全文索引
}
```

**重要方法：**
- `getFieldNames(List<Field> fields)` - 通过字段 ID 获取字段名列表

---

## ER 图数据结构

### ERNode（ER 图节点）

包装 Entity 数据，实现 DiagramNode 接口：

```dart
class ERNode implements DiagramNode {
  final Entity entity;      // 底层实体数据
  final GraphNode graphNode;// 图节点数据（位置等）
  final NodeState state;    // 节点状态

  @override
  String get id => entity.id;  // 使用 entity.id 作为节点唯一标识

  @override
  List<AnchorPoint> getAnchors(); // 字段级锚点
}
```

**节点尺寸计算：**
```dart
Size _calculateSize() {
  const headerHeight = 40.0;
  const fieldRowHeight = 28.0;
  const defaultWidth = 200.0;
  const minHeight = 80.0;

  final fieldCount = entity.fields.length;
  final height = headerHeight + (fieldCount * fieldRowHeight) + padding;
  return Size(defaultWidth, max(height, minHeight));
}
```

### ERRelationEdge（ER 图边）

表示实体间的关系：

```dart
class ERRelationEdge implements DiagramEdge {
  final GraphEdge graphEdge;  // 底层图边数据
  final EdgeState state;      // 边状态

  // 关系类型格式: "1:N", "1:1", "N:M"
  // sourceMarker/targetMarker 从 relationType 解析
}
```

### ERDiagramState（ER 图状态）

```dart
class ERDiagramState extends DiagramState {
  final String moduleId;

  // 从 Module 创建
  factory ERDiagramState.fromModule(Module module);

  // 获取特定类型节点/边
  ERNode? getERNode(String id);
  ERRelationEdge? getERRelation(String id);
}
```

**fromModule 关键逻辑：**
1. 从 `module.graphCanvas.nodes` 创建已存在的节点
2. 为没有 GraphNode 的实体自动创建节点（网格布局）
3. 使用 `entity.id` 作为节点 key（重要：保证唯一性）

---

## 流程图数据结构

### FlowNodeData（流程节点数据）

```dart
class FlowNodeData {
  final FlowNodeType type;   // 节点类型
  final String title;        // 节点标题
  final String id;           // 节点 ID
  final String? description; // 节点描述
  final String? subProcessId;// 子流程 ID
}

enum FlowNodeType {
  terminal,          // 开始/结束（椭圆）
  process,           // 流程（矩形）
  decision,          // 判断（菱形）
  inputOutput,       // 输入/输出（平行四边形）
  predefinedProcess, // 预定义流程（双边矩形）
  connector,         // 连接点（圆形）
  data,              // 数据（波形）
  document,          // 文档（波形底部）
}
```

### FlowEdgeData（流程边数据）

```dart
class FlowEdgeData {
  final String sourceId;   // 源节点 ID
  final String targetId;   // 目标节点 ID
  final FlowEdgeType type; // 边类型
  final String? label;     // 标签（如 "Yes", "No"）
}

enum FlowEdgeType {
  sequence,      // 普通流程线
  conditionYes,  // 条件分支（Yes）
  conditionNo,   // 条件分支（No）
  loopBack,      // 循环返回
  parallel,      // 并行分支
}
```

---

## 字段锚点系统

### FieldAnchor（字段锚点）

用于 ER 图字段级连线：

```dart
class FieldAnchor {
  final String nodeId;       // 所属节点 ID
  final int fieldIndex;      // 字段索引
  Offset position;           // 场景绝对位置
  final FieldAnchorDirection direction; // 方向（左/右）
  final Field field;         // 字段数据

  String get id => '$nodeId:field:$fieldIndex:${direction.name}';
}
```

### FieldAnchorRegistry（锚点注册表）

```dart
class FieldAnchorRegistry {
  // 注册节点所有字段的锚点
  void registerFieldAnchors(String nodeId, Entity entity, Offset nodePosition);

  // 更新节点锚点位置（节点移动后调用）
  void updateNodeAnchors(String nodeId, Entity entity, Offset newPosition);

  // 锚点命中测试
  FieldAnchor? hitTest(Offset point, double threshold);

  // 通过锚点 ID 获取锚点
  FieldAnchor? getAnchorById(String anchorId);
}
```

**锚点位置计算常量：**
```dart
const headerHeight = 40.0;      // 表头高度
const fieldRowHeight = 28.0;    // 字段行高
const anchorOffset = 8.0;       // 锚点距节点边缘距离
const defaultWidth = 200.0;     // 节点默认宽度
```

---

## Provider 状态

### EntityEditState

```dart
class EntityEditState {
  final Entity entity;           // 当前编辑的实体
  final String moduleId;         // 所属模块 ID
  final bool isDirty;            // 是否有未保存更改
  final int selectedTab;         // 当前标签页索引
  final String selectedDatabase; // 代码预览选中的数据库
}
```

### ERDiagramState 扩展属性

继承自 DiagramState：
- `nodes: Map<String, DiagramNode>` - 节点映射
- `edges: Map<String, DiagramEdge>` - 边映射
- `viewport: ViewportState` - 视口状态
- `interaction: InteractionState` - 交互状态
- `selection: SelectionState` - 选择状态

---

## 数据同步机制

### ERDiagramGraphSync

双向同步 ERDiagramState <-> GraphView Graph：

```dart
class ERDiagramGraphSync {
  final Graph graph = Graph();
  final FieldAnchorRegistry anchorRegistry = FieldAnchorRegistry();

  // 从 State 同步到 Graph
  void syncFromState(ERDiagramState state);

  // 导出回 State（用于持久化）
  ERDiagramState syncToState(ERDiagramState baseState);

  // 节点操作
  Node addNode(ERNode erNode);
  void removeNode(String nodeId);

  // 边操作
  ERGraphEdge? addEdgeWithFields({...});
}
```

**syncFromState 流程：**
1. 清空现有 graph 数据
2. 遍历 state.nodes，创建 GraphView Node
3. 注册字段锚点到 anchorRegistry
4. 遍历 state.edges，创建 GraphView Edge

---

## ID 使用规范

**关键原则：使用 `entity.id` 作为节点唯一标识**

```dart
// 正确
@override
String get id => entity.id;

// 错误（可能导致重复）
@override
String get id => entity.title;
```

**原因：**
- `entity.title` 可能重复（不同模块可能有同名表）
- `entity.id` 由 IdGenerator 生成，保证全局唯一

**GraphNode.moduleName 用途：**
- 存储 `entity.id` 以便后续查找
- 兼容旧数据：如果 moduleName 为空，尝试通过 title 查找
