# shared/diagram_editor - 图编辑器引擎

## 概述

**核心组件**: 通用图编辑器框架，支持多种图表类型扩展（ER图、流程图等）。提供节点/边管理、视口控制、选择管理、撤销重做、事件系统等功能。

## 依赖

- `graphview` - 图布局引擎
- `flutter_riverpod` - 状态管理
- `shared/models` - 数据模型

## 架构层次

```
┌─────────────────────────────────────────────────────────┐
│                    DiagramEditor                        │
│  (Facade - 统一API入口)                                  │
├─────────────────────────────────────────────────────────┤
│  GraphModel    │  SpatialIndex  │  EventCenter          │
│  (数据层)       │  (查询层)      │  (事件层)             │
├─────────────────────────────────────────────────────────┤
│  HandlerRegistry  │  BehaviorRegistry  │  HistoryCtrl   │
│  (事件处理)        │  (行为模块)         │  (命令系统)    │
├─────────────────────────────────────────────────────────┤
│  View 层: GraphView, NodePainter, EdgePainter, GridPainter │
├─────────────────────────────────────────────────────────┤
│  ER 层: ERTableNodeModel, ERRelationEdgeModel, ERTablePainter │
└─────────────────────────────────────────────────────────┘
```

## 核心模块

| 层级 | 模块 | 描述 |
|------|------|------|
| Core | DiagramNode, DiagramEdge, DiagramState | 核心抽象 |
| Model | NodeModel, EdgeModel, GraphModel, TransformModel | 数据模型 |
| Event | EventCenter, DiagramEventTypes | 事件系统 |
| Handler | HandlerRegistry, SelectionHandler, NodeDragHandler | 事件处理 |
| Behavior | BehaviorRegistry, PanZoomBehavior, ConnectionBehavior | 可复用行为 |
| Spatial | SpatialIndex, SimpleIndex | 空间索引 |
| Command | DiagramCommand, HistoryController | 命令系统 |
| View | GraphView, NodePainter, EdgePainter | 视图渲染 |
| ER | ERTableNodeModel, ERRelationEdgeModel | ER图扩展 |

## 详细文档

- [API文档](api-diagram.md)
- [数据模型](data-model.md)
- [坑点与注意事项](pitfalls.md)