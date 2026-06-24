# shared/models - 数据模型层

数据模型定义，所有模块依赖的核心数据结构。

## 概述

该模块定义了项目的核心数据模型，使用 `json_annotation` 进行 JSON 序列化，支持跨平台持久化。

## 模型列表

| 模型 | 文件 | 说明 |
|------|------|------|
| Project | project.dart | 项目模型，包含模块列表、数据类型配置、项目配置 |
| Module | module.dart | 模块模型，包含实体列表、图画布状态 |
| Entity | entity.dart | 数据表模型，包含字段列表、索引列表 |
| Field | entity.dart | 字段模型，定义表字段属性 |
| Index | entity.dart | 索引模型，定义表索引 |
| DataType | data_type.dart | 数据类型模型，抽象类型到各数据库的映射 |
| DataTypeDomains | data_type.dart | 数据类型域配置，包含所有数据类型和数据库模板 |
| DatabaseTemplate | data_type.dart | 数据库模板配置 |
| TemplateConfig | data_type.dart | DDL 模板配置 |
| VersionSnapshot | version.dart | 版本快照，用于版本管理 |
| ProjectHistory | project_history.dart | 项目历史记录 |

## 核心数据结构

### Project (项目)

```dart
class Project {
  final String id;                    // 项目唯一标识
  final String name;                  // 项目名称
  final String? description;          // 项目描述
  final String version;               // 项目版本
  final DateTime createdAt;           // 创建时间
  final DateTime updatedAt;           // 更新时间
  final List<Module> modules;         // 模块列表
  final DataTypeDomains dataTypeDomains; // 数据类型配置
  final Profile profile;              // 项目配置
  final List<VersionSnapshot>? versionHistory; // 版本历史
}
```

### Module (模块)

```dart
class Module {
  final String id;                    // 模块唯一标识
  final String name;                  // 模块代码（英文）
  final String chnname;               // 模块中文名
  final String? description;          // 模块描述
  final List<Entity> entities;        // 数据表列表
  final GraphCanvas graphCanvas;      // 关系图画布
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Entity (数据表)

```dart
class Entity {
  final String id;                    // 表唯一标识
  final String title;                 // 表代码（英文）
  final String chnname;               // 表中文名
  final String? remark;               // 表备注
  final List<Field> fields;           // 字段列表
  final List<Index> indexes;          // 索引列表
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Field (字段)

```dart
class Field {
  final String id;                    // 字段唯一标识
  final String name;                  // 字段名
  final String type;                  // 数据类型（抽象类型code）
  final String chnname;               // 字段中文名
  final String? remark;               // 字段备注
  final bool pk;                      // 是否主键
  final bool notNull;                 // 是否非空
  final bool autoIncrement;           // 是否自增
  final String? defaultValue;         // 默认值
  final int? length;                  // 长度
  final int? decimal;                 // 小数位数
}
```

### DataType (数据类型)

```dart
class DataType {
  final String id;                    // 类型唯一标识
  final String name;                  // 类型代码
  final String chnname;               // 类型中文名
  final String? remark;               // 类型备注
  final Map<String, String> apply;    // 各数据库映射 {数据库代码: 类型}
  final String? java;                 // Java类型映射
}
```

## 关系图

```
Project
├── Module[] (模块列表)
│   ├── Entity[] (数据表列表)
│   │   ├── Field[] (字段列表)
│   │   └── Index[] (索引列表)
│   └── GraphCanvas (图画布)
│       ├── GraphNode[] (节点列表)
│       └── GraphEdge[] (连线列表)
├── DataTypeDomains (数据类型配置)
│   ├── DataType[] (数据类型列表)
│   └── DatabaseTemplate[] (数据库模板列表)
├── Profile (项目配置)
└── VersionSnapshot[] (版本历史)
```

## 使用方式

```dart
import 'package:bkdmm/shared/models/models.dart';

// 创建项目
final project = Project(
  id: IdGenerator.generate(),
  name: 'My Project',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  modules: [],
  dataTypeDomains: DataTypeDomains(),
  profile: Profile(),
);

// JSON 序列化
final json = project.toJson();
final fromJson = Project.fromJson(json);
```

## 注意事项

1. **JSON 序列化** - 修改模型后需运行 `dart run build_runner build` 重新生成 `.g.dart` 文件
2. **不可变模型** - 所有模型使用 `final` 字段，修改时使用 `copyWith()` 方法
3. **ID 生成** - 使用 `IdGenerator.generate()` 生成唯一标识
4. **类型映射** - DataType.apply 是 Map，key 为数据库代码 (MYSQL/ORACLE/POSTGRESQL/SQLSERVER)
