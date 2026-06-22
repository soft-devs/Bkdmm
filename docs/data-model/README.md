# 数据模型设计

> **阅读时机**: 开发数据存储、状态管理、文件读写功能时

---

## 项目文件结构

项目文件采用 JSON 格式存储，扩展名为 `.bkdmm.json`：

```dart
// lib/shared/models/project.dart

class Project {
  // 项目元信息
  final String id;                    // 项目唯一标识
  final String name;                  // 项目名称
  final String? description;          // 项目描述
  final String version;               // 项目版本
  final DateTime createdAt;           // 创建时间
  final DateTime updatedAt;           // 更新时间

  // 数据模型
  final List<Module> modules;         // 模块列表

  // 数据类型配置
  final DataTypeDomains dataTypeDomains;

  // 项目配置
  final Profile profile;

  // 版本历史
  final List<VersionSnapshot>? versionHistory;
}
```

---

## 核心数据模型

### Module 模块

```dart
// lib/shared/models/module.dart

class Module {
  final String id;
  final String name;                  // 模块代码（英文）
  final String chnname;               // 模块中文名
  final String? description;
  final List<Entity> entities;        // 数据表列表
  final GraphCanvas graphCanvas;      // 关系图画布
  final DateTime createdAt;
  final DateTime updatedAt;
}

class GraphCanvas {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Viewport? viewport;           // 视口状态
}

class GraphNode {
  final String title;                 // 格式: 表名:序号
  final double x;
  final double y;
  final String? moduleName;           // 所属模块名
}

class GraphEdge {
  final String source;                // 源节点
  final String target;                // 目标节点
  final String? label;                // 关系标签
}
```

### Entity 数据表

```dart
// lib/shared/models/entity.dart

class Entity {
  final String id;
  final String title;                 // 表代码（英文）
  final String chnname;               // 表中文名
  final String? remark;
  final List<Field> fields;           // 字段列表
  final List<Index> indexes;          // 索引列表
  final List<Relation>? relations;    // 关联关系
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Field {
  final String id;
  final String name;                  // 字段名
  final String type;                  // 数据类型（抽象类型code）
  final String chnname;               // 字段中文名
  final String? remark;
  final bool pk;                      // 是否主键
  final bool notNull;                 // 是否非空
  final bool autoIncrement;           // 是否自增
  final String? defaultValue;
  final int? length;
  final int? decimal;
}

class Index {
  final String id;
  final String name;
  final List<String> fields;          // 索引字段列表
  final IndexType type;               // NORMAL/UNIQUE/FULLTEXT
  final String? remark;
}

enum IndexType {
  normal,
  unique,
  fulltext,
}
```

### DataType 数据类型

```dart
// lib/shared/models/data_type.dart

class DataTypeDomains {
  final List<DataType> datatype;
  final List<DatabaseTemplate> database;
}

class DataType {
  final String id;
  final String name;                  // 类型代码
  final String chnname;               // 类型中文名
  final String? remark;
  final Map<String, String> apply;    // 各数据库映射
  final String? java;                 // Java类型映射
}

class DatabaseTemplate {
  final String code;                  // 数据库代码(MYSQL/ORACLE等)
  final String name;
  final bool defaultDatabase;
  final TemplateConfig template;
}
```

---

## 预设数据类型

| 类型代码 | 中文名 | MySQL映射 | Java映射 |
|----------|--------|-----------|----------|
| IdOrKey | 标识键 | VARCHAR(32) | String |
| Name | 名称 | VARCHAR(128) | String |
| Intro | 简介 | VARCHAR(512) | String |
| LongText | 长文本 | TEXT | String |
| Integer | 整数 | INT | Integer |
| Long | 长整数 | BIGINT | Long |
| Money | 金额 | DECIMAL(32,8) | BigDecimal |
| DateTime | 日期时间 | DATETIME | LocalDateTime |
| YesNo | 是否 | VARCHAR(1) | String |
| Dict | 字典 | VARCHAR(32) | String |

---

## 模板配置结构

```dart
// lib/shared/models/template_config.dart

class TemplateConfig {
  // DDL模板
  final String createTableTemplate;
  final String deleteTableTemplate;
  final String rebuildTableTemplate;
  final String createFieldTemplate;
  final String updateFieldTemplate;
  final String deleteFieldTemplate;
  final String createIndexTemplate;
  final String deleteIndexTemplate;

  // 代码模板
  final String? entityTemplate;
  final String? mapperTemplate;
}
```

---

## 版本管理模型

```dart
// lib/shared/models/version.dart

class VersionSnapshot {
  final String id;
  final String version;
  final String? description;
  final ProjectData snapshot;         // 数据快照
  final DateTime createdAt;
  final String? createdBy;
}

class ChangeRecord {
  final String id;
  final ChangeType type;              // table/field/index/relation
  final ChangeOperation operation;    // add/delete/update
  final ChangeTarget target;
  final dynamic before;
  final dynamic after;
  final String rollbackSQL;
  final DateTime createdAt;
}

enum ChangeType {
  table,
  field,
  index,
  relation,
}

enum ChangeOperation {
  add,
  delete,
  update,
}

class ChangeTarget {
  final String moduleId;
  final String? entityId;
  final String? fieldId;
  final String? indexId;
}
```

---

## JSON 序列化

推荐使用 `json_serializable` 包自动生成序列化代码：

```dart
// lib/shared/models/entity.dart

import 'package:json_annotation/json_annotation.dart';

part 'entity.g.dart';

@JsonSerializable()
class Entity {
  final String id;
  final String title;
  final String chnname;
  // ...
  
  Entity({
    required this.id,
    required this.title,
    required this.chnname,
    // ...
  });

  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);
  Map<String, dynamic> toJson() => _$EntityToJson(this);
}
```

---

## 数据存储方案

### 方案一: Hive (推荐)

```dart
// lib/shared/services/storage_service.dart

import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late Box<Project> projectBox;
  static late Box<ProjectHistory> historyBox;
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // 注册适配器
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(ModuleAdapter());
    Hive.registerAdapter(EntityAdapter());
    // ...
    
    projectBox = await Hive.openBox<Project>('projects');
    historyBox = await Hive.openBox<ProjectHistory>('history');
  }
  
  // 项目操作
  Future<Project?> getProject(String id) => projectBox.get(id);
  Future<void> saveProject(Project project) => projectBox.put(project.id, project);
  Future<void> deleteProject(String id) => projectBox.delete(id);
}
```

### 方案二: 文件存储

```dart
// lib/shared/services/file_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String> getProjectPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/projects';
  }
  
  Future<Project> readProject(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return Project.fromJson(jsonDecode(content));
  }
  
  Future<void> saveProject(Project project, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(jsonEncode(project.toJson()));
  }
}
```

---

## 相关文档

- [项目管理功能](../features/project/README.md)
- [数据类型系统](../features/datatype/README.md)