# 图编辑器 V2 重构工作流

全面重构 Bkdmm 图编辑器，基于 LogicFlow 架构思想。

---

## 项目概览

| 项目 | 说明 |
|------|------|
| **目标** | 将 V1 图编辑器重构为 Model-View 分离架构 |
| **架构参考** | LogicFlow (ts) → Flutter 适配 |
| **预估周期** | 10-15 天 |
| **核心改进** | 手动 TransformModel、EventCenter、Model-View 分离 |

---

## 阶段规划

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              重构工作流                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ Phase 1  │──►│ Phase 2  │──►│ Phase 3  │──►│ Phase 4  │──►│ Phase 5  │  │
│  │ 核心框架  │   │ 渲染层   │   │ 交互行为  │   │ ER迁移   │   │ 清理扩展  │  │
│  │ 2-3 天   │   │ 2-3 天   │   │ 2-3 天   │   │ 2-3 天   │   │ 1-2 天   │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
│       │              │              │              │              │         │
│       ▼              ▼              ▼              ▼              ▼         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ 单元测试  │   │ 单元测试  │   │ 集成测试  │   │ 功能验证  │   │ 全量测试  │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: 核心框架 (2-3 天)

### 目标
建立 Model-View 分离的基础架构，实现核心数据模型和事件系统。

### 输出文件

```
lib/shared/diagram_editor/
├── src/
│   ├── diagram_editor.dart          # 主入口
│   │
│   ├── model/
│   │   ├── graph_model.dart         # 图数据模型
│   │   ├── node_model.dart          # 节点模型基类
│   │   ├── edge_model.dart          # 边模型基类
│   │   ├── transform_model.dart     # 视口变换模型
│   │   └── edit_config_model.dart   # 编辑配置
│   │
│   ├── event/
│   │   ├── event_center.dart        # 事件中心
│   │   └── event_types.dart         # 事件类型常量
│   │
│   └── util/
│       └── coordinate_utils.dart    # 坐标转换工具
│
└── diagram_editor.dart              # 导出文件
```

### 任务清单

#### Day 1: 数据模型基础

- [ ] 创建 `GraphModel` 类
  - [ ] nodes/edges 列表管理
  - [ ] addNode/addEdge 方法
  - [ ] removeNode/removeEdge 方法
  - [ ] ChangeNotifier 集成

- [ ] 创建 `NodeModel` 基类
  - [ ] id, type, x, y 属性
  - [ ] width, height 属性
  - [ ] isSelected, isHovered 状态
  - [ ] anchors 列表

- [ ] 创建 `EdgeModel` 基类
  - [ ] sourceNodeId, targetNodeId
  - [ ] sourceAnchorId, targetAnchorId
  - [ ] 路径点列表

#### Day 2: 视口变换 + 事件系统

- [ ] 创建 `TransformModel`
  - [ ] scaleX, scaleY, translateX, translateY
  - [ ] zoom(delta, focalPoint) 方法
  - [ ] pan(delta) 方法
  - [ ] toCanvasPoint(screenPoint) 坐标转换
  - [ ] toScreenPoint(canvasPoint) 坐标转换

- [ ] 创建 `EventCenter`
  - [ ] on(event, callback) 监听
  - [ ] once(event, callback) 单次监听
  - [ ] emit(event, args) 触发
  - [ ] off(event, callback) 取消监听
  - [ ] 通配符 '*' 支持

- [ ] 定义 `EventTypes` 常量
  - [ ] 节点事件: node:add, node:delete, node:click, node:drag
  - [ ] 边事件: edge:add, edge:delete, edge:click
  - [ ] 画布事件: canvas:click, canvas:zoom, canvas:pan
  - [ ] 连线事件: connection:start, connection:complete

#### Day 3: 集成测试

- [ ] GraphModel 单元测试
  - [ ] addNode/removeNode 测试
  - [ ] addEdge/removeEdge 测试
  - [ ] 坐标转换测试

- [ ] TransformModel 单元测试
  - [ ] zoom 测试
  - [ ] pan 测试
  - [ ] 边界条件测试

- [ ] EventCenter 单元测试
  - [ ] on/emit 测试
  - [ ] once 测试
  - [ ] off 测试
  - [ ] 通配符测试

### 验收标准

- [x] 所有单元测试通过
- [x] flutter analyze 无错误
- [x] GraphModel 可独立使用
- [x] EventCenter 事件分发正常

---

## Phase 2: 渲染层 (2-3 天)

### 目标
实现分层渲染架构，使用 CustomPaint 替代 InteractiveViewer。

### 输出文件

```
lib/shared/diagram_editor/
├── src/
│   ├── view/
│   │   ├── graph_view.dart          # 主视图
│   │   ├── canvas_overlay.dart      # 画布层
│   │   ├── modification_overlay.dart # 交互层
│   │   ├── tool_overlay.dart        # 工具层
│   │   │
│   │   ├── painter/
│   │   │   ├── node_painter.dart    # 节点绘制
│   │   │   ├── edge_painter.dart    # 边绘制
│   │   │   └── grid_painter.dart    # 网格绘制
│   │   │
│   │   └── widget/
│   │       ├── base_node_widget.dart
│   │       └── base_edge_widget.dart
```

### 任务清单

#### Day 1: 主视图框架

- [ ] 创建 `GraphView` 主视图
  - [ ] Stack 分层结构
  - [ ] 监听 GraphModel 变化
  - [ ] 应用 TransformModel 变换

- [ ] 创建 `CanvasOverlay` 画布层
  - [ ] CustomPaint 渲染节点和边
  - [ ] 应用 transform 矩阵

- [ ] 创建 `GridOverlay` 网格层
  - [ ] 网格线绘制
  - [ ] 跟随 transform 缩放

#### Day 2: 节点/边渲染

- [ ] 创建 `NodePainter`
  - [ ] 绘制节点矩形
  - [ ] 绘制节点文本
  - [ ] 绘制选中状态

- [ ] 创建 `EdgePainter`
  - [ ] 绘制直线边
  - [ ] 绘制折线边
  - [ ] 绘制箭头

- [ ] 创建 `BaseNodeWidget`
  - [ ] 可选的 Widget 渲染方式
  - [ ] 支持自定义 Widget

#### Day 3: 交互层 + 工具层

- [ ] 创建 `ModificationOverlay`
  - [ ] 框选矩形渲染
  - [ ] 连线预览渲染
  - [ ] 选中轮廓渲染

- [ ] 创建 `ToolOverlay`
  - [ ] 缩放控制按钮
  - [ ] 位置信息显示
  - [ ] 工具栏按钮

### 验收标准

- [x] 节点正常渲染
- [x] 边正常渲染
- [x] 网格跟随缩放
- [x] 无 InteractiveViewer 依赖

---

## Phase 3: 交互行为 (2-3 天)

### 目标
实现用户交互处理：拖拽、框选、连线、缩放平移。

### 输出文件

```
lib/shared/diagram_editor/
├── src/
│   ├── behavior/
│   │   ├── behavior.dart            # Behavior 基类
│   │   ├── behavior_registry.dart   # Behavior 注册表
│   │   │
│   │   ├── node_drag_behavior.dart  # 节点拖拽
│   │   ├── selection_behavior.dart  # 框选
│   │   ├── connection_behavior.dart  # 连线
│   │   ├── pan_zoom_behavior.dart   # 平移缩放
│   │   └── hover_behavior.dart      # 悬停
│   │
│   └── handler/
│       └── pointer_handler.dart     # 指针事件处理
```

### 任务清单

#### Day 1: 事件入口 + Behavior 基础

- [ ] 创建 `PointerHandler`
  - [ ] Listener 事件入口
  - [ ] 坐标转换
  - [ ] 命中测试
  - [ ] 分发到 Behavior

- [ ] 创建 `Behavior` 基类
  - [ ] priority 优先级
  - [ ] canHandle(event) 判断
  - [ ] handle(event) 处理
  - [ ] reset() 重置

- [ ] 创建 `BehaviorRegistry`
  - [ ] 按优先级排序
  - [ ] 事件分发逻辑

#### Day 2: 核心交互实现

- [ ] 创建 `NodeDragBehavior`
  - [ ] 判断点击是否在节点上
  - [ ] 拖拽更新节点位置
  - [ ] 触发 node:drag 事件
  - [ ] 支持多选拖拽

- [ ] 创建 `SelectionBehavior`
  - [ ] 判断点击是否在空白区域
  - [ ] 绘制框选矩形
  - [ ] 计算框选范围内的元素
  - [ ] 触发 selection:change 事件

- [ ] 创建 `PanZoomBehavior`
  - [ ] 滚轮缩放
  - [ ] 双指缩放
  - [ ] 右键/中键拖拽平移
  - [ ] 触发 transform:change 事件

#### Day 3: 连线交互

- [ ] 创建 `ConnectionBehavior`
  - [ ] 锚点点击开始连线
  - [ ] 鼠标移动更新预览线
  - [ ] 释放判断目标锚点
  - [ ] 创建 EdgeModel
  - [ ] 触发 connection:complete 事件

- [ ] 实现 `HoverBehavior`
  - [ ] 鼠标进入/离开节点
  - [ ] 显示/隐藏锚点
  - [ ] 触发 node:hover 事件

### 验收标准

- [x] 节点可拖拽
- [x] 框选功能正常
- [x] 滚轮缩放功能正常
- [x] 锚点连线功能正常
- [x] 事件正确触发

---

## Phase 4: ER 图迁移 (2-3 天)

### 目标
将现有 ER 图功能迁移到新架构，确保功能完整。

### 任务清单

#### Day 1: ER 节点/边模型

- [ ] 创建 `ERTableNodeModel`
  - [ ] 继承 NodeModel
  - [ ] tableName 属性
  - [ ] fields 列表
  - [ ] 重写 getAnchors()

- [ ] 创建 `ERRelationEdgeModel`
  - [ ] 继承 EdgeModel
  - [ ] relationType 属性 (1:1, 1:N, N:M)
  - [ ] 自定义路径计算

- [ ] 注册 ER 类型
  - [ ] diagramEditor.registerNode('er-table', ...)
  - [ ] diagramEditor.registerEdge('er-relation', ...)

#### Day 2: ER 渲染迁移

- [ ] 创建 `ERTablePainter`
  - [ ] 绘制表头
  - [ ] 绘制字段列表
  - [ ] 绘制主键/外键标记
  - [ ] 绘制锚点

- [ ] 创建 `ERRelationPainter`
  - [ ] 绘制关系线
  - [ ] 绘制基数标记 (1, N, M)

- [ ] 迁移 ER 特有交互
  - [ ] 字段点击
  - [ ] 表名双击编辑

#### Day 3: 功能验证

- [ ] 对照 V1 功能清单验证
  - [ ] 表创建/删除
  - [ ] 表拖拽
  - [ ] 关系创建
  - [ ] 关系删除
  - [ ] 框选多表
  - [ ] 缩放/平移
  - [ ] 字段显示
  - [ ] 锚点显示/隐藏

- [ ] 性能测试
  - [ ] 50+ 节点渲染测试
  - [ ] 拖拽流畅度测试

### 验收标准

- [x] V1 所有功能正常
- [x] 无性能回退
- [x] 代码量减少 50%+

---

## Phase 5: 清理和扩展 (1-2 天)

### 目标
清理旧代码，添加历史记录，文档完善。

### 任务清单

#### Day 1: 历史记录 + 代码清理

- [ ] 实现 `HistoryController`
  - [ ] 监听 graph:updated 事件
  - [ ] 保存快照
  - [ ] undo() / redo() 方法
  - [ ] Ctrl+Z / Ctrl+Y 快捷键

- [ ] 清理旧代码
  - [ ] 删除 V1 画布文件
  - [ ] 更新导入路径
  - [ ] 删除无用依赖

#### Day 2: 文档 + 扩展点

- [ ] 更新文档
  - [ ] API 文档
  - [ ] 使用示例
  - [ ] 迁移指南

- [ ] 扩展点验证
  - [ ] 自定义节点类型测试
  - [ ] 自定义边类型测试
  - [ ] 插件机制测试

### 验收标准

- [x] undo/redo 功能正常
- [x] 旧代码已清理
- [x] 文档完整
- [x] 扩展机制可用

---

## 技术要点

### 1. 坐标转换

```dart
// 屏幕坐标 → 画布坐标
Offset toCanvasPoint(Offset screen) {
  return Offset(
    (screen.dx - translateX) / scaleX,
    (screen.dy - translateY) / scaleY,
  );
}

// 画布坐标 → 屏幕坐标
Offset toScreenPoint(Offset canvas) {
  return Offset(
    canvas.dx * scaleX + translateX,
    canvas.dy * scaleY + translateY,
  );
}
```

### 2. 事件分发

```dart
void handlePointerDown(PointerDownEvent event) {
  final canvasPoint = graphModel.toCanvasPoint(event.localPosition);
  final hitResult = graphModel.hitTest(canvasPoint);

  if (hitResult.isOnAnchor) {
    eventCenter.emit(EventTypes.anchorClick, AnchorEventArgs(...));
  } else if (hitResult.isOnNode) {
    eventCenter.emit(EventTypes.nodeClick, NodeEventArgs(...));
  } else {
    eventCenter.emit(EventTypes.canvasClick, CanvasEventArgs(...));
  }
}
```

### 3. Behavior 优先级

```dart
final behaviors = [
  ConnectionBehavior(priority: 10),   // 最高优先级
  NodeDragBehavior(priority: 20),
  SelectionBehavior(priority: 50),
  PanZoomBehavior(priority: 100),     // 最低优先级
];

behaviors.sort((a, b) => a.priority.compareTo(b.priority));
```

---

## 文件结构总览

```
lib/shared/diagram_editor/
├── diagram_editor.dart              # 导出文件
│
├── src/
│   ├── diagram_editor.dart          # 主入口类
│   │
│   ├── model/                        # 数据模型
│   │   ├── graph_model.dart
│   │   ├── node_model.dart
│   │   ├── edge_model.dart
│   │   ├── transform_model.dart
│   │   └── edit_config_model.dart
│   │
│   ├── view/                         # 渲染视图
│   │   ├── graph_view.dart
│   │   ├── canvas_overlay.dart
│   │   ├── modification_overlay.dart
│   │   └── painter/
│   │
│   ├── event/                        # 事件系统
│   │   ├── event_center.dart
│   │   └── event_types.dart
│   │
│   ├── behavior/                     # 交互行为
│   │   ├── behavior.dart
│   │   ├── node_drag_behavior.dart
│   │   ├── selection_behavior.dart
│   │   ├── connection_behavior.dart
│   │   └── pan_zoom_behavior.dart
│   │
│   ├── history/                      # 历史记录
│   │   └── history_controller.dart
│   │
│   └── util/                         # 工具类
│       └── coordinate_utils.dart
│
└── test/                             # 测试
    ├── model_test.dart
    ├── event_test.dart
    └── behavior_test.dart
```

---

## 检查点

### Phase 1 完成检查

- [ ] GraphModel 单元测试通过
- [ ] TransformModel 单元测试通过
- [ ] EventCenter 单元测试通过
- [ ] flutter analyze 无错误

### Phase 2 完成检查

- [ ] 节点渲染正常
- [ ] 边渲染正常
- [ ] 网格显示正常
- [ ] 变换应用正确

### Phase 3 完成检查

- [ ] 节点拖拽流畅
- [ ] 框选功能正常
- [ ] 连线功能正常
- [ ] 缩放平移正常

### Phase 4 完成检查

- [ ] V1 功能全部验证
- [ ] 无性能回退
- [ ] 代码审查通过

### Phase 5 完成检查

- [ ] undo/redo 功能正常
- [ ] 旧代码已删除
- [ ] 文档已更新
- [ ] 发布准备就绪

---

*最后更新: 2025-06-26*