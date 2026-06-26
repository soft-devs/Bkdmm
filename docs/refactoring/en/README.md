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

*最后更新: 2025-06-26*