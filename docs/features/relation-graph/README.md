# 关系图编辑器 ⚠️ 重点自研

> **阅读时机**: 开发 ER 图可视化编辑功能时
> **重要提示**: Flutter 生态无成熟 ER 图组件，需要自研！

---

## 功能概述

关系图编辑器是**最复杂的模块**，需要自研以下功能：
- 拖拽布局节点
- 可视化关系连线
- 缩放/平移画布
- 搜索节点
- 导出图片

---

## Flutter 方案对比

| 方案 | 优势 | 劣势 | 推荐度 |
|------|------|------|--------|
| **CustomPainter 自绘** | 完全控制、性能好 | 开发量大 | ⭐⭐⭐⭐⭐ |
| flutter_graphview | 基础图布局 | 交互弱、无ER节点 | ⭐⭐ |
| InteractiveViewer + 自绘 | 缩放/平移内置 | 节点交互需自研 | ⭐⭐⭐⭐ |
| WebView + JS库(G6) | 功能成熟 | 性能差、交互复杂 | ⭐⭐ |

---

## 推荐方案: CustomPainter 自绘 + Riverpod

### 架构概述

```
ERDiagramWidget (ConsumerStatefulWidget)
    ├── InteractiveViewer (缩放/平移)
    │       └── CustomPaint (画布)
    │               ├── ERGraphPainter (总绘制器)
    │               │   ├── NodePainter (节点绘制)
    │               │   └── EdgePainter (连线绘制)
    │
    ├── GestureDetector (交互处理)
    │       ├── 拖拽节点
    │       ├── 点击选择
    │       └── 双击编辑
    │
    └── Overlay (右键菜单/弹窗)

Provider 层:
    ├── GraphCanvasNotifier (图画布状态)
    ├── SelectedNodesNotifier (选择状态)
    └── AutoLayoutProvider (自动布局)
```

### 组件实现 (使用 Riverpod)

```dart
// lib/features/modeling/er_diagram/er_diagram_widget.dart

class ERDiagramWidget extends ConsumerStatefulWidget {
  final String moduleId;

  const ERDiagramWidget({
    required this.moduleId,
    super.key,
  });

  @override
  ConsumerState<ERDiagramWidget> createState() => _ERDiagramWidgetState();
}

class _ERDiagramWidgetState extends ConsumerState<ERDiagramWidget> {
  final TransformationController _transformController = TransformationController();
  Offset? _contextMenuPosition;
  String? _draggingNode;
  Offset _dragOffset = Offset.zero;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Riverpod 监听状态
    final graphCanvas = ref.watch(graphCanvasNotifierProvider(widget.moduleId));
    final entities = ref.watch(moduleEntitiesProvider(widget.moduleId));
    final selectedNodes = ref.watch(selectedNodesProvider);

    return Stack(
      children: [
        // 主画布
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.1,
          maxScale: 5.0,
          constrained: false,
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, graphCanvas),
            onPanUpdate: (details) => _onPanUpdate(details, graphCanvas),
            onPanEnd: _onPanEnd,
            onTapDown: (details) => _onTapDown(details, graphCanvas),
            onDoubleTapDown: (details) => _onDoubleTapDown(details, graphCanvas, entities),
            onSecondaryTapDown: (details) => _showContextMenu(details, graphCanvas),
            child: CustomPaint(
              painter: ERGraphPainter(
                nodes: graphCanvas.nodes,
                edges: graphCanvas.edges,
                entities: entities,
                selectedNodes: selectedNodes,
                theme: Theme.of(context),
              ),
              size: const Size(4000, 4000),
            ),
          ),
        ),

        // 工具栏
        _buildToolbar(context, ref),

        // 右键菜单
        if (_contextMenuPosition != null)
          _buildContextMenu(context, ref),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: _zoomIn,
                tooltip: '放大',
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: _zoomOut,
                tooltip: '缩小',
              ),
              IconButton(
                icon: const Icon(Icons.fit_screen),
                onPressed: () => _fitToScreen(ref),
                tooltip: '适应屏幕',
              ),
              const VerticalDivider(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context, ref),
                tooltip: '搜索节点',
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                onPressed: () => _autoLayout(ref),
                tooltip: '自动布局',
              ),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _exportImage,
                tooltip: '导出图片',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
```

### 节点绘制器

```dart
// lib/features/modeling/er_diagram/painters/node_painter.dart

class ERGraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<Entity> entities;
  final Set<String> selectedNodes;
  
  ERGraphPainter({
    required this.nodes,
    required this.edges,
    required this.entities,
    required this.selectedNodes,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制连线
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }
    
    // 2. 绘制节点
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }
  
  void _drawNode(Canvas canvas, GraphNode node) {
    final entity = _getEntity(node.title);
    if (entity == null) return;
    
    final isSelected = selectedNodes.contains(node.title);
    final rect = _getNodeRect(node, entity);
    
    // 背景矩形
    final bgPaint = Paint()
      ..color = isSelected ? Colors.blue.shade100 : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);
    
    // 边框
    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;
    canvas.drawRect(rect, borderPaint);
    
    // 标题栏
    final headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width, 30);
    final headerPaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.blue.shade700
      ..style = PaintingStyle.fill;
    canvas.drawRect(headerRect, headerPaint);
    
    // 标题文字
    final titlePainter = TextPainter(
      text: TextSpan(
        text: '${entity.title}[${entity.chnname}]',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(rect.left + 8, rect.top + 8));
    
    // 字段列表
    double y = rect.top + 35;
    for (final field in entity.fields) {
      final fieldText = '${field.pk ? '🔑 ' : ''}${field.name}: ${field.type}';
      final fieldPainter = TextPainter(
        text: TextSpan(
          text: fieldText,
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      );
      fieldPainter.layout(maxWidth: rect.width - 16);
      fieldPainter.paint(canvas, Offset(rect.left + 8, y));
      y += 20;
    }
  }
  
  void _drawEdge(Canvas canvas, GraphEdge edge) {
    final sourceNode = nodes.firstWhere((n) => n.title == edge.source);
    final targetNode = nodes.firstWhere((n) => n.title == edge.target);
    
    final sourceRect = _getNodeRectByTitle(sourceNode);
    final targetRect = _getNodeRectByTitle(targetNode);
    
    // 计算连线起点和终点
    final startPoint = _getAnchorPoint(sourceRect, targetRect);
    final endPoint = _getAnchorPoint(targetRect, sourceRect);
    
    // 绘制连线
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(startPoint, endPoint, linePaint);
    
    // 绘制箭头
    _drawArrow(canvas, startPoint, endPoint, linePaint);
    
    // 绘制标签
    if (edge.label != null) {
      final labelPainter = TextPainter(
        text: TextSpan(text: edge.label, style: TextStyle(fontSize: 12)),
        textDirection: TextDirection.ltr,
      );
      final midPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        (startPoint.dy + endPoint.dy) / 2,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, midPoint);
    }
  }
  
  @override
  bool shouldRepaint(covariant ERGraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
           edges != oldDelegate.edges ||
           selectedNodes != oldDelegate.selectedNodes;
  }
}
```

### 交互处理

```dart
// lib/features/modeling/er_diagram/er_diagram_widget.dart (续)

void _onPanStart(DragStartDetails details) {
  final position = _transformController.toScene(details.localPosition);
  final hitNode = _hitTestNode(position);
  
  if (hitNode != null) {
    _draggingNode = hitNode.title;
    _dragOffset = Offset(hitNode.x, hitNode.y) - position;
  }
}

void _onPanUpdate(DragUpdateDetails details) {
  if (_draggingNode == null) return;
  
  final position = _transformController.toScene(details.localPosition);
  final newPosition = position + _dragOffset;
  
  // 更新节点位置
  final newNodes = widget.graphCanvas.nodes.map((n) {
    if (n.title == _draggingNode) {
      return GraphNode(
        title: n.title,
        x: newPosition.dx,
        y: newPosition.dy,
        moduleName: n.moduleName,
      );
    }
    return n;
  }).toList();
  
  widget.onGraphChanged(GraphCanvas(
    nodes: newNodes,
    edges: widget.graphCanvas.edges,
  ));
}

void _onPanEnd(DragEndDetails details) {
  _draggingNode = null;
}

void _onTapDown(TapDownDetails details) {
  final position = _transformController.toScene(details.localPosition);
  final hitNode = _hitTestNode(position);
  
  if (hitNode != null) {
    setState(() {
      _selectedNodes = {hitNode.title};
    });
  } else {
    setState(() {
      _selectedNodes = {};
    });
  }
}

void _onDoubleTapDown(TapDownDetails details) {
  final position = _transformController.toScene(details.localPosition);
  final hitNode = _hitTestNode(position);
  
  if (hitNode != null) {
    // 打开数据表编辑 Tab
    _openEntityTab(hitNode);
  }
}

GraphNode? _hitTestNode(Offset position) {
  for (final node in widget.graphCanvas.nodes) {
    final entity = _getEntity(node.title);
    if (entity == null) continue;
    
    final rect = _getNodeRect(node, entity);
    if (rect.contains(position)) {
      return node;
    }
  }
  return null;
}
```

### 自动布局算法

```dart
// lib/features/modeling/er_diagram/layout/dagre_layout.dart

class DagreLayout {
  /// 层次布局算法
  static GraphCanvas layout(List<Entity> entities, List<GraphEdge> edges) {
    // 简化实现: 按字段数量分层
    
    final nodesBySize = entities.sorted((a, b) => b.fields.length.compareTo(a.fields.length));
    
    const nodeWidth = 200.0;
    const nodeHeight = 100.0;
    const horizontalSpacing = 50.0;
    const verticalSpacing = 100.0;
    
    final nodes = <GraphNode>[];
    double x = 50.0;
    double y = 50.0;
    
    for (var i = 0; i < nodesBySize.length; i++) {
      final entity = nodesBySize[i];
      nodes.add(GraphNode(
        title: '${entity.title}:1',
        x: x,
        y: y,
      ));
      
      x += nodeWidth + horizontalSpacing;
      
      // 每行 3 个节点
      if (i % 3 == 2) {
        x = 50.0;
        y += nodeHeight + verticalSpacing;
      }
    }
    
    return GraphCanvas(nodes: nodes, edges: edges);
  }
}
```

### 导出图片

```dart
// lib/features/modeling/er_diagram/export/image_export.dart

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class ImageExportService {
  Future<Uint8List?> exportToPng(GlobalKey key) async {
    try {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveToFile(Uint8List bytes, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
  }
}
```

---

## 数据模型 (使用 Freezed)

```dart
// lib/shared/models/graph.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'graph.freezed.dart';
part 'graph.g.dart';

@freezed
class GraphCanvas with _$GraphCanvas {
  const factory GraphCanvas({
    @Default([]) List<GraphNode> nodes,
    @Default([]) List<GraphEdge> edges,
    Viewport? viewport,
  }) = _GraphCanvas;

  factory GraphCanvas.fromJson(Map<String, dynamic> json) =>
      _$GraphCanvasFromJson(json);
}

@freezed
class GraphNode with _$GraphNode {
  const factory GraphNode({
    required String title,      // 格式: 表名:序号
    required double x,
    required double y,
    String? moduleName,         // 跨模块标记
  }) = _GraphNode;

  factory GraphNode.fromJson(Map<String, dynamic> json) =>
      _$GraphNodeFromJson(json);
}

@freezed
class GraphEdge with _$GraphEdge {
  const factory GraphEdge({
    required String source,     // 源节点 "User:1"
    required String target,     // 目标节点 "Order:1"
    String? label,
    String? relationType,
  }) = _GraphEdge;

  factory GraphEdge.fromJson(Map<String, dynamic> json) =>
      _$GraphEdgeFromJson(json);
}

@freezed
class Viewport with _$Viewport {
  const factory Viewport({
    @Default(1.0) double scale,
    @Default(Offset.zero) Offset offset,
  }) = _Viewport;

  factory Viewport.fromJson(Map<String, dynamic> json) =>
      _$ViewportFromJson(json);
}
```

---

## 已知坑点

1. **节点标题格式**: 必须为 `表名:序号`，冒号分隔
2. **节点更新**: 需手动触发重绘
3. **跨模块节点**: moduleName 设为目标模块名
4. **无效数据清理**: 删除表后需清理对应节点和边
5. **缩放限制**: scale 范围 0.1-5.0
6. **连线锚点**: 需计算最近锚点避免重叠

---

## 参考资源

- Flutter CustomPainter 文档: https://docs.flutter.dev/ui/painting
- InteractiveViewer 文档: https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html
- 原实现参考: [../reference/relation.md](../reference/relation.md)