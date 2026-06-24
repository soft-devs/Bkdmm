# features/modeling - 数据建模核心

实体编辑器、ER图编辑器和流程图编辑器，核心建模功能。

## 概述

该模块是 Bkdmm 的核心功能，提供数据表设计、ER图可视化和关系编辑。

## 子模块

| 子模块 | 说明 | 文件数 |
|------|------|--------|
| entity_editor | 实体编辑器 (表字段编辑) | 6 |
| er_diagram | ER图编辑器 | 4 |
| flowchart | 流程图编辑器 (扩展示例) | 4 |

## 文件结构

```
features/modeling/
├── entity_editor/
│   ├── entity_editor.dart     # 模块导出
│   ├── providers/
│   │   └── entity_provider.dart  # 实体状态管理
│   ├── views/
│   │   └── entity_editor_view.dart # 实体编辑视图
│   └── widgets/
│       ├── field_table.dart   # 字段表格
│       ├── code_preview.dart  # 代码预览
│       └── index_editor.dart  # 索引编辑器
├── er_diagram/
│   ├── er_diagram.dart        # 模块导出
│   ├── models/
│   │   └── er_diagram_models.dart  # ER图模型
│   ├── providers/
│   │   └── er_diagram_provider.dart # ER图状态管理
│   ├── renderers/
│   │   └── er_renderers.dart  # ER图渲染器
│   └── widgets/
│       └── er_diagram_canvas.dart  # ER图画布
└── flowchart/
│   ├── flowchart.dart         # 模块导出
│   ├── models/
│   │   └── flowchart_models.dart   # 流程图模型
│   ├── renderers/
│   │   └── flowchart_renderers.dart # 流程图渲染器
│   └── widgets/
│       └── flowchart_canvas.dart   # 流程图画布
```

## EntityEditor

实体编辑器，用于编辑数据表的字段和索引。

### EntityEditorView

实体编辑主视图。

#### 布局

```
┌─────────────────────────────────────────────────────────────┐
│ Header (表名 + 中文名 + 工具栏)                               │
├─────────────────────────────────────┬───────────────────────┤
│                                     │                       │
│         Field Table (Syncfusion)    │   Code Preview        │
│                                     │   (DDL/Java)          │
│  - 字段名  - 类型  - 中文名  - 属性   │                       │
│                                     │                       │
├─────────────────────────────────────┴───────────────────────┤
│ Index Editor (索引列表)                                      │
└─────────────────────────────────────────────────────────────┘
```

#### 功能

- **字段编辑** - 添加、删除、修改字段
- **索引编辑** - 添加、删除、修改索引
- **代码预览** - 实时生成 DDL 和 Java 代码
- **数据类型选择** - 从预定义类型列表选择

### FieldTable

字段表格组件，使用 Syncfusion DataGrid。

#### 字段属性

| 属性 | 说明 |
|------|------|
| name | 字段名 |
| type | 数据类型 |
| chnname | 中文名 |
| pk | 主键 |
| notNull | 非空 |
| autoIncrement | 自增 |
| defaultValue | 默认值 |
| remark | 备注 |

### EntityProvider

实体状态管理。

#### 主要方法

| 方法 | 说明 |
|------|------|
| `addField(Field field)` | 添加字段 |
| `updateField(String id, Field field)` | 更新字段 |
| `removeField(String id)` | 删除字段 |
| `addIndex(Index index)` | 添加索引 |
| `updateIndex(String id, Index index)` | 更新索引 |
| `removeIndex(String id)` | 删除索引 |

## ERDiagram

ER图编辑器，可视化展示表关系。

### ERDiagramCanvas

ER图画布组件，基于 diagram_editor 框架。

#### 功能

- **节点显示** - 表节点，显示表名和字段列表
- **连线显示** - 表间关系连线，带箭头和标签
- **缩放平移** - 鼠标滚轮缩放，拖拽平移
- **节点拖拽** - 拖拽调整节点位置
- **双击编辑** - 双击节点打开实体编辑器
- **右键菜单** - 添加实体、编辑、删除

#### 交互

| 操作 | 功能 |
|------|------|
| 单击节点 | 选择节点 |
| 双击节点 | 打开实体编辑对话框 |
| 右键节点 | 编辑/删除菜单 |
| 右键空白 | 添加实体菜单 |
| 拖拽节点 | 移动节点位置 |
| 滚轮 | 缩放画布 |
| 拖拽空白 | 平移画布 |

### ERNodeRenderer

ER图节点渲染器。

#### 渲染内容

- 表头背景色 (主题色)
- 表名 (英文 + 中文)
- 字段列表
- 主键图标 (🔑)
- 索引图标

### EREdgeRenderer

ER图连线渲染器。

#### 渲染内容

- 连线 (曲线/直线)
- 箭头 (表示关系方向)
- 关系标签 (1:1, 1:N, N:M)

## Flowchart

流程图编辑器 (扩展示例)。

### 功能

- 节点类型：开始、结束、流程、判断
- 连线类型：直线、带箭头
- 基本交互：拖拽、选择

## 注意事项

1. **Syncfusion DataGrid** - 需要正确配置列定义和行数据
2. **代码预览** - 使用 codegen 模块生成，需传递当前 Entity
3. **ER图布局** - 使用 graphview 进行自动布局
4. **状态同步** - 编辑后需同步更新 projectProvider
5. **性能优化** - 大量节点时需优化渲染性能