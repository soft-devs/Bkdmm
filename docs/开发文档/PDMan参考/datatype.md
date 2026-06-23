# DataType - 数据类型管理

## 概述

数据类型管理模块，定义项目中的标准数据类型及其在不同数据库中的映射关系。支持自定义数据类型，统一管理跨数据库的类型转换。

## 文件结构

```
datatype/
├── index.js          # 数据类型配置组件
├── DataTypeUtils.js  # 工具函数(增删改查)
└── style/            # 样式文件
```

## 核心组件API

### DataTypeUtils 工具函数

```javascript
import { DataTypeUtils } from './datatype';

// 新增数据类型
DataTypeUtils.addDataType(dataSource, (newDataSource) => {});

// 重命名数据类型
DataTypeUtils.renameDataType(dataTypeCode, dataSource, (newDataSource) => {});

// 删除数据类型
DataTypeUtils.deleteDataType(dataTypeCode, dataSource, (newDataSource) => {});

// 复制数据类型
DataTypeUtils.copyDataType(dataTypeCode, dataSource);

// 剪切数据类型
DataTypeUtils.cutDataType(dataTypeCode, dataSource);

// 粘贴数据类型
DataTypeUtils.pasteDataType(dataSource, (newDataSource) => {});
```

## 数据模型

### 数据类型定义结构

```json
{
  "name": "标识号",
  "code": "IdOrKey",
  "apply": {
    "JAVA": {
      "type": "String"
    },
    "MYSQL": {
      "type": "VARCHAR(32)"
    },
    "ORACLE": {
      "type": "VARCHAR2(32)"
    },
    "SQLServer": {
      "type": "NVARCHAR(32)"
    },
    "PostgreSQL": {
      "type": "VARCHAR(32)"
    }
  }
}
```

### 属性说明

| 属性 | 类型 | 说明 |
|------|------|------|
| name | string | 数据类型名称(中文) |
| code | string | 数据类型代码(唯一标识) |
| apply | object | 各数据库/语言的类型映射 |

### apply结构

```json
{
  "数据库代码": {
    "type": "数据库类型"
  }
}
```

## 默认数据类型

系统预置以下数据类型(见defaultData.json):

| code | name | MySQL类型 | Java类型 |
|------|------|-----------|----------|
| DefaultString | 默认字串 | VARCHAR(32) | String |
| IdOrKey | 标识号 | VARCHAR(32) | String |
| LongKey | 标识号-长 | VARCHAR(64) | String |
| Integer | 整数 | INT | Integer |
| Long | 长整数 | BIGINT | Long |
| Double | 双精度浮点数 | DOUBLE | Double |
| DateTime | 日期时间 | DATETIME | Date |
| Boolean | 布尔值 | TINYINT | Boolean |
| Text | 长文本 | TEXT | String |

## 关键流程

### 类型映射查询

```
字段类型(code) → datatype数组查找
    ↓
获取apply对象
    ↓
根据database code获取对应type
```

### 新增数据类型流程

```
点击"新增数据类型" → DataTypeUtils.addDataType()
    ↓
输入name和code
    ↓
配置各数据库映射
    ↓
校验code唯一性
    ↓
保存到dataTypeDomains.datatype
```

## 已知坑点

1. **code唯一性**: code必须唯一，重名会自动追加"-副本"
2. **apply完整性**: 需为所有数据库配置映射
3. **类型引用**: 表字段type引用的是code而非name
4. **删除影响**: 删除数据类型后引用该类型的字段无法生成代码
5. **数据域排序**: datatype数组支持拖拽排序

## 详细文档

- [api-datatype-utils.md](api-datatype-utils.md) - 工具函数详细API
- [default-datatypes.md](default-datatypes.md) - 默认数据类型列表
- [data-model.md](data-model.md) - 数据模型详细说明