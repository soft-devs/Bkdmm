# Module - 模块管理

## 概述

模块管理模块，管理项目中的业务模块。每个模块包含数据表实体(entities)和关系图(graphCanvas)，是项目数据的一级组织单元。

## 文件结构

```
module/
├── index.js       # 模块树组件
├── ModuleUtils.js # 工具函数(增删改查)
└── style/         # 样式文件
```

## 核心组件API

### ModuleUtils 工具函数

```javascript
import { Utils } from './module';

// 新增模块
Utils.addModule(dataSource, (newDataSource) => {});

// 重命名模块
Utils.renameModule(moduleName, dataSource, (newDataSource, newModuleName) => {});

// 删除模块
Utils.deleteModule(moduleName, dataSource, (newDataSource) => {});

// 复制模块
Utils.copyModule(moduleName, dataSource);

// 剪切模块
Utils.cutModule(moduleName, dataSource);

// 粘贴模块
Utils.pasteModule(dataSource, (newDataSource) => {});
```

## 数据模型

### 模块结构

```json
{
  "name": "用户管理",
  "chnname": "用户管理模块",
  "entities": [
    { "title": "User", "chnname": "用户", "fields": [], "indexes": [] },
    { "title": "Role", "chnname": "角色", "fields": [], "indexes": [] }
  ],
  "graphCanvas": {
    "nodes": [
      { "title": "User:1", "x": 100, "y": 200, "moduleName": false }
    ],
    "edges": []
  }
}
```

### 属性说明

| 属性 | 类型 | 说明 |
|------|------|------|
| name | string | 模块代码(唯一标识) |
| chnname | string | 模块中文名 |
| entities | array | 数据表列表 |
| graphCanvas | object | 关系图数据 |

## 关键流程

### 新增模块流程

```
点击空白处/右键菜单"新增模块" → ModuleUtils.addModule()
    ↓
弹窗输入模块名
    ↓
校验名称唯一性
    ↓
追加到dataSource.modules
```

### 删除模块流程

```
右键菜单"删除模块" → 确认弹窗
    ↓
ModuleUtils.deleteModule()
    ↓
从modules数组移除
    ↓
关闭该模块下所有Tab
```

### 重命名模块级联更新

```
重命名模块 → 更新modules数组
    ↓
更新所有Tab标题(含模块名)
    ↓
更新Tab的key/value
```

## 模块排序

支持拖拽排序，通过moveArrayPosition实现：

```javascript
// 拖拽排序
onDrop={(drop, drag) => {
  const dragIndex = modules.findIndex(m => m.name === dragModule);
  const dropIndex = modules.findIndex(m => m.name === dropModule);
  saveProject({
    ...dataSource,
    modules: moveArrayPosition(modules, dragIndex, dropIndex)
  });
}}
```

## 已知坑点

1. **模块名唯一性**: 重名会自动追加"-副本"
2. **删除级联**: 删除模块会删除其下所有数据表和关系图
3. **Tab管理**: 删除模块需手动关闭相关Tab
4. **跨模块移动表**: 移动表到其他模块需更新graphCanvas
5. **关系图节点**: 跨模块的节点moduleName设为目标模块名

## 详细文档

- [api-module-utils.md](api-module-utils.md) - 工具函数详细API
- [data-model.md](data-model.md) - 数据模型详细说明