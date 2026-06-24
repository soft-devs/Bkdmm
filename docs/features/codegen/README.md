# features/codegen - 代码生成

DDL 和 Java 代码生成，支持多数据库和自定义模板。

## 概述

该模块提供代码生成功能，基于 mustache 模板引擎，支持多种数据库 DDL 生成和 Java 实体类生成。

## 文件结构

```
features/codegen/
├── codegen.dart               # 模块导出
├── services/
│   ├── codegen_service.dart   # 代码生成服务
│   └── template_service.dart  # 模板服务
├── providers/
│   └── codegen_provider.dart  # 代码生成状态管理
└── views/
    └── codegen_view.dart      # 代码生成视图
```

## 支持的数据库

| 数据库 | 代码 | 说明 |
|------|------|------|
| MySQL | MYSQL | 默认支持 |
| PostgreSQL | POSTGRESQL | 默认支持 |
| Oracle | ORACLE | 默认支持 |
| SQL Server | SQLSERVER | 默认支持 |
| SQLite | SQLITE | 默认支持 |

## CodegenService

代码生成核心服务。

### 主要方法

| 方法 | 说明 |
|------|------|
| `generateDDL(Entity entity, String dbCode)` | 生成 DDL |
| `generateJavaEntity(Entity entity)` | 生成 Java 实体类 |
| `generateAllDDL(Project project, String dbCode)` | 生成所有表的 DDL |
| `previewCode(Entity entity, TemplateType type)` | 预览代码 |

### 使用示例

```dart
final service = CodegenService();

// 生成 MySQL DDL
final ddl = service.generateDDL(entity, 'MYSQL');

// 生成 Java 实体类
final javaCode = service.generateJavaEntity(entity);
```

## TemplateService

模板管理服务，加载和管理 mustache 模板。

### 模板位置

```
assets/templates/
├── ddl/
│   ├── mysql_create_table.mustache
│   ├── postgresql_create_table.mustache
│   ├── oracle_create_table.mustache
│   └── ...
└── code/
    ├── java_entity.mustache
    └── ...
```

### 模板变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{tableName}}` | 表名 | user_info |
| `{{tableComment}}` | 表注释 | 用户信息表 |
| `{{#fields}}...{{/fields}}` | 字段迭代 | - |
| `{{field.name}}` | 字段名 | user_id |
| `{{field.typeDB}}` | 数据库类型 | VARCHAR(64) |
| `{{field.pk}}` | 是否主键 | true/false |
| `{{field.notNull}}` | 是否非空 | true/false |
| `{{field.autoIncrement}}` | 是否自增 | true/false |
| `{{field.defaultValue}}` | 默认值 | CURRENT_TIMESTAMP |
| `{{field.remark}}` | 字段注释 | 用户ID |
| `{{#field.isPk}}...{{/field.isPk}}` | 主键条件渲染 | - |

### 模板示例

```sql
-- mysql_create_table.mustache
CREATE TABLE `{{tableName}}` (
{{#fields}}
  `{{name}}` {{typeDB}}{{#notNull}} NOT NULL{{/notNull}}{{#autoIncrement}} AUTO_INCREMENT{{/autoIncrement}}{{#defaultValue}} DEFAULT {{defaultValue}}{{/defaultValue}}{{#remark}} COMMENT '{{remark}}'{{/remark}},
{{/fields}}
  PRIMARY KEY ({{#primaryKeys}}{{name}}{{/primaryKeys}})
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='{{tableComment}}';
```

## CodegenProvider

代码生成状态管理。

### 状态类

```dart
class CodegenState {
  final String? generatedCode;      // 生成的代码
  final TemplateType templateType;  // 模板类型
  final String databaseCode;        // 目标数据库
  final bool isGenerating;          // 生成中状态
}
```

### 主要方法

| 方法 | 说明 |
|------|------|
| `selectDatabase(String dbCode)` | 选择目标数据库 |
| `generate(Entity entity)` | 生成代码 |
| `copyToClipboard()` | 复制到剪贴板 |

## CodegenView

代码生成视图，显示代码预览和导出选项。

### 功能

- 数据库类型选择
- 代码预览 (语法高亮)
- 复制到剪贴板
- 导出到文件

## 自定义模板

用户可以自定义模板：

1. 创建 `.mustache` 模板文件
2. 使用模板变量定义格式
3. 放置在 `assets/templates/custom/` 目录
4. 在设置中配置自定义模板路径

## 注意事项

1. **模板缓存** - 模板加载后会缓存，修改模板需重启应用
2. **类型映射** - 数据类型映射来自 DataTypeDomains 配置
3. **编码问题** - 生成的代码使用 UTF-8 编码
4. **大表生成** - 字段过多的表可能生成时间较长
5. **特殊字符** - 表名/字段名中的特殊字符需要转义