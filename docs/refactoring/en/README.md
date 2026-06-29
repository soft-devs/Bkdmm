# 图编辑器重构文档

基于 LogicFlow 架构重新设计 Bkdmm 图编辑器。

---

## 📚 文档索引

### 新架构设计

| # | 文档 | 说明 |
|---|------|------|
| 01 | [架构总览](01-architecture-overview.md) | V2 架构设计、核心组件、文件结构 |
| 02 | [数据模型](02-data-model.md) | GraphModel、NodeModel、TransformModel 设计 |
| 03 | [事件系统](03-event-system.md) | EventCenter 实现、事件类型、事件参数 |
| 04 | [实现指南](04-implementation-guide.md) | **LogicFlow 核心思想提取与 Flutter 适配代码** |

### 迁移参考

| # | 文档 | 说明 |
|---|------|------|
| 05 | [V1 迁移清单](05-v1-migration-checklist.md) | V1 功能清单、迁移状态、测试验证 |

### 工作流

| # | 文档 | 说明 |
|---|------|------|
| WF | [重构工作流](WORKFLOW.md) | **5 阶段重构计划、任务清单、验收标准** |

---

## 🎯 快速开始

### 1. 理解架构

阅读顺序：**04 → 01 → 02 → 03**

- [实现指南](04-implementation-guide.md) - 理解核心设计理念
- [架构总览](01-architecture-overview.md) - 查看整体架构
- [数据模型](02-data-model.md) - 深入 Model 设计
- [事件系统](03-event-system.md) - 了解事件机制

### 2. 核心改进

| V1 问题 | V2 解决方案 |
|---------|-------------|
| InteractiveViewer 拦截事件 | 手动 TransformModel |
| 事件分散在 Widget | EventCenter 统一管理 |
| Widget 与逻辑耦合 | Model-View 分离 |
| 状态管理混乱 | ChangeNotifier 响应式 |

### 3. 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                     DiagramEditor                           │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ GraphModel (数据模型)                                  │ │
│  │  - nodes: List<NodeModel>                             │ │
│  │  - edges: List<EdgeModel>                             │ │
│  │  - transformModel: TransformModel                     │ │
│  │  - eventCenter: EventCenter                           │ │
│  └───────────────────────────────────────────────────────┘ │
│                          │                                  │
│                          │ notifyListeners()                │
│                          ▼                                  │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ GraphView (渲染视图)                                   │ │
│  │  - CanvasOverlay (节点/边渲染)                         │ │
│  │  - ModificationOverlay (交互层)                        │ │
│  │  - ToolOverlay (工具层)                                │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 技术栈

| LogicFlow (TS) | Flutter 适配 |
|----------------|--------------|
| MobX `@observable` | `ChangeNotifier` |
| Preact `@observer` | `ListenableBuilder` |
| EventEmitter | 自定义 `EventCenter` |
| SVG 渲染 | `CustomPaint` |
| `<div>` 分层 | `Stack` widget |

---

## 📁 当前文件结构

```
lib/shared/diagram_editor/
├── diagram_editor.dart              # 导出文件（门面 API）
│
├── src/
│   ├── diagram_editor.dart          # DiagramEditor 主入口类
│   │
│   ├── core/                        # 核心抽象
│   │   ├── diagram_node.dart        # DiagramNode 抽象类
│   │   ├── diagram_edge.dart        # DiagramEdge 抽象类
│   │   └── diagram_state.dart       # DiagramState 状态容器
│   │
│   ├── model/                       # 数据模型
│   │   ├── node_model.dart          # NodeModel 实现
│   │   ├── edge_model.dart          # EdgeModel 实现
│   │   ├── transform_model.dart     # 视口变换模型
│   │   └ graph_model.dart           # 图数据模型
│   │
│   ├── event/                       # 事件系统
│   │   ├── event_types.dart         # 事件类型常量
│   │   └ event_center.dart          # 事件发射器
│   │
│   ├── handlers/                    # 事件处理器
│   │   ├── diagram_event.dart       # 事件定义
│   │   ├── diagram_context.dart     # 处理上下文
│   │   ├── diagram_handler.dart     # 处理器基类
│   │   ├── handler_registry.dart    # 处理器注册表
│   │   ├── pointer_handler.dart     # 指针事件入口
│   │   ├── anchor_click_handler.dart
│   │   ├── node_drag_handler.dart
│   │   ├── selection_handler.dart
│   │   └ canvas_pan_handler.dart
│   │
│   ├── behavior/                    # 可复用行为
│   │   ├── behavior.dart            # Behavior 基类
│   │   ├── behavior_registry.dart   # Behavior 注册表
│   │   ├── node_drag_behavior.dart
│   │   ├── selection_behavior.dart
│   │   ├── connection_behavior.dart
│   │   └ pan_zoom_behavior.dart
│   │
│   ├── spatial/                     # 空间索引
│   │   ├── spatial_index.dart       # 空间索引接口
│   │   └ simple_index.dart          # 简单实现
│   │
│   ├── commands/                    # 命令系统
│   │   ├── diagram_command.dart     # 命令基类
│   │   └ history_controller.dart    # 历史控制器
│   │
│   ├── integration/                 # 集成管理
│   │   ├── er_interaction_manager.dart
│   │   └ er_interaction_provider.dart
│   │
│   ├── view/                        # 视图渲染
│   │   ├── graph_view.dart          # 主视图
│   │   ├── canvas_overlay.dart      # 画布层
│   │   ├── modification_overlay.dart # 交互层
│   │   ├── tool_overlay.dart        # 工具层
│   │   └ painter/
│   │       ├── node_painter.dart
│   │       ├── edge_painter.dart
│   │       └ grid_painter.dart
│   │
│   └── er/                          # ER 图扩展
│       ├── er_table_node_model.dart
│       ├── er_relation_edge_model.dart
│       ├── er_table_painter.dart
│       └ er_relation_painter.dart
```

---

## 🚀 ER 图当前实现

### ER 图模块结构

```
lib/features/modeling/er_diagram/
├── er_diagram.dart                  # 导出文件
│
├── models/
│   └── er_diagram_ui_state.dart     # UI 状态模型
│
├── providers/
│   └ er_diagram_ui_provider.dart    # Riverpod Provider
│
└── widgets/
    ├── er_diagram_canvas.dart       # 主画布（基于 diagram_editor）
    ├── er_table_node_widget.dart    # 表节点 Widget
    └── er_field_anchor_widget.dart  # 字段锚点 Widget
```

### 核心组件

| 组件 | 说明 |
|------|------|
| `ERDiagramCanvas` | 主画布，使用 diagram_editor 的 GraphView |
| `ERDiagramUIState` | UI 状态（选择、悬停、拖拽、连线、框选） |
| `ERDiagramUINotifier` | Riverpod StateNotifier 管理 UI 状态 |
| `ERInteractionManager` | diagram_editor 集成管理器 |
| `ERTableNodeWidget` | 表节点渲染 |
| `ERFieldAnchorWidget` | 字段锚点渲染 |

### 交互模式

| 模式 | 说明 | 可用操作 |
|------|------|----------|
| **预览模式** | 只读查看 | 左键拖动画布、滚轮缩放、双击预览实体 |
| **编辑模式** | 可编辑 | 左键选节点/框选/拖动/连线、右键拖动画布、双击编辑实体 |

---

*最后更新: 2026-06-29*