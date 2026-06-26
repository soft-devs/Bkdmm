# ER 图画布功能清单

## 概述

本文档记录 V1 版本 ER 图画布的所有功能，用于指导 V2 版本的迁移和测试验证。

---

## 一、画布功能 (Canvas Features)

### 1.1 视口控制

| 功能 | 操作 | 预览模式 | 编辑模式 | 实现位置 |
|------|------|:--------:|:--------:|----------|
| 平移画布 | 左键拖动 | ✅ | ❌ | InteractiveViewer (panEnabled=true) |
| 平移画布 | 右键拖动 | ❌ | ✅ | 画布 Listener 手动处理 |
| 缩放画布 | 滚轮 | ✅ | ✅ | InteractiveViewer |
| 缩放画布 | 工具栏按钮 | ✅ | ✅ | `_zoomIn()`, `_zoomOut()` |
| 适应屏幕 | 工具栏按钮 | ✅ | ✅ | `_fitToScreen()` |
| 显示坐标 | 鼠标悬停 | ✅ | ✅ | 左下角坐标显示 |

### 1.2 交互模式

| 模式 | 说明 | panEnabled | 可用操作 |
|------|------|:----------:|----------|
| 预览模式 (Preview) | 仅查看，不可编辑 | true | 左键拖动画布、滚轮缩放、双击预览实体 |
| 编辑模式 (Edit) | 可编辑实体和关系 | false | 左键选节点/框选/拖动/连线、右键拖动画布 |

### 1.3 工具栏功能

| 按钮 | 功能 | 实现方法 |
|------|------|----------|
| 预览模式 | 切换到预览模式 | `notifier.enterPreviewMode()` |
| 编辑模式 | 切换到编辑模式 | `notifier.enterEditMode()` |
| 放大 | 放大画布 | `_zoomIn()` |
| 缩小 | 缩小画布 | `_zoomOut()` |
| 适应屏幕 | 缩放以适应所有节点 | `_fitToScreen()` |
| 自动布局 | Sugiyama 算法自动布局 | `_autoLayout()` |

### 1.4 渲染层

| 层级 | 内容 | 实现方式 |
|------|------|----------|
| 背景层 | 无限网格 | `_InfiniteGridPainter` (在 InteractiveViewer 外部) |
| 节点层 | 表节点 Widget | `_ERGraphView` → `ERTableNodeWidget` |
| 边层 | 实体关系连线 | `_EdgePainter` |
| 连线预览层 | 连线时的虚线预览 | `_ConnectionPreviewPainter` (屏幕坐标) |
| 框选预览层 | 框选矩形 | `_SelectionRectPainter` (屏幕坐标) |

---

## 二、节点功能 (Node Features)

### 2.1 节点渲染

| 功能 | 说明 | 实现位置 |
|------|------|----------|
| 表头 | 显示表名和中文名 | `_buildHeader()` |
| 字段列表 | 显示字段名和类型 | `_buildFieldRow()` |
| 主键标记 | 钥匙图标 | `Icons.vpn_key` |
| 选中状态 | 蓝色边框 + 阴影 | `isSelected` 参数 |
| 尺寸计算 | 根据字段数量计算高度 | `calculateNodeSize()` |

### 2.2 节点交互

| 操作 | 模式 | 功能 | 实现方式 |
|------|------|------|----------|
| 单击 | 编辑 | 选中节点 | `GestureDetector.onTap` |
| Ctrl+单击 | 编辑 | 多选/取消选中 | `isCtrlPressed` 检测 |
| 双击 | 预览 | 打开预览弹窗 | `onEntityPreview` 回调 |
| 双击 | 编辑 | 打开编辑弹窗 | `onEntityEdit` 回调 |
| 拖动 | 编辑 | 移动节点 | `GestureDetector.onPanStart/Update/End` |
| 拖动 (多选) | 编辑 | 移动所有选中节点 | `draggingNodeIds` + `_multiDragStartPositions` |

### 2.3 事件拦截机制

节点使用双重策略确保事件正确处理：

```
Listener (opaque)     ← 拦截事件，阻止传递给画布
  └── GestureDetector ← 处理手势
        └── 节点内容
```

**关键配置**：
- `Listener.behavior = HitTestBehavior.opaque` - 拦截所有事件
- `GestureDetector.behavior = HitTestBehavior.opaque` - 确保整个节点区域可响应

---

## 三、锚点功能 (Anchor Features)

### 3.1 锚点渲染

| 功能 | 说明 |
|------|------|
| 位置 | 字段行左右两侧，距离节点边缘 8px |
| 尺寸 | 视觉 6px，点击区域 20px |
| 颜色 | 主键字段黄色，普通字段蓝色 |
| 显示条件 | 仅编辑模式显示 |

### 3.2 锚点交互

| 操作 | 功能 | 实现方式 |
|------|------|----------|
| 第一次点击 | 开始连线 | `startConnection()` |
| 第二次点击 | 完成连线 | `completeConnection()` |
| 移动预览 | 显示连线预览 | `updateConnectionPreview()` |

### 3.3 事件处理

锚点使用独立的 `Listener`，优先级最高：

```dart
Listener(
  behavior: HitTestBehavior.opaque,
  onPointerDown: (event) {
    // 创建锚点数据，触发 onAnchorTap
  },
  child: MouseRegion(
    cursor: SystemMouseCursors.cell,
    child: 锚点视觉元素,
  ),
)
```

---

## 四、事件机制 (Event Mechanism)

### 4.1 Widget 层级结构

```
ERDiagramCanvas (画布)
├── Listener (画布级事件监听, translucent)
│   └── MouseRegion
│       └── Stack
│           ├── IgnorePointer (网格背景)
│           └── InteractiveViewer (动态 panEnabled)
│               └── _ERGraphView
│                   └── ERTableNodeWidget (节点)
│                       ├── Listener (opaque, 拦截事件)
│                       │   └── GestureDetector (处理手势)
│                       │       └── 节点内容
│                       └── ERFieldAnchorLayer (锚点层)
│                           └── Listener (每个锚点)
```

### 4.2 事件处理流程

#### 预览模式

```
用户操作 → Listener (translucent, 记录) → InteractiveViewer (panEnabled=true)
                                             ↓
                                    内置手势处理 (平移/缩放)
```

#### 编辑模式

```
用户操作 → Listener (translucent, 记录)
                ↓
           检查按钮类型
                ↓
    ┌──────────┴──────────┐
    ↓                     ↓
 右键拖动             左键操作
 (手动平移)              ↓
               InteractiveViewer (panEnabled=false)
                        ↓
                   手动命中测试
                        ↓
         ┌──────────────┼──────────────┐
         ↓              ↓              ↓
     在锚点上        在节点上       在空白区域
   (锚点处理)      (节点处理)     (开始框选)
```

### 4.3 手动命中测试

V1 版本的关键设计，解决远距离节点事件失效问题：

```dart
// 1. 屏幕坐标 → 画布坐标
final transform = _transformationController.value;
final inverseTransform = Matrix4.inverted(transform);
final canvasPos = MatrixUtils.transformPoint(inverseTransform, event.localPosition);

// 2. 遍历节点检查点击位置
for (final entity in module.entities) {
  final nodeRect = Rect.fromLTWH(graphNode.x, graphNode.y, width, height);
  // 扩大点击区域以包含锚点
  final expandedRect = nodeRect.inflate(ERFieldAnchorWidget.hitSize);
  if (expandedRect.contains(canvasPos)) {
    // 手动触发选中/拖动
    break;
  }
}
```

### 4.4 HitTestBehavior 说明

| 值 | 行为 | 使用位置 |
|---|------|----------|
| `translucent` | 事件穿透到子组件，同时自己也收到事件 | 画布 Listener |
| `opaque` | 拦截事件，阻止传递给父级 | 节点 Listener、锚点 Listener |
| `deferToChild` | 仅当点击子组件时才响应 | 不使用 |

---

## 五、状态管理 (State Management)

### 5.1 UI 状态 (ERDiagramUIState)

| 字段 | 类型 | 说明 |
|------|------|------|
| `interactionMode` | `ERInteractionMode` | 当前交互模式 (preview/edit) |
| `selectedNodeIds` | `Set<String>` | 选中的节点 ID 集合 |
| `draggingNodeIds` | `Set<String>` | 正在拖动的节点 ID 集合 |
| `isConnecting` | `bool` | 是否正在连线 |
| `connection` | `ConnectionState` | 连线状态 (源锚点、预览终点) |
| `isSelecting` | `bool` | 是否正在框选 |
| `selection` | `SelectionState` | 框选状态 (框选矩形) |

### 5.2 Provider 结构

```
projectNotifierProvider
    └── Project
        └── Module
            ├── entities: List<Entity>      # 实体数据
            └── graphCanvas.nodes: List<GraphNode>  # 节点位置

erDiagramUIProvider(moduleId)
    └── ERDiagramUIState                    # UI 状态
```

---

## 六、V2 迁移清单

### 6.1 已完成的迁移

| 文件 | 状态 | 说明 |
|------|:----:|------|
| `handlers/diagram_event.dart` | ✅ | 事件定义 |
| `handlers/diagram_context.dart` | ✅ | 上下文定义 |
| `handlers/diagram_handler.dart` | ✅ | 处理器基类 |
| `handlers/handler_registry.dart` | ✅ | 处理器注册表 |
| `handlers/anchor_click_handler.dart` | ✅ | 锚点点击处理器 |
| `handlers/node_drag_handler.dart` | ✅ | 节点拖动处理器 |
| `handlers/selection_handler.dart` | ✅ | 框选处理器 |
| `handlers/canvas_pan_handler.dart` | ✅ | 画布平移处理器 |
| `spatial/spatial_index.dart` | ✅ | 空间索引接口 |
| `spatial/simple_index.dart` | ✅ | 简单空间索引实现 |
| `commands/diagram_command.dart` | ✅ | 命令基类 |
| `commands/history_controller.dart` | ✅ | 历史控制器 |
| `integration/er_interaction_manager.dart` | ✅ | ER 图交互管理器 |
| `integration/er_interaction_provider.dart` | ✅ | Riverpod Provider |

### 6.2 待完成的工作

| 任务 | 优先级 | 说明 |
|------|:------:|------|
| ERDiagramCanvasV2 事件集成 | 高 | 将 ERInteractionManager 集成到画布 |
| 解决 InteractiveViewer 事件拦截问题 | 高 | V2 核心问题 |
| 连线处理器 (ConnectionHandler) | 中 | 需要补充 |
| 锚点命中测试集成 | 中 | 空间索引需要包含锚点 |
| 多选拖动支持 | 中 | 当前处理器支持但画布未集成 |
| 命令集成 | 低 | 节点移动命令等 |
| Undo/Redo UI | 低 | 快捷键和工具栏按钮 |

### 6.3 V2 已知问题

1. **InteractiveViewer 拦截事件**
   - 问题：即使 `panEnabled=false`，InteractiveViewer 仍可能拦截手势事件
   - 影响：节点和锚点无法收到事件
   - 解决方案：考虑完全移除 InteractiveViewer 或使用更底层的实现

2. **空间索引初始化**
   - 问题：空间索引可能未正确初始化或更新
   - 影响：命中测试失败
   - 解决方案：确保节点渲染后更新索引

3. **事件传递链断裂**
   - 问题：V2 移除了节点外层的 Listener 拦截器
   - 影响：无法阻止事件传递到画布
   - 解决方案：恢复双重 Listener 策略

---

## 七、测试验证清单

### 7.1 画布测试

- [ ] 预览模式：左键拖动平移画布
- [ ] 编辑模式：右键拖动平移画布
- [ ] 滚轮缩放画布
- [ ] 工具栏缩放按钮
- [ ] 适应屏幕功能
- [ ] 自动布局功能
- [ ] 坐标显示正确

### 7.2 节点测试

- [ ] 单击选中节点
- [ ] Ctrl+单击多选节点
- [ ] 双击打开弹窗（预览/编辑模式）
- [ ] 拖动单个节点
- [ ] 多选拖动多个节点
- [ ] 节点选中状态视觉反馈
- [ ] 远距离节点事件响应

### 7.3 锚点测试

- [ ] 锚点仅在编辑模式显示
- [ ] 点击锚点开始连线
- [ ] 连线预览显示
- [ ] 点击目标锚点完成连线
- [ ] 主键/普通字段锚点颜色区分

### 7.4 框选测试

- [ ] 空白区域开始框选
- [ ] 框选矩形显示
- [ ] 框选结束后正确选中节点
- [ ] 框选不干扰节点交互

---

*文档版本: 1.0*
*最后更新: 2025-06-26*
