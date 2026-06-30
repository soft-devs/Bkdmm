# Changelog - shared/models

> 模块变更历史。最新变更在最上方。
> 排查问题时优先阅读本文件。

---

## [2026-06-25] refactor: ER图模块重构 - 简化数据层

**类型**: refactor
**提交**: a7ff5ef
**风险**: MEDIUM

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| entity.dart | +50/-30 | 简化 Entity 模型 |
| module.dart | +80/-40 | 简化 Module 模型 |
| field.dart | 合入 entity.dart | 移除独立 Field 文件 |

### 影响范围
- **数据模型**: Entity/Field/Index 合并定义
- **API**: 无变化，保持向后兼容

---

## [2026-06-24] feat: 优化实体编辑器和数据模型

**类型**: feat
**提交**: 3d89593
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| project.dart | +30 | 新增 Profile 默认字段 |
| data_type.dart | +50 | 新增 Java 类型映射 |

### 影响范围
- **数据模型**: Profile 支持默认字段配置
- **功能**: DataType 支持 Java 类型映射

---

## [2026-06-22] feat: 初始化数据模型

**类型**: feat
**提交**: 607e59b
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| project.dart | +100 | 项目模型 |
| entity.dart | +120 | 实体模型 |
| module.dart | +150 | 模块模型 |
| data_type.dart | +80 | 数据类型模型 |
| version.dart | +90 | 版本快照模型 |
| project_history.dart | +40 | 项目历史模型 |

### 影响范围
- **数据模型**: 核心模型定义
- **JSON**: 支持 json_serializable 序列化

---

## [2026-06-22] feat: 初始化 Bkdmm Flutter 项目

**类型**: feat
**提交**: 2dc7fbe
**风险**: LOW

### 变更文件
| 文件 | 变更 | 说明 |
|------|------|------|
| models.dart | +10 | 模型导出文件 |

### 影响范围
- **API**: 模型导出入口
