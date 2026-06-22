# PDMan 原项目参考

> **阅读时机**: 需要参考原 Electron 项目实现细节时

---

## 原项目概述

PDMan 是一款国产免费通用的数据库模型建模工具，基于 Electron + React 技术栈构建。

**原项目地址**: https://github.com/pdman/pdman

---

## 原技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Electron | 3.0.0 | 桌面框架 |
| React | 16.2.0 | UI框架 |
| @antv/g6 | 1.2.8 | 图可视化 |
| antd | 3.0.1 | UI组件库 |
| doT.js | - | 模板引擎 |

---

## 模块索引

### 基础层

| 模块 | 描述 | 文件数 | 详细文档 |
|------|------|--------|----------|
| components | UI组件库(Button/Modal/Tree等) | 22 | [components.md](components.md) |
| utils | 工具函数(json操作/代码生成/版本管理) | 9 | [utils.md](utils.md) |

### 业务层

| 模块 | 描述 | 文件数 | 详细文档 |
|------|------|--------|----------|
| table | 数据表编辑器(字段/索引/代码配置) | 8 | [table.md](table.md) |
| relation | 关系图编辑器(G6可视化) | 2 | [relation.md](relation.md) |
| database | 数据库模板管理(doT模板配置) | 3 | [database.md](database.md) |
| datatype | 数据类型管理(类型映射配置) | 2 | [datatype.md](datatype.md) |
| module | 模块管理(项目模块操作) | 2 | [module.md](module.md) |
| main-app | 主应用(Home/App/Setting) | 6 | [main-app.md](main-app.md) |

### 配置层

| 模块 | 描述 | 文件数 | 详细文档 |
|------|------|--------|----------|
| config | Webpack构建配置 | 2 | [config.md](config.md) |
| bin | 构建/启动脚本 | 2 | [bin.md](bin.md) |

---

## 核心架构参考

```
┌────────────────────────────────────────────────────────┐
│                 Electron 主进程 [main.js]              │
│  BrowserWindow创建 → IPC通信 → 窗口控制                │
└────────────────────────────────────────────────────────┘
                         ↓ IPC
┌────────────────────────────────────────────────────────┐
│                 React 渲染进程                          │
│                                                        │
│  [Loading] ──→ [Home] ──→ [App]                       │
│                           │                            │
│  ┌─────────────────────────────────────────────────┐  │
│  │  左侧树形导航(Tree组件)                           │  │
│  │  ├─ 模块 → 关系图/数据表                          │  │
│  │  └─ 数据域 → 数据类型/数据库                      │  │
│  └─────────────────────────────────────────────────┘  │
│                           │ 双击打开                   │
│  ┌─────────────────────────────────────────────────┐  │
│  │  Tab工作区                                       │  │
│  │  ├─ Relation: G6关系图可视化编辑                  │  │
│  │  └─ Table: 数据表字段/索引配置                    │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│                 数据持久层                              │
│  .pdman.json项目文件                                   │
│  ├─ modules: 模块列表(含entities数据表)               │
│  ├─ dataTypeDomains: 数据类型/数据库映射               │
│  └─ 代码生成: doT模板 → SQL/Java代码                   │
└────────────────────────────────────────────────────────┘
```

---

## 关键实现参考

### 1. 数据表编辑器

**原实现文件**: `src/app/container/table/`

**核心功能**:
- 字段表格编辑
- 索引配置
- 代码预览

**Flutter 参考**: [表编辑器文档](../features/table-editor/README.md)

---

### 2. 关系图编辑器

**原实现文件**: `src/app/container/relation/`

**核心技术**:
- @antv/g6 图引擎
- 自定义节点渲染
- 拖拽交互

**关键代码**:
```javascript
// 节点格式: 表名:序号
const node = {
  title: "User:1",
  x: 100,
  y: 200,
  moduleName: false  // 跨模块标记
};
```

**Flutter 参考**: [关系图文档](../features/relation-graph/README.md)

---

### 3. 代码生成

**原实现文件**: `src/utils/json2code.js`

**模板引擎**: doT.js

**模板变量**:
```javascript
{
  entity: { title, chnname, fields, indexes },
  datatype: [数据类型映射],
  func: { camel, underline, upperCase, lowerCase }
}
```

**Flutter 参考**: [代码生成文档](../features/codegen/README.md)

---

### 4. 数据类型系统

**原实现文件**: `src/app/container/datatype/`

**数据结构**:
```json
{
  "name": "标识号",
  "code": "IdOrKey",
  "apply": {
    "JAVA": { "type": "String" },
    "MYSQL": { "type": "VARCHAR(32)" },
    "ORACLE": { "type": "VARCHAR2(32)" }
  }
}
```

**Flutter 参考**: [数据类型文档](../features/datatype/README.md)

---

## 已知坑点汇总

1. **表名特殊字符**: 不能包含 `/`、`&`、`:`
2. **G6版本锁定**: 使用@antv/g6@1.2.8，新版API不兼容
3. **跨模块移动表**: 会删除当前模块的关联关系
4. **节点标题格式**: 必须为`表名:序号`，冒号分隔
5. **数据升级**: 老版项目文件自动增量升级
6. **IPC同步调用**: 部分操作使用sendSync同步返回
7. **模板变量**: doT模板支持camel/underline转换
8. **Tab折叠**: Tab数量超出宽度时自动折叠

---

## 详细文档索引

- [components.md](components.md) - UI组件库详细文档
- [utils.md](utils.md) - 工具函数详细文档
- [table.md](table.md) - 数据表编辑器详细文档
- [relation.md](relation.md) - 关系图编辑器详细文档
- [database.md](database.md) - 数据库模板详细文档
- [datatype.md](datatype.md) - 数据类型详细文档
- [module.md](module.md) - 模块管理详细文档
- [main-app.md](main-app.md) - 主应用详细文档
- [config.md](config.md) - 构建配置详细文档
- [bin.md](bin.md) - 脚本详细文档