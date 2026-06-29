# shared/models - 核心数据模型

## 概述

核心数据模型层，定义项目的所有实体结构。所有业务模块依赖此模块。

## 依赖

- `json_annotation` - JSON序列化注解
- `part '*.g.dart'` - 自动生成的序列化代码

## 模型清单

| 模型 | 描述 | 关键字段 |
|------|------|----------|
| Project | 项目模型 | id, name, modules, dataTypeDomains, profile |
| Module | 模块模型 | id, name, entities, graphCanvas |
| Entity | 数据表模型 | id, title, chnname, fields, indexes |
| Field | 字段模型 | id, name, type, pk, notNull, defaultValue |
| Index | 索引模型 | id, name, fieldIds, type |
| DataType | 数据类型 | id, name, apply(数据库映射), java |
| DataTypeDomains | 数据类型域 | datatype[], database[] |
| DatabaseTemplate | 数据库模板 | code, name, template |
| TemplateConfig | 模板配置 | createTableTemplate, entityTemplate... |
| VersionSnapshot | 版本快照 | version, snapshot |
| ChangeRecord | 变更记录 | type, operation, target, before/after |
| ProjectHistory | 项目历史 | path, name, lastOpenedAt |

## 核心关系

```
Project (1) ──┬── (N) Module
              │         │
              │         └── (N) Entity
              │                   │
              │                   ├── (N) Field
              │                   └── (N) Index
              │
              ├── DataTypeDomains
              │         │
              │         ├── (N) DataType
              │         └── (N) DatabaseTemplate
              │
              └── Profile (defaultFields, defaultDatabase)
```

## 关键方法

### Entity
- `primaryKeys` - 获取主键字段列表
- `validateFieldIds()` - 验证字段ID唯一性
- `validateIndexIds()` - 验证索引ID唯一性
- `validateAllIds()` - 验证所有ID唯一性

### Module
- `validateEntityIds()` - 验证Entity ID唯一性
- `validateAllIds()` - 验证模块内所有ID
- `fixAllIds()` - 修复所有空ID和重复ID

### DataType
- `getDatabaseType(code)` - 获取指定数据库的类型映射

## 使用示例

```dart
// 创建项目
final project = Project(
  id: IdGenerator.generate(),
  name: 'MyProject',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  dataTypeDomains: DataTypeDomains(datatype: [], database: []),
  profile: Profile(),
);

// 创建模块
final module = Module(
  id: IdGenerator.generate(),
  name: 'user',
  chnname: '用户模块',
  graphCanvas: GraphCanvas(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// JSON序列化
final json = project.toJson();
final restored = Project.fromJson(json);
```

## 详细文档

- [数据模型详解](data-model.md)
- [坑点与注意事项](pitfalls.md)
