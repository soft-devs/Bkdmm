# ER图编辑器 ⚠️ 重点自研

> 阅读时机: 开发 ER 图功能
> **重要**: Flutter 无成熟组件，需自研！

---

## 功能

- 节点显示 (表名+字段)
- 拖拽移动
- 缩放/平移
- 关系连线
- 导出图片

---

## 代码路径

```
lib/features/modeling/er_diagram/
├── widgets/
│   └── er_diagram_widget.dart
├── painters/
│   ├── node_painter.dart
│   └── edge_painter.dart
└── layout/
    └── dagre_layout.dart
```

---

## 实现方案

### 架构

```
ERDiagramWidget
    ├── InteractiveViewer  # 缩放/平移 (内置)
    ├── CustomPaint        # 画布绘制
    │       ├── NodePainter
    │       └── EdgePainter
    └── GestureDetector    # 交互
```

### 主组件

```dart
class ERDiagramWidget extends StatefulWidget {
  final GraphCanvas graphCanvas;
  final List<Entity> entities;
}

Widget build(BuildContext context) {
  return InteractiveViewer(
    minScale: 0.1,
    maxScale: 5.0,
    child: GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: CustomPaint(
        painter: ERGraphPainter(nodes, edges, entities),
        size: Size(2000, 2000),
      ),
    ),
  );
}
```

### 节点绘制

```dart
void _drawNode(Canvas canvas, GraphNode node) {
  // 背景矩形
  canvas.drawRect(rect, Paint()..color = Colors.white);

  // 标题栏
  canvas.drawRect(headerRect, Paint()..color = Colors.blue);

  // 标题文字
  TextPainter(text: TextSpan(text: title))..paint(canvas, offset);

  // 字段列表
  for (final field in fields) {
    // 绘制字段行
  }
}
```

### 交互

```dart
void _onPanStart(DragStartDetails details) {
  final position = _transformController.toScene(details.localPosition);
  final hitNode = _hitTestNode(position);
  if (hitNode != null) _draggingNode = hitNode;
}
```

---

## 工具栏

| 功能 | 实现 |
|------|------|
| 放大/缩小 | `transformController.value.scale * factor` |
| 复原 | `Matrix4.identity()` |
| 导出 | `RepaintBoundary.toImage()` |

---

## 坑点

1. 节点标题格式: `表名:序号`
2. 坐标转换: `toScene()`
3. 数据变更需 `setState()`

---

## 相关文档

- [系统架构](../../需求与架构/系统架构/系统架构.md)
- [技术选型](../../需求与架构/系统架构/技术选型.md)