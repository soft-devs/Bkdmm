# features/datatype - 数据类型管理

抽象数据类型与数据库类型映射管理。

## 概述

该模块管理数据类型定义，支持抽象类型到各数据库具体类型的映射。

## 文件结构

```
features/datatype/
├── datatype.dart              # 模块导出
├── providers/
│   └── datatype_provider.dart # 数据类型状态管理
└── views/
    ├── datatype_view.dart     # 数据类型列表视图
    └── datatype_edit_dialog.dart  # 数据类型编辑对话框
```

## 核心概念

### 抽象数据类型

Bkdmm 使用抽象数据类型概念，一个抽象类型可以映射到不同数据库的具体类型：

```
抽象类型: String
├── MySQL → VARCHAR(255)
├── PostgreSQL → VARCHAR(255)
├── Oracle → VARCHAR2(255)
└── SQL Server → NVARCHAR(255)
```

### 默认数据类型

| 类型 | 中文名 | MySQL | PostgreSQL | Oracle |
|------|--------|-------|------------|--------|
| String | 字符串 | VARCHAR | VARCHAR | VARCHAR2 |
| Text | 长文本 | TEXT | TEXT | CLOB |
| Integer | 整数 | INT | INTEGER | NUMBER |
| Long | 长整数 | BIGINT | BIGINT | NUMBER |
| Decimal | 小数 | DECIMAL | DECIMAL | NUMBER |
| Boolean | 布尔 | TINYINT | BOOLEAN | NUMBER(1) |
| Date | 日期 | DATE | DATE | DATE |
| DateTime | 日期时间 | DATETIME | TIMESTAMP | TIMESTAMP |
| UUID | 唯一标识 | VARCHAR(36) | UUID | VARCHAR2(36) |

## DatatypeView

数据类型管理视图。

### 功能

- 显示所有数据类型列表
- 添加新数据类型
- 编辑现有数据类型
- 删除数据类型
- 搜索/过滤数据类型

### 列表字段

| 字段 | 说明 |
|------|------|
| 代码 | 类型标识 (如 String, Integer) |
| 中文名 | 类型中文名称 |
| MySQL | MySQL 类型映射 |
| PostgreSQL | PostgreSQL 类型映射 |
| Java | Java 类型映射 |

## DatatypeEditDialog

数据类型编辑对话框。

### 可编辑字段

- **代码** - 类型标识，英文，唯一
- **中文名** - 类型中文名称
- **备注** - 类型说明
- **数据库映射** - 各数据库的具体类型
- **Java 类型** - 对应的 Java 类型

### 使用示例

```dart
// 编辑现有数据类型
final result = await showDialog<bool>(
  context: context,
  builder: (context) => DatatypeEditDialog(
    dataType: existingType,  // null 表示新建
  ),
);

if (result == true) {
  ref.read(datatypeProvider.notifier).updateDataType(updated);
}
```

## DatatypeProvider

数据类型状态管理。

### 状态类

```dart
class DatatypeState {
  final List<DataType> datatypes;    // 数据类型列表
  final List<DatabaseTemplate> databases; // 数据库模板列表
  final DataType? selectedType;      // 当前选中类型
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `loadDatatypes()` | 加载数据类型 |
| `addDataType(DataType type)` | 添加数据类型 |
| `updateDataType(DataType type)` | 更新数据类型 |
| `removeDataType(String id)` | 删除数据类型 |
| `getDatabaseType(String typeId, String dbCode)` | 获取数据库类型映射 |

## 数据类型配置存储

数据类型配置保存在项目的 `dataTypeDomains` 字段：

```json
{
  "dataTypeDomains": {
    "datatype": [
      {
        "id": "1",
        "name": "String",
        "chnname": "字符串",
        "apply": {
          "MYSQL": "VARCHAR(255)",
          "POSTGRESQL": "VARCHAR(255)",
          "ORACLE": "VARCHAR2(255)"
        },
        "java": "String"
      }
    ],
    "database": [
      {
        "code": "MYSQL",
        "name": "MySQL",
        "defaultDatabase": true,
        "template": {...}
      }
    ]
  }
}
```

## 注意事项

1. **默认类型** - 系统内置默认数据类型，不可删除但可修改
2. **类型依赖** - 已被使用的类型修改后需同步更新相关表
3. **映射完整性** - 添加新数据类型时需为所有支持的数据库配置映射
4. **Java 类型** - 代码生成时使用，需确保类型正确
5. **项目隔离** - 数据类型配置是项目级别的，不同项目可不同配置