# Changelog - shared/diagram_editor

> 模块变更历史。最新变更在最上方。
> 排查问题时优先阅读本文件。

---

## [2026-06-29] feat: 图编辑器 V2 重构 - 视图系统与行为层

**类型**: feat
**提交**: 97cb08f
**风险**: HIGH

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| diagram_editor.dart | +163/-50 | 新版编辑器入口，集成新架构 |
| behavior/behavior.dart | +172 | 新增行为层抽象 |
| behavior/behavior_registry.dart | +409 | 新增行为注册表 |
| behavior/connection_behavior.dart | +814 | 新增连线行为 |
| behavior/node_drag_behavior.dart | +475 | 新增节点拖拽行为 |
| behavior/pan_zoom_behavior.dart | +812 | 新增平移缩放行为 |
| behavior/selection_behavior.dart | +315 | 新增选择行为 |
| view/graph_view.dart | +850 | 完整视图实现 |
| view/painter/*.dart | +1500 | 绘制器实现 |

### 影响范围
- **API**: DiagramEditor 新增 behavior 属性，支持行为注册
- **跨模块**: features/modeling/er_diagram 需要适配新接口
- **数据模型**: 新增 BehaviorRegistry, Behavior 基类

### 回滚指南
- 回滚: `git revert 97cb08f`
- 检查文件: behavior/, view/, diagram_editor.dart
- 副作用: V2 功能不可用，需使用 V1 实现

---

## [2026-06-29] feat: 添加图编辑器事件系统和数据模型

**类型**: feat
**提交**: caea90d
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| event/event_center.dart | +280 | 事件中心实现 |
| event/event_types.dart | +120 | 事件类型定义 |
| model/graph_model.dart | +450 | 图数据模型 |
| model/node_model.dart | +180 | 节点模型 |
| model/edge_model.dart | +160 | 边模型 |
| model/transform_model.dart | +300 | 变换模型 |

### 影响范围
- **API**: 新增 EventCenter, GraphModel, NodeModel, EdgeModel
- **数据模型**: 完整的图编辑器数据层
- **事件**: DiagramEventTypes 定义所有事件类型

---

## [2026-06-26] feat: 实现图表编辑器重构 Phase 1-3

**类型**: feat
**提交**: b989579
**风险**: HIGH

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| core/diagram_node.dart | +120 | 核心节点抽象 |
| core/diagram_edge.dart | +100 | 核心边抽象 |
| core/diagram_state.dart | +150 | 编辑器状态 |
| spatial/spatial_index.dart | +100 | 空间索引接口 |
| spatial/simple_index.dart | +150 | 简单索引实现 |
| commands/diagram_command.dart | +180 | 命令系统 |
| commands/history_controller.dart | +120 | 历史控制器 |

### 影响范围
- **API**: 新增 DiagramNode, DiagramEdge, DiagramState 抽象
- **架构**: 分层架构确立 (Core → Model → Event → Handler → Behavior → View)
- **命令**: 支持撤销重做

### 回滚指南
- 回滚: `git revert b989579`
- 检查文件: core/, spatial/, commands/
- 副作用: 基础架构不可用

---

## [2026-06-22] feat: 初始化 Bkdmm Flutter 项目

**类型**: feat
**提交**: 2dc7fbe
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| pubspec.yaml | +80 | 项目配置 |
| lib/main.dart | +30 | 应用入口 |
| lib/app/app.dart | +100 | 主应用 |

### 影响范围
- **API**: 项目初始化
- **配置**: Flutter 3.8+, TDesign Flutter, Riverpod

