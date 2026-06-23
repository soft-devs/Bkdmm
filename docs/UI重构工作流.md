# Bkdmm UI 重构工作流

> 使用 TDesign Flutter + GraphView + InteractiveViewer 重构 ER 图编辑器 UI

---

## 一、重构目标

### 1.1 当前问题

| 问题 | 描述 | 解决方案 |
|------|------|----------|
| 边界管理 | 自定义 CustomPaint 超边界 | InteractiveViewer 边界约束 |
| UI 风格 | 自定义组件风格不统一 | TDesign 企业级组件 |
| 维护成本 | 自定义 Paint 逻辑复杂 | GraphView 布局算法 |
| 交互体验 | 手势冲突、边界检测问题 | 状态机 + InteractiveViewer |

### 1.2 重构目标架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Bkdmm UI 架构                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  TDesign UI Layer                       │   │
│  │  - TDNavBar (导航栏)                                     │   │
│  │  - TDButton (工具栏按钮)                                 │   │
│  │  - TDDialog (对话框)                                     │   │
│  │  - TDMessage (消息提示)                                  │   │
│  │  - TDCard (节点卡片)                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              InteractiveViewer (边界层)                 │   │
│  │  - boundaryMargin: 边界约束                              │   │
│  │  - minScale/maxScale: 缩放限制                           │   │
│  │  - panAxis: 轴向移动控制                                 │   │
│  │  - TransformationController: 视口控制                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                GraphView (布局层)                        │   │
│  │  - SugiyamaAlgorithm: ER 图分层布局                      │   │
│  │  - 自定义节点 Widget (TDCard)                            │   │
│  │  - 边渲染                                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              State Management (状态层)                  │   │
│  │  - Riverpod StateNotifier                                │   │
│  │  - ERGraphNotifier                                       │   │
│  │  - UndoRedoNotifier                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、重构阶段

### Phase 1: 环境准备 (Day 1)

#### 任务清单

- [ ] 添加 tdesign_flutter 依赖
- [ ] 配置 TDesign 主题
- [ ] 创建主题配置文件
- [ ] 验证依赖兼容性

#### 执行步骤

```bash
# 1. 添加依赖
cd bkdmm
flutter pub add tdesign_flutter

# 2. 验证安装
flutter pub get
flutter analyze
```

#### 代码变更

**1. pubspec.yaml**
```yaml
dependencies:
  # 新增 TDesign
  tdesign_flutter: ^0.1.4

  # 现有依赖保持不变
  graphview: ^1.2.0
  # ...
```

**2. 创建主题配置**
```dart
// lib/shared/theme/app_theme.dart
import 'package:tdesign_flutter/tdesign_flutter.dart';

class AppTheme {
  static TDThemeData get light => TDThemeData.defaultData().copyWith(
    brandColor: const Color(0xFF0052D9),
    successColor: const Color(0xFF2BA471),
    warningColor: const Color(0xFFE37318),
    errorColor: const Color(0xFFD54941),
  );

  static TDThemeData get dark => TDThemeData.defaultData().copyWith(
    brandColor: const Color(0xFF4582E6),
    bgColor: const Color(0xFF1D1D1D),
    bgColorContainer: const Color(0xFF2C2C2C),
  );
}
```

**3. 更新 main.dart**
```dart
// lib/main.dart
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'shared/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TDTheme(
      data: AppTheme.light,
      child: MaterialApp(
        title: 'Bkdmm',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.light.brandColor,
          ),
        ),
        home: const WorkspaceView(),
      ),
    );
  }
}
```

#### 验收标准

- [ ] `flutter pub get` 无错误
- [ ] `flutter analyze` 无警告
- [ ] 应用启动正常
- [ ] TDesign 主题生效

---

### Phase 2: 替换基础 UI 组件 (Day 2-3)

#### 2.1 替换按钮组件

**目标文件**:
- `er_diagram_widget.dart` - 工具栏按钮
- 各对话框中的按钮

**变更映射**:
```dart
// Before (Material)
ElevatedButton.icon(
  icon: const Icon(Icons.add),
  label: const Text('Add Entity'),
  onPressed: () => _addEntity(),
)

// After (TDesign)
TDButton(
  text: 'Add Entity',
  theme: TDButtonTheme.primary,
  icon: TDIcons.add,
  onTap: () => _addEntity(),
)
```

**执行**:
```bash
# 查找所有 ElevatedButton
grep -r "ElevatedButton" lib/
grep -r "TextButton" lib/
grep -r "OutlinedButton" lib/
```

#### 2.2 替换输入框组件

**目标文件**:
- 实体编辑对话框
- 字段编辑对话框
- 搜索输入框

**变更映射**:
```dart
// Before (Material)
TextField(
  decoration: InputDecoration(
    labelText: 'Table Name',
    hintText: 'Enter table name',
  ),
  controller: _controller,
)

// After (TDesign)
TDInput(
  leftLabel: 'Table Name',
  hintText: 'Enter table name',
  controller: _controller,
  clearBtn: true,
)
```

#### 2.3 替换对话框组件

**目标文件**:
- `er_diagram_widget.dart` - 关系创建对话框
- 实体编辑对话框

**变更映射**:
```dart
// Before (Material)
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Create Relation'),
    content: Column(...),
    actions: [
      TextButton(onPressed: () {}, child: Text('Cancel')),
      FilledButton(onPressed: () {}, child: Text('Create')),
    ],
  ),
)

// After (TDesign)
showDialog(
  context: context,
  builder: (ctx) => TDDialog(
    title: 'Create Relation',
    content: Column(...),
    actions: [
      TDDialogAction(
        text: 'Cancel',
        action: () => Navigator.pop(ctx),
      ),
      TDDialogAction(
        text: 'Create',
        theme: TDButtonTheme.primary,
        action: () {
          _createRelation();
          Navigator.pop(ctx);
        },
      ),
    ],
  ),
)
```

#### 2.4 替换消息提示

**变更映射**:
```dart
// Before (Material)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Saved successfully')),
)

// After (TDesign)
TDMessage.showSuccess(context, message: 'Saved successfully')
```

#### 验收标准

- [ ] 所有按钮使用 TDButton
- [ ] 所有输入框使用 TDInput
- [ ] 所有对话框使用 TDDialog
- [ ] 所有消息提示使用 TDMessage
- [ ] UI 显示正常，无样式错乱

---

### Phase 3: 重构 ER 图画布 (Day 4-6)

#### 3.1 保留现有架构

现有架构已经很好：
- ✅ InteractiveViewer 已集成
- ✅ 状态机已实现
- ✅ 手势处理完善

**保留文件**:
- `er_diagram_widget.dart` - 主组件（小修改）
- `graph_provider.dart` - 状态管理
- `dagre_layout.dart` - 布局算法

#### 3.2 替换节点渲染

**当前**: CustomPaint + NodePainter
**目标**: GraphView + TDCard

**方案 A: 保留 CustomPaint + TDesign 颜色（推荐）**

```dart
// 修改 NodePainter 使用 TDesign 颜色
import 'package:tdesign_flutter/tdesign_flutter.dart';

class NodePainter {
  static void paint({
    required Canvas canvas,
    required ERGraphNode node,
    required double scale,
    required bool isDarkMode,
    bool showAnchors = false,
  }) {
    // 使用 TDesign 颜色
    final bgColor = isDarkMode
        ? TDTheme.of(context).bgColorContainer
        : Colors.white;

    final headerColor = TDTheme.of(context).brandColor;

    // 其余绘制逻辑保持不变...
  }
}
```

**方案 B: 使用 GraphView + TDCard（可选，后续优化）**

```dart
// 新建 er_diagram_graphview.dart
class ERDiagramGraphView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 3.0,
      child: GraphView(
        graph: _buildGraph(),
        algorithm: SugiyamaAlgorithm(_config),
        builder: (node) => _buildNodeWidget(node),
      ),
    );
  }

  Widget _buildNodeWidget(Node node) {
    final entity = node.key!.value as Entity;
    return TDCard(
      title: entity.title,
      subtitle: entity.chnname,
      child: Column(
        children: entity.fields.map((f) => _buildFieldRow(f)).toList(),
      ),
    );
  }
}
```

#### 3.3 更新工具栏

```dart
// lib/features/modeling/er_diagram/widgets/er_diagram_widget.dart

Widget _toolbar(ERGraphState graphState, bool isDark) {
  return TDCard(
    size: TDCardSize.small,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 模式切换
        TDButton(
          icon: editMode ? TDIcons.edit : TDIcons.pan_tool,
          theme: TDButtonTheme.primary,
          size: TDButtonSize.small,
          onTap: () => notifier.toggleInteractionMode(),
        ),

        // 分隔
        TDDivider(direction: TDDividerDirection.vertical),

        // 缩放
        TDButton(
          icon: TDIcons.zoom_in,
          size: TDButtonSize.small,
          onTap: _zoomIn,
        ),
        TDButton(
          icon: TDIcons.zoom_out,
          size: TDButtonSize.small,
          onTap: _zoomOut,
        ),
        TDButton(
          icon: TDIcons.autofit_width,
          size: TDButtonSize.small,
          onTap: _fitToScreen,
        ),

        TDDivider(direction: TDDividerDirection.vertical),

        // 布局
        TDButton(
          icon: TDIcons.autofit_height,
          size: TDButtonSize.small,
          onTap: _autoLayout,
        ),
      ],
    ),
  );
}
```

#### 验收标准

- [ ] ER 图正常显示
- [ ] 节点拖拽正常
- [ ] 边创建正常
- [ ] 缩放/平移正常
- [ ] 边界约束生效
- [ ] 工具栏使用 TDesign 组件

---

### Phase 4: 重构对话框和表单 (Day 7-8)

#### 4.1 实体编辑对话框

**新建**: `lib/shared/widgets/dialogs/entity_edit_dialog.dart`

```dart
import 'package:tdesign_flutter/tdesign_flutter.dart';

class EntityEditDialog extends StatefulWidget {
  final Entity? entity;
  final void Function(Entity) onSave;

  const EntityEditDialog({
    super.key,
    this.entity,
    required this.onSave,
  });

  @override
  State<EntityEditDialog> createState() => _EntityEditDialogState();
}

class _EntityEditDialogState extends State<EntityEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _chnNameController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity?.title ?? '');
    _chnNameController = TextEditingController(text: widget.entity?.chnname ?? '');
    _commentController = TextEditingController(text: widget.entity?.comment ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return TDDialog(
      title: widget.entity == null ? '新建实体' : '编辑实体',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TDInput(
            leftLabel: '表名',
            hintText: '请输入表名',
            controller: _nameController,
            required: true,
          ),
          const SizedBox(height: 16),
          TDInput(
            leftLabel: '中文名',
            hintText: '请输入中文名',
            controller: _chnNameController,
          ),
          const SizedBox(height: 16),
          TDTextarea(
            hintText: '请输入描述',
            controller: _commentController,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TDDialogAction(
          text: '取消',
          action: () => Navigator.pop(context),
        ),
        TDDialogAction(
          text: '保存',
          theme: TDButtonTheme.primary,
          action: () {
            final entity = Entity(
              id: widget.entity?.id ?? const Uuid().v4(),
              title: _nameController.text,
              chnname: _chnNameController.text,
              comment: _commentController.text,
              fields: widget.entity?.fields ?? [],
            );
            widget.onSave(entity);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
```

#### 4.2 字段编辑对话框

**新建**: `lib/shared/widgets/dialogs/field_edit_dialog.dart`

```dart
class FieldEditDialog extends StatefulWidget {
  final Field? field;
  final void Function(Field) onSave;

  @override
  Widget build(BuildContext context) {
    return TDDialog(
      title: field == null ? '新建字段' : '编辑字段',
      content: Column(
        children: [
          TDInput(leftLabel: '字段名', controller: _nameController),
          TDInput(leftLabel: '中文名', controller: _chnNameController),

          // 数据类型选择器
          TDPicker(
            title: '数据类型',
            data: ['VARCHAR', 'INT', 'BIGINT', 'DATE', 'DATETIME'],
            selectedIndex: _typeIndex,
            onConfirm: (index) => setState(() => _typeIndex = index),
          ),

          TDInput(leftLabel: '长度', controller: _lengthController),
          TDInput(leftLabel: '小数位', controller: _decimalController),

          // 开关
          Row(
            children: [
              TDText('主键'),
              TDSwitch(isOn: _isPk, onChanged: (v) => setState(() => _isPk = v)),
            ],
          ),
          Row(
            children: [
              TDText('非空'),
              TDSwitch(isOn: _notNull, onChanged: (v) => setState(() => _notNull = v)),
            ],
          ),
        ],
      ),
      actions: [...],
    );
  }
}
```

#### 验收标准

- [ ] 实体编辑对话框使用 TDesign 组件
- [ ] 字段编辑对话框使用 TDesign 组件
- [ ] 表单验证正常
- [ ] 保存功能正常

---

### Phase 5: 整体测试和优化 (Day 9-10)

#### 5.1 功能测试

```bash
# 运行测试
flutter test

# 运行应用
flutter run -d windows
flutter run -d chrome
```

#### 5.2 测试清单

| 功能 | 测试项 | 状态 |
|------|--------|------|
| **ER 图显示** | 节点正确渲染 | [ ] |
| | 边正确渲染 | [ ] |
| | 缩放正常 | [ ] |
| | 平移正常 | [ ] |
| | 边界约束生效 | [ ] |
| **节点交互** | 单击选中 | [ ] |
| | 双击编辑 | [ ] |
| | 拖拽移动 | [ ] |
| | 右键菜单 | [ ] |
| **边操作** | 从锚点拖拽创建 | [ ] |
| | 连接到目标锚点 | [ ] |
| | 取消创建 | [ ] |
| **对话框** | 实体创建/编辑 | [ ] |
| | 字段创建/编辑 | [ ] |
| | 关系创建 | [ ] |
| **主题** | 浅色模式 | [ ] |
| | 深色模式 | [ ] |

#### 5.3 性能优化

```dart
// 使用 const 构造函数
const TDButton(...)

// 使用 RepaintBoundary
RepaintBoundary(
  child: TDCard(...),
)

// 延迟加载
FutureBuilder(
  future: _loadData(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const TDLoading();
    return TDCard(...);
  },
)
```

#### 验收标准

- [ ] 所有功能测试通过
- [ ] 无性能问题
- [ ] 无内存泄漏
- [ ] 深色模式正常

---

## 三、文件变更清单

### 新增文件

| 文件 | 用途 |
|------|------|
| `lib/shared/theme/app_theme.dart` | TDesign 主题配置 |
| `lib/shared/widgets/dialogs/entity_edit_dialog.dart` | 实体编辑对话框 |
| `lib/shared/widgets/dialogs/field_edit_dialog.dart` | 字段编辑对话框 |
| `lib/shared/widgets/dialogs/relation_edit_dialog.dart` | 关系编辑对话框 |

### 修改文件

| 文件 | 变更内容 |
|------|----------|
| `pubspec.yaml` | 添加 tdesign_flutter 依赖 |
| `lib/main.dart` | 添加 TDTheme 配置 |
| `lib/features/modeling/er_diagram/widgets/er_diagram_widget.dart` | 替换 UI 组件 |
| `lib/features/modeling/er_diagram/painters/node_painter.dart` | 使用 TDesign 颜色 |
| `lib/features/modeling/er_diagram/painters/edge_painter.dart` | 使用 TDesign 颜色 |

---

## 四、风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| TDesign 与 GraphView 冲突 | 中 | 先小范围测试，保留 CustomPaint 方案 |
| 主题切换问题 | 低 | 提供默认主题，渐进式迁移 |
| 手势冲突 | 中 | 使用现有状态机，优先测试 |
| 性能下降 | 低 | 使用 const，RepaintBoundary |

---

## 五、时间线

| 阶段 | 时间 | 任务 |
|------|------|------|
| Phase 1 | Day 1 | 环境准备 |
| Phase 2 | Day 2-3 | 替换基础 UI 组件 |
| Phase 3 | Day 4-6 | 重构 ER 图画布 |
| Phase 4 | Day 7-8 | 重构对话框和表单 |
| Phase 5 | Day 9-10 | 测试和优化 |

**总计**: 10 个工作日

---

## 六、执行命令

### 开始重构

```bash
# 1. 创建重构分支
git checkout -b refactor/ui-tdesign

# 2. 添加依赖
flutter pub add tdesign_flutter

# 3. 运行分析
flutter analyze

# 4. 开始编码
# ...
```

### 测试验证

```bash
# 运行测试
flutter test

# 运行应用
flutter run -d windows

# 构建生产版本
flutter build windows
```

### 完成重构

```bash
# 合并到主分支
git checkout main
git merge refactor/ui-tdesign

# 推送
git push origin main
```

---

## 七、参考文档

| 文档 | 路径 |
|------|------|
| TDesign 集成指南 | [docs/TDesign-Flutter集成指南.md](TDesign-Flutter集成指南.md) |
| Flutter UI 框架研究报告 | [docs/Flutter-UI框架研究报告.md](Flutter-UI框架研究报告.md) |
| ER 图状态机设计 | [memory/er-diagram-state-machine.md](../.claude/memory/er-diagram-state-machine.md) |

---

> **总结**: 本工作流提供了清晰的分阶段重构路径，优先保持现有功能稳定，渐进式引入 TDesign 组件。关键是保留现有的 InteractiveViewer + 状态机架构，仅替换 UI 层组件。