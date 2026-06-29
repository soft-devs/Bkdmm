# Changelog - shared/models

> 模块变更历史。最新变更在最上方。
> 排查问题时优先阅读本文件。

---

## [2026-06-24] 自动提交: 优化实体编辑器和数据模型

**类型**: refactor
**提交**: 3d89593
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| entity.dart | 优化 | 实体模型字段优化 |
| module.dart | 优化 | 模块模型结构调整 |

### 影响范围
- **API**: 无变化，内部结构优化
- **跨模块**: 无
- **数据模型**: 字段验证方法增强

---

## [2026-06-22] feat: 初始化 Bkdmm Flutter 项目

**类型**: feat
**提交**: 2dc7fbe
**风险**: N/A

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| models.dart | 新增 | 模型导出文件 |
| entity.dart | 新增 | Entity, Field, Index 模型 |
| module.dart | 新增 | Module, GraphCanvas 模型 |
| project.dart | 新增 | Project, Profile 模型 |
| data_type.dart | 新增 | DataTypeDomains 模型 |
| project_history.dart | 新增 | ProjectHistory 模型 |
| version.dart | 新增 | VersionSnapshot 模型 |

### 影响范围
- **API**: 项目初始化，所有模型首次创建
- **跨模块**: 基础模型定义
- **数据模型**: 核心数据结构确立