# Changelog - features/modeling

> 模块变更历史。最新变更在最上方。
> 排查问题时优先阅读本文件。

---

## [2026-06-29] refactor: 优化实体编辑器表格组件

**类型**: refactor
**提交**: 600894f
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| entity_editor/views/entity_editor_view.dart | +150/-80 | 优化表格布局和交互 |
| entity_editor/widgets/field_table.dart | +200/-100 | 字段表格组件重构 |
| entity_editor/widgets/index_editor.dart | +80/-40 | 索引编辑器优化 |

### 影响范围
- **API**: FieldTable 新增 onFieldReorder 回调
- **UI**: 表格支持拖拽排序
- **性能**: 虚拟滚动优化

---

## [2026-06-29] feat: 图编辑器 V2 重构 - 视图系统与行为层

**类型**: feat
**提交**: 97cb08f
**风险**: HIGH

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| er_diagram/widgets/er_diagram_canvas.dart | +500/-300 | V2 画布实现 |
| er_diagram/widgets/er_table_node_widget.dart | +150/-80 | 表节点组件适配 |
| er_diagram/core/er_graph_builder.dart | +200 | 图构建器 |

### 影响范围
- **API**: ERDiagramCanvas 新版接口
- **跨模块**: 依赖 shared/diagram_editor V2
- **数据模型**: ERDiagramUIState 新增字段

### 回滚指南
- 回滚: `git revert 97cb08f`
- 检查文件: er_diagram/widgets/, er_diagram/core/
- 副作用: 需要同时回退 diagram_editor

---

## [2026-06-28] fix: 修复 V2 画布事件处理问题

**类型**: fix
**提交**: 2d2f1c3
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| er_diagram/widgets/er_diagram_canvas.dart | +80/-30 | 修复事件传递 |
| er_diagram/core/er_graph_builder.dart | +30 | 节点位置计算修复 |

### 影响范围
- **API**: 事件处理链修复
- **修复**: 节点点击响应问题

---

## [2026-06-27] refactor: 回退到 V1 版本的 ER 图事件处理

**类型**: refactor
**提交**: 0bc5343
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| er_diagram/widgets/er_diagram_canvas.dart | +100/-150 | 回退到 V1 事件处理 |

### 影响范围
- **API**: 暂时禁用 V2 特性
- **原因**: V2 事件处理不稳定

---

## [2026-06-22] feat: 初始化实体编辑器模块

**类型**: feat
**提交**: 607e59b
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| entity_editor/entity_editor.dart | +50 | 模块导出 |
| entity_editor/providers/entity_provider.dart | +300 | 实体状态管理 |
| entity_editor/views/entity_editor_view.dart | +400 | 实体编辑器视图 |
| entity_editor/widgets/field_table.dart | +350 | 字段表格 |

### 影响范围
- **API**: EntityProvider, EntityEditorView
- **功能**: 实体字段编辑、索引管理

