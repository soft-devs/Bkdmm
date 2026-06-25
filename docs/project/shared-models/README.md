# shared/models - 核心数据模型

## 概述

项目的核心数据模型层，定义了所有业务实体。无外部依赖，纯数据类。

## 模型清单

| 模型 | 文件 | 说明 |
|------|------|------|
| Entity | entity.dart | 数据表模型 |
| Field | entity.dart | 字段模型 (嵌套在Entity) |
| Index | entity.dart | 索引模型 (嵌套在Entity) |
| Module | module.dart | 模块模型 |
| GraphCanvas | module.dart | 关系图画布 (嵌套在Module) |
| GraphNode | module.dart | 图节点 (嵌套在GraphCanvas) |
| Project | project.dart | 项目模型 |
| DataTypeDomains | data_type.dart | 数据类型域 |
| Profile | project.dart | 项目配置 |
| ProjectHistory | project_history.dart | 项目历史记录 |
| VersionSnapshot | version.dart | 版本快照 |

## 核心模型关系

```
Project
├── id, name, description, version
├── modules: List<Module>
│   └── Module
│       ├── id, name, chnname, description
│       ├── entities: List<Entity>
│       │   └── Entity
│       │       ├── id, title, chnname, remark
│       │       ├── fields: List<Field>
│       │       │   └── Field
│       │       │       ├── id, name, chnname, type
│       │       │       ├── pk, allowNull, autoIncrement
│       │       │       ├── defaultValue, remark
│       │       └── indexes: List<Index>
│       └── graphCanvas: GraphCanvas
├── dataTypeDomains: DataTypeDomains
└── profile: Profile
```

## 关键类详解

### Entity (数据表)

```dart
class Entity {
  final String id;           // 表唯一标识
  final String title;        // 表代码（英文）
  final String chnname;      // 表中文名
  final String? remark;      // 表备注
  final List<Field> fields;  // 字段列表
  final List<Index> indexes; // 索引列表
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**常用方法**:
- `primaryKeys` - 获取主键字段列表
- `validateFieldIds()` - 验证字段ID唯一性
- `copyWith()` - 不可变更新

### Field (字段)

```dart
class Field {
  final String id;
  final String name;           // 字段名
  final String chnname;        // 字段中文名
  final String type;           // 数据类型
  final bool pk;               // 是否主键
  final bool allowNull;        // 是否允许空
  final bool autoIncrement;    // 是否自增
  final String? defaultValue;  // 默认值
  final String? remark;        // 备注
}
```

### Module (模块)

```dart
class Module {
  final String id;
  final String name;           // 模块代码
  final String chnname;        // 模块中文名
  final String? description;
  final List<Entity> entities; // 数据表列表
  final GraphCanvas graphCanvas; // 关系图画布
}
```

### Project (项目)

```dart
class Project {
  final String id;
  final String name;
  final String? description;
  final String version;
  final List<Module> modules;
  final DataTypeDomains dataTypeDomains;
  final Profile profile;
}
```

## JSON 序列化

所有模型使用 `json_annotation` 进行序列化：
- 使用 `@JsonSerializable()` 注解
- 生成 `.g.dart` 文件
- 提供 `fromJson()` 工厂方法和 `toJson()` 方法

## 使用示例

```dart
// 创建实体
final entity = Entity(
  id: IdGenerator.generate(),
  title: 'user_info',
  chnname: '用户信息表',
  fields: [],
  indexes: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// 不可变更新
final updated = entity.copyWith(
  chnname: '用户信息',
  updatedAt: DateTime.now(),
);

// JSON序列化
final json = entity.toJson();
final fromJson = Entity.fromJson(json);
```

## 坑点

1. **ID生成**: 必须使用 `IdGenerator.generate()` 生成唯一ID
2. **不可变更新**: 所有模型使用 `copyWith()` 更新，不可直接修改
3. **时间字段**: `createdAt`/`updatedAt` 需要手动维护
4. **JSON生成**: 修改模型后需运行 `flutter pub run build_runner build`

## 详细文档

- [data-model.md](data-model.md) - 数据模型详细字段说明
- [pitfalls.md](pitfalls.md) - 已知坑点
