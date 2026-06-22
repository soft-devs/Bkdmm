# Table - 数据表编辑器

## 概述

数据表编辑器是PDMan的核心功能模块，提供数据表字段配置、索引管理、代码预览等功能。支持多表编辑(Tab切换)，数据实时保存到项目文件。

## 文件结构

```
table/
├── index.js          # 主组件DataTable
├── Table.js          # 表格渲染组件
├── TableRow.js       # 表格行组件
├── TableCell.js      # 表格单元格组件
├── TableUtils.js     # 工具函数(增删改查)
├── TableDataCode.js  # 代码预览组件
├── TableIndexConfig.js # 索引配置组件
├── TableSummary.js   # 表摘要组件
└── ImportFields.js   # 字段导入组件
```

## 核心组件API

### DataTable (index.js)

主容器组件，管理数据表编辑状态。

**Props**:
| 属性 | 类型 | 说明 |
|------|------|------|
| value | string | 格式: `entity&{模块名}&{表名}` |
| dataSource | object | 项目数据源 |
| project | string | 项目名 |
| saveProjectSome | function | 保存部分数据 |
| updateTabs | function | 更新Tab标题 |
| changeDataType | string | 数据变更类型 |

**State**:
| 状态 | 类型 | 说明 |
|------|------|------|
| dataTable | object | 当前数据表数据 |
| tabShow | string | 当前Tab(summary/fields/indexes/code) |
| module | string | 所属模块名 |
| table | string | 数据表名 |

**实例方法**:
```javascript
// 保存数据表(返回Promise)
promiseSave(callback);

// 保存数据表(回调)
save(callback);
```

### TableUtils 工具函数

```javascript
import * as Utils from './TableUtils';

// 新增数据表
Utils.addTable(moduleName, dataSource, (newDataSource) => {});

// 删除数据表
Utils.deleteTable(moduleName, tableName, dataSource, (newDataSource) => {});

// 重命名数据表
Utils.renameTable(moduleName, oldTableName, dataSource, (newDataSource, dataHistory) => {});

// 复制数据表(到剪贴板)
Utils.copyTable(moduleName, tableName, dataSource);

// 剪切数据表
Utils.cutTable(moduleName, tableName, dataSource);

// 粘贴数据表
Utils.pasteTable(moduleName, dataSource, (newDataSource) => {});
```

## 数据模型

### 数据表实体结构

```json
{
  "title": "User",
  "chnname": "用户表",
  "nameTemplate": "{code}[{name}]",
  "fields": [
    {
      "name": "ID",
      "type": "IdOrKey",
      "chnname": "主键",
      "remark": "用户ID",
      "pk": true,
      "notNull": true,
      "autoIncrement": false
    }
  ],
  "indexes": [
    {
      "name": "IDX_USER_NAME",
      "fields": ["USERNAME"],
      "type": "NORMAL"  // NORMAL/UNIQUE/FULLTEXT
    }
  ]
}
```

### 字段属性

| 属性 | 类型 | 说明 |
|------|------|------|
| name | string | 字段代码 |
| type | string | 数据类型(引用数据类型定义) |
| chnname | string | 字段中文名 |
| remark | string | 备注 |
| pk | boolean | 是否主键 |
| notNull | boolean | 是否非空 |
| autoIncrement | boolean | 是否自增 |
| defaultValue | string | 默认值 |
| relation | object | 关联关系 |

## Tab功能

### 摘要(Summary)

显示数据表基本信息：
- 表名/中文名
- 字段数量
- 索引数量

### 字段(Fields)

表格形式编辑字段列表：
- 拖拽排序
- 批量导入
- 类型选择(下拉)
- 主键/非空/自增勾选

### 索引(Indexes)

管理数据表索引：
- 索引名称
- 索引字段(多选)
- 索引类型(NORMAL/UNIQUE/FULLTEXT)

### 代码(Code)

预览生成的代码：
- 选择数据库类型
- 实时预览SQL/Java代码
- 复制代码

## 关键流程

### 保存流程

```
用户编辑 → promiseSave() → 数据校验
    ↓
校验表名唯一性
    ↓
校验字段合法性(无特殊字符)
    ↓
saveProjectSome() → 更新dataSource
    ↓
如果表名变更 → updateTabs() 更新Tab标题
```

### 新增数据表流程

```
右键菜单"新增数据表" → TableUtils.addTable()
    ↓
弹窗输入表名
    ↓
校验表名(唯一性/特殊字符)
    ↓
获取默认字段(defaultFields)
    ↓
追加到module.entities
    ↓
回调保存项目
```

## 已知坑点

1. **表名特殊字符**: 不能包含 `/`、`&`、`:` 三种字符
2. **字段名特殊字符**: 同上限制
3. **保存时校验**: 先校验表名唯一性，再校验字段
4. **剪贴板操作**: 使用Electron的clipboard模块
5. **数据更新机制**: changeDataType='reset'时全量更新
6. **Tab组件引用**: 通过ref存储tableInstance

## 详细文档

- [api-table-utils.md](api-table-utils.md) - 工具函数详细API
- [data-model.md](data-model.md) - 数据模型详细说明
- [pitfalls.md](pitfalls.md) - 坑点陷阱