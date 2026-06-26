# V1 版本 ER 图事件处理流程分析

## 核心架构

### Widget 层级结构

```
ERDiagramCanvas (画布)
├── Listener (画布级事件监听)
│   └── MouseRegion
│       └── Stack
│           ├── IgnorePointer (网格背景)
│           └── InteractiveViewer (panEnabled: 预览模式开启，编辑模式关闭)
│               └── _ERGraphView
│                   └── ERTableNodeWidget (节点)
│                       ├── Listener (拦截事件，阻止传递给画布)
│                       │   └── GestureDetector (处理点击、双击、拖动)
│                       │       └── 节点内容
│                       └── ERFieldAnchorLayer (锚点层)
│                           └── Listener (每个锚点)
│                               └── 锚点视觉元素
```

## 事件处理流程

### 1. 预览模式 (Preview Mode)

| 操作 | 处理方式 | 效果 |
|------|---------|------|
| 左键拖动 | InteractiveViewer 内置处理 | 平移画布 |
| 左键点击节点 | ERTableNodeWidget 的 GestureDetector | 无响应 |
| 左键双击节点 | ERTableNodeWidget 的 GestureDetector | 打开预览弹窗 |
| 滚轮缩放 | InteractiveViewer 内置处理 | 缩放画布 |

**关键配置**：
- `InteractiveViewer.panEnabled = true` (预览模式)
- 节点的 `GestureDetector.behavior = HitTestBehavior.opaque`
- 节点的 `Listener.behavior = HitTestBehavior.opaque` (拦截事件)

### 2. 编辑模式 (Edit Mode)

| 操作 | 处理方式 | 效果 |
|------|---------|------|
| 左键点击空白 | 画布 Listener → 检测点击不在节点上 → 启动框选 | 框选节点 |
| 左键点击节点 | 节点 Listener 拦截 → GestureDetector.onTap | 选中节点 |
| 左键拖动节点 | 节点 Listener 拦截 → GestureDetector.onPanStart/Update/End | 拖动节点 |
| 左键双击节点 | 节点 GestureDetector.onDoubleTap | 打开编辑弹窗 |
| 左键点击锚点 | 锚点 Listener → 回调 onAnchorTap | 开始连线 |
| 右键拖动 | 画布 Listener → 检测右键 → 手动平移变换 | 平移画布 |
| 滚轮缩放 | InteractiveViewer 内置处理 | 缩放画布 |

**关键配置**：
- `InteractiveViewer.panEnabled = false` (编辑模式)
- 节点的 `Listener.behavior = HitTestBehavior.opaque` (阻止事件传递到画布)
- 节点的 `GestureDetector.behavior = HitTestBehavior.opaque`

## V1 版本的关键设计

### 1. 双重 Listener 策略

```
画布 Listener ( translucent )
    ↓ 事件穿透
InteractiveViewer
    ↓ 事件穿透 (panEnabled=false 时)
节点 Listener ( opaque ) ← 拦截事件，阻止继续传递
    ↓ 事件被消费
GestureDetector
    ↓ 处理手势
回调函数
```

### 2. 手动命中测试

在画布的 `_onPointerDown` 中，当左键按下时：
1. 将屏幕坐标转换为画布坐标
2. 遍历所有节点，检查点击是否在节点的扩展区域内
3. 如果在节点上，手动触发选中逻辑
4. 如果不在节点上，启动框选

### 3. 远距离节点事件失效的解决方案

V1 版本通过手动命中测试解决了节点事件失效问题：
- 不依赖 Widget 的命中测试（距离太远会失效）
- 在画布层手动计算点击位置是否在节点区域内
- 手动调用选中回调

### 4. 事件拦截机制

节点外层的 `Listener` 使用 `HitTestBehavior.opaque`：
- 拦截所有指针事件
- 阻止事件继续传递到画布
- 避免在点击节点时触发画布的框选

### 5. 锚点事件处理

锚点使用独立的 `Listener`：
- `behavior: HitTestBehavior.opaque`
- 独立处理点击事件
- 触发 `onAnchorTap` 回调

## 事件流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户点击屏幕                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    画布 Listener (translucent)                   │
│                    记录所有指针事件                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      InteractiveViewer                           │
│                 (编辑模式下 panEnabled=false)                     │
│                      不拦截手势事件                               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              点击是否在节点区域内？（手动命中测试）                 │
└─────────────────────────────────────────────────────────────────┘
                    │                   │
                    ▼                   ▼
           ┌──────────────┐    ┌──────────────┐
           │   在节点上    │    │  不在节点上   │
           └──────────────┘    └──────────────┘
                    │                   │
                    ▼                   ▼
    ┌────────────────────────┐  ┌──────────────────────┐
    │ 节点 Listener 拦截事件  │  │ 启动框选逻辑          │
    │ GestureDetector 处理   │  │ 记录框选起点          │
    │ - onTap: 选中节点      │  └──────────────────────┘
    │ - onPanStart: 开始拖动 │
    │ - onDoubleTap: 编辑    │
    └────────────────────────┘
```

## 关键代码片段

### 画布 Listener (er_diagram_canvas.dart)

```dart
return Listener(
  behavior: HitTestBehavior.translucent,
  onPointerDown: (event) => _onPointerDown(event, uiState),
  onPointerMove: (event) => _onPointerMove(event, uiState),
  onPointerUp: (event) => _onPointerUp(event, uiState, entityMap, graphNodeMap),
  child: MouseRegion(
    // ...
    child: Stack(
      children: [
        // 网格背景
        InteractiveViewer(
          panEnabled: uiState.isPreviewMode, // 关键！
          scaleEnabled: true,
          child: _ERGraphView(...),
        ),
      ],
    ),
  ),
);
```

### 节点 Widget (er_table_node_widget.dart)

```dart
// 先用 Listener 拦截事件
content = Listener(
  onPointerDown: (event) {
    // 拦截事件，不传递给父级
  },
  behavior: HitTestBehavior.opaque, // 关键！
  child: content,
);

// 再用 GestureDetector 处理手势
if (widget.isEditMode) {
  content = GestureDetector(
    behavior: HitTestBehavior.opaque, // 关键！
    onTap: _onTap,
    onDoubleTap: widget.onDoubleTap,
    onPanStart: _onPanStart,
    onPanUpdate: _onPanUpdate,
    onPanEnd: _onPanEnd,
    child: content,
  );
}
```

### 手动命中测试 (er_diagram_canvas.dart _onPointerDown)

```dart
// 将屏幕坐标转换为画布坐标
final transform = _transformationController.value;
final inverseTransform = Matrix4.inverted(transform);
final canvasPos = MatrixUtils.transformPoint(inverseTransform, event.localPosition);

// 检查每个节点
for (final entity in module.entities) {
  final graphNode = module.graphCanvas.nodes.firstWhere(...);
  final nodeSize = ERTableNodeWidget.calculateNodeSize(entity.fields.length);
  final nodeRect = Rect.fromLTWH(graphNode.x, graphNode.y, nodeSize.width, nodeSize.height);

  // 扩大点击区域以包含锚点
  final expandedRect = nodeRect.inflate(ERFieldAnchorWidget.hitSize);
  if (expandedRect.contains(canvasPos)) {
    // 手动触发选中
    notifier.selectNodeSingle(entity.id);
    // 启动拖动
    _isDraggingNode = true;
    _manualDragNodeId = entity.id;
    break;
  }
}
```

## V2 版本的问题

V2 版本引入了 `ERInteractionManager` 和新的架构，但导致事件失效：

1. **InteractiveViewer 拦截事件**：在编辑模式下 `panEnabled=false`，但 InteractiveViewer 仍然可能拦截事件
2. **移除了手动命中测试**：V2 依赖 `ERInteractionManager.spatialIndex`，但可能初始化或更新不正确
3. **事件传递链断裂**：移除了节点外层的 `Listener` 拦截器，导致事件可能无法正确传递

## 建议

恢复 V1 的工作版本，然后渐进式地引入新功能，确保每一步都正常工作。
