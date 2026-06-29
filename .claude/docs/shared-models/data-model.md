# 数据模型详解

## Project - 项目模型

```dart
class Project {
  final String id;              // 项目唯一标识
  final String name;            // 项目名称
  final String? description;    // 项目描述
  final String version;         // 项目版本 (默认 "1.0.0")
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间
  final List<Module> modules;   // 模块列表
  final DataTypeDomains dataTypeDomains; // 数据类型配置
  final Profile profile;        // 项目配置
  final List<VersionSnapshot>? versionHistory; // 版本历史
}
```

## Module - 模块模型

```dart
class Module {
  final String id;              // 模块唯一标识
  final String name;            // 模块代码（英文）
  final String chnname;         // 模块中文名
  final String? description;    // 模块描述
  final List<Entity> entities;  // 数据表列表
  final GraphCanvas graphCanvas; // 关系图画布
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间
}
```

## Entity - 数据表模型

```dart
class Entity {
  final String id;              // 表唯一标识
  final String title;           // 表代码（英文）
  final String chnname;         // 表中文名
  final String? remark;         // 表备注
  final List<Field> fields;     // 字段列表
  final List<Index> indexes;    // 索引列表
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间
}
```

### Entity 方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `primaryKeys` | `List<Field>` | 获取主键字段列表 |
| `validateFieldIds()` | `bool` | 验证字段ID唯一性 |
| `validateIndexIds()` | `bool` | 验证索引ID唯一性 |
| `validateAllIds()` | `bool` | 验证所有ID唯一性 |
| `hasEmptyFieldIds()` | `bool` | 检查是否有空ID字段 |
| `hasEmptyIndexIds()` | `bool` | 检查是否有空ID索引 |

## Field - 字段模型

```dart
class Field {
  final String id;              // 字段唯一标识
  final String name;            // 字段名
  final String type;            // 数据类型（抽象类型code）
  final String chnname;         // 字段中文名
  final String? remark;         // 字段备注
  final bool pk;                // 是否主键
  final bool notNull;           // 是否非空
  final bool autoIncrement;     // 是否自增
  final String? defaultValue;   // 默认值
  final int? length;            // 长度
  final int? decimal;           // 小数位数
}
```

## Index - 索引模型

```dart
class Index {
  final String id;              // 索引唯一标识
  final String name;            // 索引名称
  final List<String> fieldIds;  // 索引字段ID列表
  final IndexType type;         // 索引类型
  final String? remark;         // 索引备注
}

enum IndexType {
  normal,    // 普通索引
  unique,    // 唯一索引
  fulltext,  // 全文索引
}
```

### Index 方法

| 方法 | 返回类型 | 描述 |
|------|----------|------|
| `getFieldNames(fields)` | `List<String>` | 从字段ID获取字段名列表 |

## GraphCanvas - 图画布

```dart
class GraphCanvas {
  final List<GraphNode> nodes;   // 节点列表
  final List<GraphEdge> edges;   // 连线列表
  final Viewport? viewport;      // 视口状态
}

class GraphNode {
  final String title;      // 格式: 表名:序号
  final double x;          // X坐标
  final double y;          // Y坐标
  final String? moduleName;// 所属模块名
}

class GraphEdge {
  final String source;       // 源节点 (表名:序号)
  final String target;       // 目标节点 (表名:序号)
  final String? sourceField; // 源字段名
  final String? targetField; // 目标字段名
  final String? label;       // 关系标签
  final String? relationType;// 关系类型: 1:1, 1:N, N:1, N:M
}

class Viewport {
  final double scale;     // 缩放比例
  final double offsetX;   // X偏移量
  final double offsetY;   // Y偏移量
}
```

## DataType - 数据类型

```dart
class DataType {
  final String id;              // 类型唯一标识
  final String name;            // 类型代码
  final String chnname;         // 类型中文名
  final String? remark;         // 类型备注
  final Map<String, String> apply; // 各数据库映射 {数据库代码: 类型}
  final String? java;           // Java类型映射
}
```

### 数据库映射示例

```dart
DataType(
  id: '1',
  name: 'String',
  chnname: '字符串',
  apply: {
    'MYSQL': 'VARCHAR',
    'ORACLE': 'VARCHAR2',
    'POSTGRESQL': 'VARCHAR',
  },
  java: 'String',
)
```

## Profile - 项目配置

```dart
class Profile {
  final List<String> defaultFields;   // 默认字段列表
  final String defaultFieldsType;     // 默认字段类型
  final String? defaultDatabase;      // 默认数据库
  final Map<String, dynamic>? settings; // 其他设置
}
```

## VersionSnapshot - 版本快照

```dart
class VersionSnapshot {
  final String id;                  // 快照唯一标识
  final String version;             // 版本号
  final String? description;        // 版本描述
  final Map<String, dynamic> snapshot; // 数据快照
  final DateTime createdAt;         // 创建时间
  final String? createdBy;          // 创建者
}
```

## ChangeRecord - 变更记录

```dart
class ChangeRecord {
  final String id;              // 变更唯一标识
  final ChangeType type;        // 变更类型
  final ChangeOperation operation; // 变更操作
  final ChangeTarget target;    // 变更目标
  final dynamic before;         // 变更前数据
  final dynamic after;          // 变更后数据
  final String? rollbackSQL;    // 回滚SQL
  final DateTime createdAt;     // 创建时间
}

enum ChangeType { table, field, indexChange, relation }
enum ChangeOperation { add, delete, update }
```
