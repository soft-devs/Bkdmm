# 图编辑器 V2 重构工作流

全面重构 Bkdmm 图编辑器，基于 LogicFlow 架构思想。

---

## 项目概览

| 项目 | 说明 |
|------|------|
| **目标** | 将 V1 图编辑器重构为 Model-View 分离架构 |
| **架构参考** | LogicFlow (ts) → Flutter 适配 |
| **核心改进** | 手动 TransformModel、EventCenter、Model-View 分离 |
| **当前状态** | ✅ Phase 1-4 已完成，ER 图已迁移 |

---

## 阶段规划

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              重构工作流                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ Phase 1  │──►│ Phase 2  │──►│ Phase 3  │──►│ Phase 4  │──►│ Phase 5  │  │
│  │ 核心框架  │   │ 渲染层   │   │ 交互行为  │   │ ER迁移   │   │ 清理扩展  │  │
│  │ ✅ 完成   │   │ ✅ 完成   │   │ ✅ 完成   │   │ ✅ 完成   │   │ ✅ 完成   │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
│       │              │              │              │              │         │
│       ▼              ▼              ▼              ▼              ▼         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ 单元测试  │   │ 单元测试  │   │ 集成测试  │   │ 功能验证  │   │ 全量测试  │  │
│  │ ✅       │   │ ✅       │   │ ✅       │   │ ✅       │   │ 待完善   │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: 核心框架 ✅ 已完成

### 输出文件

```
lib/shared/diagram_editor/src/
├── core/
│   ├── diagram_node.dart          # DiagramNode 抽象类
│   ├── diagram_edge.dart          # DiagramEdge 抽象类
│   └── diagram_state.dart         # DiagramState 状态容器
│
├── model/
│   ├── graph_model.dart           # 图数据模型
│   ├── node_model.dart            # NodeModel 实现
│   ├── edge_model.dart            # EdgeModel 实现
│   └── transform_model.dart       # 视口变换模型
│
├── event/
│   ├── event_center.dart          # 事件中心
│   └── event_types.dart           # 事件类型常量
│
├── handlers/
│   ├── diagram_event.dart         # 事件定义
│   ├── diagram_context.dart       # 处理上下文
│   ├── diagram_handler.dart       # 处理器基类
│   ├── handler_registry.dart      # 处理器注册表
│   ├── pointer_handler.dart       # 指针事件入口
│   ├── anchor_click_handler.dart  # 锚点点击处理
│   ├── node_drag_handler.dart     # 节点拖动处理
│   ├── selection_handler.dart     # 框选处理
│   └── canvas_pan_handler.dart    # 画布平移处理
│
├── spatial/
│   ├── spatial_index.dart         # 空间索引接口
│   └── simple_index.dart          # 简单实现
│
└── commands/
    ├── diagram_command.dart       # 命令基类
    └── history_controller.dart    # 历史控制器
```

### 完成的功能

- [x] GraphModel - 图数据管理
- [x] NodeModel - 节点模型
- [x] EdgeModel - 边模型
- [x] TransformModel - 视口变换
- [x] EventCenter - 事件系统
- [x] Handler 系统 - 事件处理
- [x] HistoryController - 历史记录

---

## Phase 2: 渲染层 ✅ 已完成

### 输出文件

```
lib/shared/diagram_editor/src/
├── view/
│   ├── graph_view.dart            # 主视图
│   ├── canvas_overlay.dart        # 画布层
│   ├── modification_overlay.dart   # 交互层
│   ├── tool_overlay.dart          # 工具层
│   │
│   └── painter/
│       ├── node_painter.dart      # 节点绘制
│       ├── edge_painter.dart      # 边绘制
│       └── grid_painter.dart      # 网格绘制
```

### 完成的功能

- [x] GraphView - Stack 分层结构
- [x] CanvasOverlay - CustomPaint 渲染
- [x] GridPainter - 网格绘制
- [x] NodePainter - 节点绘制
- [x] EdgePainter - 边绘制

---

## Phase 3: 交互行为 ✅ 已完成

### 输出文件

```
lib/shared/diagram_editor/src/
├── behavior/
│   ├── behavior.dart              # Behavior 基类
│   ├── behavior_registry.dart     # Behavior 注册表
│   ├── node_drag_behavior.dart    # 节点拖动
│   ├── selection_behavior.dart    # 框选
│   ├── connection_behavior.dart   # 连线
│   └── pan_zoom_behavior.dart     # 平移缩放
```

### 完成的功能

- [x] Behavior 基类和注册机制
- [x] NodeDragBehavior - 节点拖动
- [x] SelectionBehavior - 框选
- [x] ConnectionBehavior - 连线
- [x] PanZoomBehavior - 平移缩放

---

## Phase 4: ER 图迁移 ✅ 已完成

### 输出文件

```
lib/shared/diagram_editor/src/
├── integration/
│   ├── er_interaction_manager.dart    # ER 交互管理器
│   └── er_interaction_provider.dart   # Riverpod Provider
│
├── er/
│   ├── er_table_node_model.dart       # ER 表节点模型
│   ├── er_relation_edge_model.dart    # ER 关系边模型
│   ├── er_table_painter.dart          # ER 表绘制器
│   └── er_relation_painter.dart       # ER 关系绘制器

lib/features/modeling/er_diagram/
├── er_diagram.dart                    # 导出文件
├── models/
│   └── er_diagram_ui_state.dart       # UI 状态模型
├── providers/
│   └── er_diagram_ui_provider.dart    # Riverpod Provider
└── widgets/
    ├── er_diagram_canvas.dart         # 主画布
    ├── er_table_node_widget.dart      # 表节点 Widget
    └── er_field_anchor_widget.dart    # 字段锚点 Widget
```

### 完成的功能

- [x] ERDiagramCanvas - 基于 GraphView 的主画布
- [x] ERDiagramUIState - UI 状态管理
- [x] ERDiagramUINotifier - Riverpod StateNotifier
- [x] ERTableNodeWidget - 表节点渲染
- [x] ERFieldAnchorWidget - 字段锚点
- [x] 节点选择（单选/多选/Ctrl+点击）
- [x] 节点拖动（单节点/多选）
- [x] 连线开始/预览/完成
- [x] 框选功能
- [x] 画布平移/缩放
- [x] 预览/编辑模式切换

---

## Phase 5: 清理和扩展 ✅ 已完成

### 已完成

- [x] 删除 V1 版本代码
  - [x] 删除 `er_diagram_canvas.dart` (V1)
  - [x] 删除 `er_graph_builder.dart`
  - [x] 删除 `layout_adapter.dart`
  - [x] 删除 `core/` 和 `layout/` 空目录

- [x] 重命名 V2 文件
  - [x] `er_diagram_canvas_v2.dart` → `er_diagram_canvas.dart`
  - [x] 类名 `ERDiagramCanvasV2` → `ERDiagramCanvas`

- [x] 更新导出和引用
  - [x] 更新 `er_diagram.dart` 导出
  - [x] 更新 `workspace_view.dart` 引用

### 待完善

- [ ] 全量测试覆盖
- [ ] 性能优化（大节点数量）
- [ ] 自动布局算法
- [ ] 完整的 Undo/Redo 集成
- [ ] 键盘快捷键支持

---

## 文件结构总览

```
lib/shared/diagram_editor/
├── diagram_editor.dart              # 导出文件（门面 API）
│
├── src/
│   ├── diagram_editor.dart          # DiagramEditor 主入口类
│   │
│   ├── core/                        # 核心抽象
│   │   ├── diagram_node.dart
│   │   ├── diagram_edge.dart
│   │   └── diagram_state.dart
│   │
│   ├── model/                       # 数据模型
│   │   ├── node_model.dart
│   │   ├── edge_model.dart
│   │   ├── transform_model.dart
│   │   └── graph_model.dart
│   │
│   ├── event/                       # 事件系统
│   │   ├── event_types.dart
│   │   └── event_center.dart
│   │
│   ├── handlers/                    # 事件处理器
│   │   ├── diagram_event.dart
│   │   ├── diagram_context.dart
│   │   ├── diagram_handler.dart
│   │   ├── handler_registry.dart
│   │   ├── pointer_handler.dart
│   │   ├── anchor_click_handler.dart
│   │   ├── node_drag_handler.dart
│   │   ├── selection_handler.dart
│   │   └── canvas_pan_handler.dart
│   │
│   ├── behavior/                    # 可复用行为
│   │   ├── behavior.dart
│   │   ├── behavior_registry.dart
│   │   ├── node_drag_behavior.dart
│   │   ├── selection_behavior.dart
│   │   ├── connection_behavior.dart
│   │   └── pan_zoom_behavior.dart
│   │
│   ├── spatial/                     # 空间索引
│   │   ├── spatial_index.dart
│   │   └── simple_index.dart
│   │
│   ├── commands/                    # 命令系统
│   │   ├── diagram_command.dart
│   │   └── history_controller.dart
│   │
│   ├── integration/                 # 集成管理
│   │   ├── er_interaction_manager.dart
│   │   └── er_interaction_provider.dart
│   │
│   ├── view/                        # 视图渲染
│   │   ├── graph_view.dart
│   │   ├── canvas_overlay.dart
│   │   ├── modification_overlay.dart
│   │   ├── tool_overlay.dart
│   │   └── painter/
│   │       ├── node_painter.dart
│   │       ├── edge_painter.dart
│   │       └── grid_painter.dart
│   │
│   └── er/                          # ER 图扩展
│       ├── er_table_node_model.dart
│       ├── er_relation_edge_model.dart
│       ├── er_table_painter.dart
│       └── er_relation_painter.dart
│
└── test/                            # 测试
    ├── model_test.dart
    ├── event_test.dart
    └── view_test.dart
```

---

## 技术要点

### 1. 坐标转换

```dart
// 屏幕坐标 → 画布坐标
Offset toCanvasPoint(Offset screen) {
  return Offset(
    (screen.dx - translateX) / scaleX,
    (screen.dy - translateY) / scaleY,
  );
}

// 画布坐标 → 屏幕坐标
Offset toScreenPoint(Offset canvas) {
  return Offset(
    canvas.dx * scaleX + translateX,
    canvas.dy * scaleY + translateY,
  );
}
```

### 2. 事件分发

```dart
void handlePointerDown(PointerDownEvent event) {
  final canvasPoint = graphModel.toCanvasPoint(event.localPosition);
  final hitResult = graphModel.hitTest(canvasPoint);

  if (hitResult.isOnAnchor) {
    eventCenter.emit(EventTypes.anchorClick, AnchorEventArgs(...));
  } else if (hitResult.isOnNode) {
    eventCenter.emit(EventTypes.nodeClick, NodeEventArgs(...));
  } else {
    eventCenter.emit(EventTypes.canvasClick, CanvasEventArgs(...));
  }
}
```

### 3. Behavior 优先级

```dart
final behaviors = [
  ConnectionBehavior(priority: 10),   // 最高优先级
  NodeDragBehavior(priority: 20),
  SelectionBehavior(priority: 50),
  PanZoomBehavior(priority: 100),     // 最低优先级
];

behaviors.sort((a, b) => a.priority.compareTo(b.priority));
```

---

*最后更新: 2026-06-29*