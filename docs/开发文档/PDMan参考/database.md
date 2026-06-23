# Database - 数据库模板管理

## 概述

数据库模板管理模块，配置不同数据库的代码生成模板。支持MySQL、Oracle、SQLServer、PostgreSQL等主流数据库，使用doT模板引擎生成DDL/DML脚本。

## 文件结构

```
database/
├── index.js           # 数据库配置组件
├── DatabaseUtils.js   # 工具函数(增删改查)
├── TemplateHelp.js    # 模板帮助文档
└── TemplatePreviewEdit.js # 模板编辑器
```

## 核心组件API

### DatabaseUtils 工具函数

```javascript
import { Utils } from './database';

// 新增数据库
Utils.addDatabase(dataSource, (newDataSource) => {});

// 重命名数据库
Utils.renameDatabase(databaseCode, dataSource, (newDataSource) => {});

// 删除数据库
Utils.deleteDatabase(databaseCode, dataSource, (newDataSource) => {});

// 复制数据库配置
Utils.copyDatabase(databaseCode, dataSource);

// 剪切数据库配置
Utils.cutDatabase(databaseCode, dataSource);

// 粘贴数据库配置
Utils.pasteDatabase(dataSource, (newDataSource) => {});
```

## 数据模型

### 数据库配置结构

```json
{
  "code": "MYSQL",
  "name": "MySQL数据库",
  "defaultDatabase": true,
  "template": {
    "createTable": "CREATE TABLE {{=it.entity.title}} (...)",
    "createIndex": "CREATE INDEX ...",
    "dropTable": "DROP TABLE ...",
    "comment": "COMMENT ON TABLE ..."
  }
}
```

### 模板类型

| 模板 | 说明 |
|------|------|
| createTable | 建表语句 |
| createIndex | 建索引语句 |
| dropTable | 删表语句 |
| comment | 注释语句 |
| query | 查询语句 |

## 模板语法

使用doT模板引擎，支持以下变量：

```javascript
// 实体信息
{{=it.entity.title}}      // 表代码
{{=it.entity.chnname}}    // 表中文名
{{=it.entity.fields}}     // 字段数组

// 字段遍历
{{~it.entity.fields:field}}
  {{=field.name}}         // 字段名
  {{=field.type}}         // 字段类型
  {{=field.chnname}}      // 字段中文名
{{~}}

// 数据类型映射
{{=it.datatype[field.type]}}  // 数据库类型

// 内置函数
camel(str)      // 驼峰转换
underline(str)  // 下划线转换
upperCase(str)  // 大写
lowerCase(str)  // 小写
```

## 关键流程

### 新增数据库流程

```
点击"新增数据库" → DatabaseUtils.addDatabase()
    ↓
打开Database配置弹窗
    ↓
填写code/name/template
    ↓
校验code唯一性
    ↓
设置defaultDatabase(首个默认)
    ↓
保存到dataTypeDomains.database
```

### 默认数据库机制

```javascript
// 确保至少有一个默认数据库
const checkDatabase = (database = []) => {
  if (!database.some(db => db.defaultDatabase)) {
    return database.map((db, index) => ({
      ...db,
      defaultDatabase: index === 0
    }));
  }
  return database;
};
```

### 重命名级联更新

```javascript
// 重命名数据库时，更新所有数据类型的apply映射
const updateDatatype = (datatype, oldCode, newCode) => {
  return datatype.map(type => {
    const typeApply = type.apply || {};
    if (oldCode in typeApply) {
      typeApply[newCode] = {...typeApply[oldCode]};
      delete typeApply[oldCode];
    }
    return { ...type, apply: typeApply };
  });
};
```

## 已知坑点

1. **默认数据库**: 删除默认数据库后自动设置首个为默认
2. **重命名影响**: 重命名数据库会更新所有数据类型的apply映射
3. **模板验证**: 保存前不验证模板语法，运行时可能报错
4. **复制到剪贴板**: 使用Electron的clipboard模块

## 详细文档

- [api-database-utils.md](api-database-utils.md) - 工具函数详细API
- [template-syntax.md](template-syntax.md) - 模板语法详细说明
- [data-model.md](data-model.md) - 数据模型详细说明