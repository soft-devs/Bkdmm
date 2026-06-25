# Changelog - features/workspace

> 模块变更历史。最新变更在最上方。
> 排查问题时优先阅读本文件。

---

## [2026-06-25] 自动提交: 重构多个功能模块为组件化结构

**类型**: refactor
**提交**: 13e1ae4
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| widgets/module_tree.dart | -250行 | 提取组件到独立文件 |
| widgets/module_tree_item.dart | 新增 | 模块/实体树节点组件 |
| dialogs/module_dialogs.dart | 新增 | 6个对话框函数 |

### 影响范围
- **API**: ModuleTree 接口不变
- **跨模块**: 无
- **数据模型**: 无变化

### 回滚指南
- 回滚: `git revert 13e1ae4`
- 检查文件: module_tree.dart, module_tree_item.dart, module_dialogs.dart
- 副作用: 组件拆分后导入路径变化，需更新引用

---

## [2026-06-24] 自动提交: 设置模块重构为组件化结构

**类型**: refactor
**提交**: 788bd5f
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| widgets/property_section.dart | 新增 | 属性区块组件 |
| widgets/property_field.dart | 新增 | 属性字段组件 |
| widgets/stat_tile.dart | 新增 | 统计卡片组件 |

### 影响范围
- **API**: workspace_view 引用新组件
- **跨模块**: 无

---

## [2026-06-24] 自动提交: ER图画布优化与工作区布局改进

**类型**: perf
**提交**: c3a0b23
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| views/workspace_view.dart | 优化 | 布局性能优化 |
| widgets/bottom_view/ | 优化 | 底部视图渲染 |

### 影响范围
- **API**: 无变化
- **跨模块**: er_diagram 布局计算
- **数据模型**: 无

---

## [2026-06-24] 自动提交: 修复ER图渲染逻辑

**类型**: fix
**提交**: c2d1521
**风险**: HIGH

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| widgets/module_tree.dart | 修复 | 节点ID使用entity.id |

### 影响范围
- **API**: 模块树节点选择逻辑
- **跨模块**: er_diagram 节点标识
- **数据模型**: 节点ID生成策略

### 回滚指南
- 回滚: `git revert c2d1521`
- 检查文件: module_tree.dart
- 副作用: 节点ID变化可能导致选中状态异常

---

## [2026-06-23] 自动提交: 重构工作区为IDE风格布局

**类型**: feat
**提交**: 697ee5c
**风险**: HIGH

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| views/workspace_view.dart | 重构 | IDE风格三栏布局 |
| providers/layout_provider.dart | 新增 | 布局状态管理 |
| widgets/left_view/ | 新增 | 左侧视图容器 |
| widgets/bottom_view/ | 新增 | 底部视图容器 |
| widgets/toolbar/ | 新增 | 工具栏组件 |

### 影响范围
- **API**: 全新布局结构
- **跨模块**: 整体UI框架变更
- **数据模型**: LayoutState 新增

### 回滚指南
- 回滚: `git revert 697ee5c`
- 检查文件: workspace_view.dart 及所有子组件
- 副作用: 布局状态持久化格式变化