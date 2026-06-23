# Relation - 关系图编辑器

## 概述

关系图编辑器基于@antv/g6图可视化引擎，提供数据表关系可视化编辑功能。支持拖拽布局、关系线绘制、缩放导航、图片导出等。

## 文件结构

```
relation/
├── index.js        # 主组件Relation
├── RelationEdit.js # 关系编辑弹窗
└── style/          # 样式文件
```

## 核心组件API

### Relation (index.js)

主容器组件，管理关系图渲染和交互。

**Props**:
| 属性 | 类型 | 说明 |
|------|------|------|
| id | string | 组件唯一标识 |
| value | string | 格式: `map&{模块名}/关系图` |
| dataSource | object | 项目数据源 |
| height | number | 图高度 |
| width | number | 图宽度 |
| modeChange | function | 模式切换回调 |

**State**:
| 状态 | 类型 | 说明 |
|------|------|------|
| empty | boolean | 是否空关系图 |
| contextDisplay | string | 右键菜单显示状态 |
| contextMenus | array | 右键菜单项 |
| count | number | 计数器(节点编号) |

**实例方法**:
```javascript
// 缩放操作
onZoom('add');     // 放大
onZoom('sub');     // 缩小
onZoom('normal');  // 原始大小

// 搜索节点
searchNodes(keyword);

// 导出图片
exportImg(filePath, type, callback);

// 获取节点数据
getNodes();

// 设置节点数据
setNodes(nodes);

// 保存数据
saveData(callback);

// 撤销/重做
undo();
redo();

// 切换模式
changeMode('drag' | 'edit');
```

### G6配置

```javascript
// 图实例配置
const net = new G6.Net({
  id: `paint-${value}`,
  height: height,
  width: width,
  modes: {
    default: ['drag', 'zoom', 'dragNode'],
    edit: ['edit']
  },
  layout: null  // 手动布局
});
```

## 数据模型

### 关系图数据结构

```json
{
  "graphCanvas": {
    "nodes": [
      {
        "title": "User:1",  // 格式: 表名:序号
        "x": 100,
        "y": 200,
        "moduleName": false  // 跨模块标记
      }
    ],
    "edges": [
      {
        "source": "User:1",
        "target": "Order:1",
        "label": "用户订单"
      }
    ]
  }
}
```

### 节点属性

| 属性 | 类型 | 说明 |
|------|------|------|
| title | string | 节点标题(表名:序号) |
| x | number | X坐标 |
| y | number | Y坐标 |
| moduleName | string/boolean | 所属模块名(跨模块为false) |

### 边属性

| 属性 | 类型 | 说明 |
|------|------|------|
| source | string | 源节点 |
| target | string | 目标节点 |
| label | string | 关系标签 |

## 关键流程

### 初始化流程

```
组件挂载 → _getData(dataSource)
    ↓
提取模块nodes/edges数据
    ↓
_checkEmpty() 检查空状态
    ↓
_renderRelation() 创建G6实例
    ↓
渲染节点和边
```

### 数据变更处理

```
dataSource变化 → 判断changeDataType
    ↓
reset: 全量重置graphCanvas
    ↓
增量更新: 获取net.save()当前状态
    ↓
_updateNodes() 合并新数据
    ↓
_clearInvalidData() 清理无效节点
    ↓
net.changeData() 重新渲染
```

### 跨模块移动表

```
拖拽节点 → onDrop → 判断跨模块
    ↓
更新graphCanvas.nodes的moduleName
    ↓
更新所有Relation实例的节点
    ↓
saveProject() 保存数据
```

## 交互功能

### 右键菜单

| 操作 | 说明 |
|------|------|
| 删除节点 | 删除选中节点及关联边 |
| 编辑关系 | 打开RelationEdit弹窗 |
| 新增关系 | 添加新的连接线 |

### 模式切换

| 模式 | 功能 |
|------|------|
| drag | 拖拽画布/节点 |
| edit | 编辑关系线 |

### 导出图片

支持格式:
- JPG
- PNG

## 已知坑点

1. **节点标题格式**: 必须为`表名:序号`，冒号分隔
2. **G6版本锁定**: 使用@antv/g6@1.2.8，新版API不兼容
3. **节点更新**: 需手动调用net.changeData()
4. **跨模块节点**: moduleName设为false表示不属于当前模块
5. **无效数据清理**: 删除表后需清理对应节点和边
6. **关系图Tab**: value格式为`map&{模块}/关系图`
7. **缩放限制**: scale范围0-9.8
8. **实例管理**: 通过relationInstance[key]存储多Tab实例

## 详细文档

- [api-relation.md](api-relation.md) - 关系图详细API
- [data-model.md](data-model.md) - 数据模型详细说明
- [pitfalls.md](pitfalls.md) - 坑点陷阱