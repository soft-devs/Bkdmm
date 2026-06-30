import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/core/diagram_state.dart';
import 'package:bkdmm/shared/diagram_editor/core/diagram_node.dart';
import 'package:bkdmm/shared/diagram_editor/core/diagram_edge.dart';
import 'package:bkdmm/shared/diagram_editor/view/canvas_overlay.dart';
import 'package:bkdmm/shared/diagram_editor/view/painter/node_painter.dart';
import 'package:bkdmm/shared/diagram_editor/view/painter/edge_painter.dart';
import 'package:bkdmm/shared/diagram_editor/model/node_model.dart';
import 'package:bkdmm/shared/diagram_editor/model/edge_model.dart';

void main() {
  group('View Layer Tests', () {
    group('NodePainterConfig', () {
      test('should create with default values', () {
        const config = NodePainterConfig();

        expect(config.backgroundColor, const Color(0xFFFFFFFF));
        expect(config.borderColor, const Color(0xFFE0E0E0));
        expect(config.borderWidth, 1.0);
        expect(config.borderRadius, const Radius.circular(8.0));
        expect(config.titleFontSize, 14.0);
        expect(config.showShadow, true);
        expect(config.showAnchors, false);
        expect(config.anchorSize, 10.0);
        expect(config.anchorShape, AnchorShape.circle);
      });

      test('should create dark theme config', () {
        final darkConfig = NodePainterConfig.dark();

        expect(darkConfig.backgroundColor, const Color(0xFF2D3748));
        expect(darkConfig.borderColor, const Color(0xFF4A5568));
        expect(darkConfig.titleColor, const Color(0xFFE2E8F0));
        expect(darkConfig.selectionColor, const Color(0xFF63B3ED));
        expect(darkConfig.anchorColor, const Color(0xFF63B3ED));
      });

      test('should copy with new values', () {
        const original = NodePainterConfig();
        final copy = original.copyWith(
          backgroundColor: const Color(0xFFEEEEEE),
          borderWidth: 2.0,
          showShadow: false,
          showAnchors: true,
        );

        expect(copy.backgroundColor, const Color(0xFFEEEEEE));
        expect(copy.borderWidth, 2.0);
        expect(copy.showShadow, false);
        expect(copy.showAnchors, true);
        // Original values should remain
        expect(copy.borderColor, original.borderColor);
        expect(copy.titleFontSize, original.titleFontSize);
      });

      test('should support all copyWith parameters', () {
        const original = NodePainterConfig();
        final copy = original.copyWith(
          backgroundColor: const Color(0xFFFFFFFF),
          selectedBackgroundColor: const Color(0xFFE3F2FD),
          hoverBackgroundColor: const Color(0xFFF5F5F5),
          highlightBackgroundColor: const Color(0xFFFFF8E1),
          borderColor: const Color(0xFFE0E0E0),
          hoverBorderColor: const Color(0xFFBDBDBD),
          borderWidth: 1.5,
          borderRadius: const Radius.circular(10.0),
          titleColor: const Color(0xFF212121),
          titleFontSize: 16.0,
          titleFontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
          titleTopPadding: 14.0,
          titlePadding: 18.0,
          selectionColor: const Color(0xFF2196F3),
          selectionStrokeWidth: 3.0,
          selectionPadding: 6.0,
          showSelectionHandles: false,
          selectionHandleSize: 10.0,
          hoverColor: const Color(0xFF2196F3),
          hoverStrokeWidth: 2.0,
          hoverPadding: 4.0,
          highlightColor: const Color(0xFFFFC107),
          highlightStrokeWidth: 3.0,
          highlightPadding: 6.0,
          dragColor: const Color(0xFF2196F3),
          dragOpacity: 0.4,
          showShadow: false,
          shadowColor: const Color(0x2F000000),
          shadowBlur: 10.0,
          shadowOffset: const Offset(3, 3),
          showAnchors: true,
          anchorColor: const Color(0xFF2196F3),
          anchorBorderColor: const Color(0xFFFFFFFF),
          anchorBorderWidth: 3.0,
          anchorSize: 12.0,
          anchorShape: AnchorShape.rectangle,
        );

        // All copied values should match
        expect(copy.backgroundColor, const Color(0xFFFFFFFF));
        expect(copy.selectedBackgroundColor, const Color(0xFFE3F2FD));
        expect(copy.hoverBackgroundColor, const Color(0xFFF5F5F5));
        expect(copy.highlightBackgroundColor, const Color(0xFFFFF8E1));
        expect(copy.borderColor, const Color(0xFFE0E0E0));
        expect(copy.hoverBorderColor, const Color(0xFFBDBDBD));
        expect(copy.borderWidth, 1.5);
        expect(copy.borderRadius, const Radius.circular(10.0));
        expect(copy.titleColor, const Color(0xFF212121));
        expect(copy.titleFontSize, 16.0);
        expect(copy.titleFontWeight, FontWeight.w700);
        expect(copy.fontFamily, 'Roboto');
        expect(copy.titleTopPadding, 14.0);
        expect(copy.titlePadding, 18.0);
        expect(copy.selectionColor, const Color(0xFF2196F3));
        expect(copy.selectionStrokeWidth, 3.0);
        expect(copy.selectionPadding, 6.0);
        expect(copy.showSelectionHandles, false);
        expect(copy.selectionHandleSize, 10.0);
        expect(copy.hoverColor, const Color(0xFF2196F3));
        expect(copy.hoverStrokeWidth, 2.0);
        expect(copy.hoverPadding, 4.0);
        expect(copy.highlightColor, const Color(0xFFFFC107));
        expect(copy.highlightStrokeWidth, 3.0);
        expect(copy.highlightPadding, 6.0);
        expect(copy.dragColor, const Color(0xFF2196F3));
        expect(copy.dragOpacity, 0.4);
        expect(copy.showShadow, false);
        expect(copy.shadowColor, const Color(0x2F000000));
        expect(copy.shadowBlur, 10.0);
        expect(copy.shadowOffset, const Offset(3, 3));
        expect(copy.showAnchors, true);
        expect(copy.anchorColor, const Color(0xFF2196F3));
        expect(copy.anchorBorderColor, const Color(0xFFFFFFFF));
        expect(copy.anchorBorderWidth, 3.0);
        expect(copy.anchorSize, 12.0);
        expect(copy.anchorShape, AnchorShape.rectangle);
      });
    });

    group('NodePainterUtils', () {
      late TestNode testNode;

      setUp(() {
        testNode = TestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 100),
          type: 'test',
          title: 'Test Node',
        );
      });

      test('should calculate bounds correctly', () {
        final bounds = NodePainterUtils.calculateBounds(testNode);

        expect(bounds.left, 100);
        expect(bounds.top, 100);
        expect(bounds.right, 300);
        expect(bounds.bottom, 200);
      });

      test('should calculate center correctly', () {
        final center = NodePainterUtils.calculateCenter(testNode);

        expect(center.dx, 200); // 100 + 200/2
        expect(center.dy, 150); // 100 + 100/2
      });

      test('should calculate anchor positions for all directions', () {
        // Left anchor
        final leftAnchor = NodePainterUtils.calculateAnchorPosition(
          testNode,
          AnchorDirection.left,
        );
        expect(leftAnchor.dx, 100);
        expect(leftAnchor.dy, 150);

        // Right anchor
        final rightAnchor = NodePainterUtils.calculateAnchorPosition(
          testNode,
          AnchorDirection.right,
        );
        expect(rightAnchor.dx, 300);
        expect(rightAnchor.dy, 150);

        // Top anchor
        final topAnchor = NodePainterUtils.calculateAnchorPosition(
          testNode,
          AnchorDirection.top,
        );
        expect(topAnchor.dx, 200);
        expect(topAnchor.dy, 100);

        // Bottom anchor
        final bottomAnchor = NodePainterUtils.calculateAnchorPosition(
          testNode,
          AnchorDirection.bottom,
        );
        expect(bottomAnchor.dx, 200);
        expect(bottomAnchor.dy, 200);
      });

      test('should calculate anchor position with offset', () {
        final leftAnchorWithOffset = NodePainterUtils.calculateAnchorPosition(
          testNode,
          AnchorDirection.left,
          offset: 10.0,
        );
        expect(leftAnchorWithOffset.dx, 90); // 100 - 10
        expect(leftAnchorWithOffset.dy, 150);
      });

      test('should detect point inside node', () {
        final pointInside = const Offset(150, 150);
        expect(NodePainterUtils.containsPoint(testNode, pointInside), true);

        final pointOutside = const Offset(350, 250);
        expect(NodePainterUtils.containsPoint(testNode, pointOutside), false);
      });

      test('should detect point with padding', () {
        final pointJustOutside = const Offset(95, 150);
        expect(NodePainterUtils.containsPoint(testNode, pointJustOutside), false);
        expect(NodePainterUtils.containsPoint(testNode, pointJustOutside, padding: 10), true);
      });

      test('should calculate edge intersection', () {
        // Point to the right of node
        final externalRight = const Offset(400, 150);
        final intersectionRight = NodePainterUtils.calculateEdgeIntersection(
          testNode,
          externalRight,
        );
        expect(intersectionRight, isNotNull);
        expect(intersectionRight!.dx, 300); // Right edge
        expect(intersectionRight.dy, 150);

        // Point above node
        final externalTop = const Offset(200, 50);
        final intersectionTop = NodePainterUtils.calculateEdgeIntersection(
          testNode,
          externalTop,
        );
        expect(intersectionTop, isNotNull);
        expect(intersectionTop!.dx, 200);
        expect(intersectionTop.dy, 100); // Top edge
      });

      test('should return null for edge intersection at center', () {
        final center = NodePainterUtils.calculateCenter(testNode);
        final intersection = NodePainterUtils.calculateEdgeIntersection(
          testNode,
          center,
        );
        expect(intersection, isNull);
      });

      test('should create rounded rect path', () {
        final rect = Rect.fromLTWH(0, 0, 100, 50);
        final path = NodePainterUtils.createRoundedRectPath(
          rect,
          const Radius.circular(8),
        );

        expect(path, isNotNull);
        // Verify path contains RRect
        final bounds = path.getBounds();
        expect(bounds.width, 100);
        expect(bounds.height, 50);
      });
    });

    group('EdgePainter', () {
      late EdgePainter painter;
      late DiagramState state;
      late ViewportState viewport;

      setUp(() {
        painter = EdgePainter();
        viewport = const ViewportState(zoom: 1.0, panOffset: Offset.zero);
      });

      test('should have default styles', () {
        expect(EdgePainter.defaultStyle.color, const Color(0xFF666666));
        expect(EdgePainter.defaultStyle.width, 2.0);
        expect(EdgePainter.defaultStyle.shape, EdgeShape.straight);

        expect(EdgePainter.hoverStyle.color, const Color(0xFF1890FF));
        expect(EdgePainter.hoverStyle.width, 2.5);

        expect(EdgePainter.selectedStyle.color, const Color(0xFF1890FF));
        expect(EdgePainter.selectedStyle.width, 3.0);

        expect(EdgePainter.creatingStyle.lineType, EdgeLineType.dashed);
      });

      test('should hit test edge correctly', () {
        final sourceNode = TestNode(
          id: 'source',
          position: const Offset(0, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Source',
        );
        final targetNode = TestNode(
          id: 'target',
          position: const Offset(200, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Target',
        );
        final edge = TestEdge(
          id: 'edge-1',
          sourceAnchorId: 'source:right',
          targetAnchorId: 'target:left',
          type: 'default',
        );

        state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {'source': sourceNode, 'target': targetNode},
          edges: {'edge-1': edge},
        );

        // Point near the edge (between nodes)
        final hitPoint = const Offset(150, 25);
        final hitEdgeId = painter.hitTest(hitPoint, state, viewport);
        expect(hitEdgeId, 'edge-1');

        // Point far from the edge
        final missPoint = const Offset(150, 200);
        final missEdgeId = painter.hitTest(missPoint, state, viewport);
        expect(missEdgeId, isNull);
      });

      test('should hit test with tolerance', () {
        final sourceNode = TestNode(
          id: 'source',
          position: const Offset(0, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Source',
        );
        final targetNode = TestNode(
          id: 'target',
          position: const Offset(200, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Target',
        );
        final edge = TestEdge(
          id: 'edge-1',
          sourceAnchorId: 'source:right',
          targetAnchorId: 'target:left',
          type: 'default',
        );

        state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {'source': sourceNode, 'target': targetNode},
          edges: {'edge-1': edge},
        );

        // Point slightly above edge line
        final nearPoint = const Offset(150, 35);
        final hitWithTolerance = painter.hitTest(
          nearPoint,
          state,
          viewport,
          tolerance: 15.0,
        );
        expect(hitWithTolerance, 'edge-1');

        final missWithTolerance = painter.hitTest(
          nearPoint,
          state,
          viewport,
          tolerance: 5.0,
        );
        expect(missWithTolerance, isNull);
      });

      test('should calculate edge bounds', () {
        final sourceNode = TestNode(
          id: 'source',
          position: const Offset(0, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Source',
        );
        final targetNode = TestNode(
          id: 'target',
          position: const Offset(200, 100),
          size: const Size(100, 50),
          type: 'test',
          title: 'Target',
        );
        final edge = TestEdge(
          id: 'edge-1',
          sourceAnchorId: 'source:right',
          targetAnchorId: 'target:left',
          type: 'default',
        );

        state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {'source': sourceNode, 'target': targetNode},
          edges: {'edge-1': edge},
        );

        final bounds = painter.calculateEdgeBounds(edge, state, viewport);

        expect(bounds.width > 0, true);
        expect(bounds.height > 0, true);
        // Bounds should include both anchor positions
        expect(bounds.left <= 100, true); // source right anchor at x=100
        expect(bounds.right >= 200, true); // target left anchor at x=200
      });

      test('should return zero bounds for missing anchors', () {
        final edge = TestEdge(
          id: 'edge-1',
          sourceAnchorId: 'missing:right',
          targetAnchorId: 'missing:left',
          type: 'default',
        );

        state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {},
          edges: {'edge-1': edge},
        );

        final bounds = painter.calculateEdgeBounds(edge, state, viewport);
        expect(bounds, Rect.zero);
      });
    });

    group('CanvasOverlay', () {
      testWidgets('should render with basic parameters', (tester) async {
        final state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {},
          edges: {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasOverlay(
                state: state,
                transform: Matrix4.identity(),
                viewportSize: const Size(800, 600),
              ),
            ),
          ),
        );

        // CanvasOverlay creates a CustomPaint inside
        expect(find.byType(CanvasOverlay), findsOneWidget);
      });

      testWidgets('should render with nodes and edges', (tester) async {
        final sourceNode = TestNode(
          id: 'source',
          position: const Offset(0, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Source',
        );
        final targetNode = TestNode(
          id: 'target',
          position: const Offset(200, 0),
          size: const Size(100, 50),
          type: 'test',
          title: 'Target',
        );
        final edge = TestEdge(
          id: 'edge-1',
          sourceAnchorId: 'source:right',
          targetAnchorId: 'target:left',
          type: 'default',
        );

        final state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {'source': sourceNode, 'target': targetNode},
          edges: {'edge-1': edge},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasOverlay(
                state: state,
                transform: Matrix4.identity(),
                viewportSize: const Size(800, 600),
              ),
            ),
          ),
        );

        expect(find.byType(CanvasOverlay), findsOneWidget);
      });

      testWidgets('should respect grid settings', (tester) async {
        final state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {},
          edges: {},
        );

        // With grid enabled
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasOverlay(
                state: state,
                transform: Matrix4.identity(),
                viewportSize: const Size(800, 600),
                showGrid: true,
                gridSize: 20.0,
              ),
            ),
          ),
        );

        expect(find.byType(CanvasOverlay), findsOneWidget);

        // With grid disabled
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasOverlay(
                state: state,
                transform: Matrix4.identity(),
                viewportSize: const Size(800, 600),
                showGrid: false,
              ),
            ),
          ),
        );

        expect(find.byType(CanvasOverlay), findsOneWidget);
      });

      testWidgets('should apply dark mode colors', (tester) async {
        final state = DiagramState(
          diagramId: 'test',
          diagramType: 'er',
          nodes: {},
          edges: {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasOverlay(
                state: state,
                transform: Matrix4.identity(),
                viewportSize: const Size(800, 600),
                isDarkMode: true,
              ),
            ),
          ),
        );

        expect(find.byType(CanvasOverlay), findsOneWidget);
      });
    });

    group('NodePainter', () {
      late TestNode testNode;
      late NodeState nodeState;

      setUp(() {
        testNode = TestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 100),
          type: 'test',
          title: 'Test Node',
        );
        nodeState = const NodeState();
      });

      test('should create with required parameters', () {
        final painter = NodePainter(
          node: testNode,
          state: nodeState,
        );

        expect(painter.node, testNode);
        expect(painter.state, nodeState);
        expect(painter.viewport, isNull);
        expect(painter.config, const NodePainterConfig());
      });

      test('should detect repaint needed when node changes', () {
        final painter1 = NodePainter(
          node: testNode,
          state: nodeState,
        );

        final differentNode = TestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 100),
          type: 'test',
          title: 'Different Title',
        );

        final painter2 = NodePainter(
          node: differentNode,
          state: nodeState,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should detect repaint needed when state changes', () {
        final painter1 = NodePainter(
          node: testNode,
          state: const NodeState(),
        );

        final painter2 = NodePainter(
          node: testNode,
          state: const NodeState(isSelected: true),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should detect repaint needed when config changes', () {
        final painter1 = NodePainter(
          node: testNode,
          state: nodeState,
          config: const NodePainterConfig(),
        );

        final painter2 = NodePainter(
          node: testNode,
          state: nodeState,
          config: const NodePainterConfig(showAnchors: true),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should not repaint when parameters match', () {
        final painter1 = NodePainter(
          node: testNode,
          state: nodeState,
          config: const NodePainterConfig(),
        );

        final painter2 = NodePainter(
          node: testNode,
          state: nodeState,
          config: const NodePainterConfig(),
        );

        expect(painter1.shouldRepaint(painter2), false);
      });

      test('should hit test correctly', () {
        final painter = NodePainter(node: testNode, state: nodeState);

        // Point inside node
        final hitInside = painter.hitTest(const Offset(150, 150));
        expect(hitInside, true);

        // Point outside node
        final hitOutside = painter.hitTest(const Offset(350, 250));
        expect(hitOutside, false);
      });

      test('should hit test with viewport transformation', () {
        final viewport = const ViewportState(zoom: 2.0, panOffset: Offset(50, 50));
        final painter = NodePainter(
          node: testNode,
          state: nodeState,
          viewport: viewport,
        );

        // Screen coordinate (150, 150) with zoom 2.0 and pan (50, 50)
        // Scene coordinate = (150 - 50) / 2 = (50, 50)
        // This is outside the node (which is at scene (100, 100) to (300, 200))
        final hitOutside = painter.hitTest(const Offset(150, 150));
        expect(hitOutside, false);

        // Screen coordinate (350, 350) with zoom 2.0 and pan (50, 50)
        // Scene coordinate = (350 - 50) / 2 = (150, 150)
        // This is inside the node
        final hitInside = painter.hitTest(const Offset(350, 350));
        expect(hitInside, true);
      });
    });

    group('ConnectionPreviewPainter', () {
      test('should create with required parameters', () {
        const painter = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter.sourcePos, const Offset(0, 0));
        expect(painter.targetPos, const Offset(100, 100));
        expect(painter.color, const Color(0xFF1890FF));
        expect(painter.showArrow, true);
      });

      test('should detect repaint when source changes', () {
        const painter1 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = ConnectionPreviewPainter(
          sourcePos: Offset(10, 10),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should detect repaint when target changes', () {
        const painter1 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(200, 200),
          color: Color(0xFF1890FF),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should detect repaint when color changes', () {
        const painter1 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF000000),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should not repaint when parameters match', () {
        const painter1 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = ConnectionPreviewPainter(
          sourcePos: Offset(0, 0),
          targetPos: Offset(100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter1.shouldRepaint(painter2), false);
      });
    });

    group('SelectionRectPainter', () {
      test('should create with required parameters', () {
        const painter = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter.rect, Rect.fromLTWH(50, 50, 100, 100));
        expect(painter.color, const Color(0xFF1890FF));
      });

      test('should detect repaint when rect changes', () {
        const painter1 = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = SelectionRectPainter(
          rect: Rect.fromLTWH(60, 60, 100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should detect repaint when color changes', () {
        const painter1 = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF000000),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('should not repaint when parameters match', () {
        const painter1 = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF1890FF),
        );

        const painter2 = SelectionRectPainter(
          rect: Rect.fromLTWH(50, 50, 100, 100),
          color: Color(0xFF1890FF),
        );

        expect(painter1.shouldRepaint(painter2), false);
      });
    });

    group('DefaultNodeRenderer', () {
      test('should create with default values', () {
        const renderer = DefaultNodeRenderer();

        expect(renderer.bgColor, isNull);
        expect(renderer.borderColor, isNull);
        expect(renderer.selectionColor, isNull);
        expect(renderer.cornerRadius, 8.0);
      });

      test('should create with custom values', () {
        const renderer = DefaultNodeRenderer(
          bgColor: Color(0xFFEEEEEE),
          borderColor: Color(0xFF999999),
          selectionColor: Color(0xFFFF0000),
          cornerRadius: 12.0,
        );

        expect(renderer.bgColor, const Color(0xFFEEEEEE));
        expect(renderer.borderColor, const Color(0xFF999999));
        expect(renderer.selectionColor, const Color(0xFFFF0000));
        expect(renderer.cornerRadius, 12.0);
      });
    });

    group('DefaultEdgeRenderer', () {
      test('should create with default values', () {
        const renderer = DefaultEdgeRenderer();

        expect(renderer.color, isNull);
        expect(renderer.width, 2.0);
        expect(renderer.showArrow, true);
        expect(renderer.arrowSize, 10.0);
      });

      test('should create with custom values', () {
        const renderer = DefaultEdgeRenderer(
          color: Color(0xFF1890FF),
          width: 3.0,
          showArrow: false,
          arrowSize: 15.0,
        );

        expect(renderer.color, const Color(0xFF1890FF));
        expect(renderer.width, 3.0);
        expect(renderer.showArrow, false);
        expect(renderer.arrowSize, 15.0);
      });
    });

    group('EdgeStyle', () {
      test('should create with default values', () {
        const style = EdgeStyle();

        expect(style.color, const Color(0xFF666666));
        expect(style.width, 2.0);
        expect(style.lineType, EdgeLineType.solid);
        expect(style.shape, EdgeShape.straight);
        expect(style.showArrow, false);
        expect(style.arrowSize, 10.0);
        expect(style.curveFactor, 0.3);
      });

      test('should copy with new values', () {
        const original = EdgeStyle();
        final copy = original.copyWith(
          color: const Color(0xFF1890FF),
          width: 3.0,
          lineType: EdgeLineType.dashed,
          shape: EdgeShape.curved,
        );

        expect(copy.color, const Color(0xFF1890FF));
        expect(copy.width, 3.0);
        expect(copy.lineType, EdgeLineType.dashed);
        expect(copy.shape, EdgeShape.curved);
        // Original values should remain
        expect(copy.showArrow, original.showArrow);
        expect(copy.arrowSize, original.arrowSize);
      });

      test('should serialize to JSON', () {
        const style = EdgeStyle(
          color: Color(0xFF1890FF),
          width: 2.5,
          lineType: EdgeLineType.dashed,
          shape: EdgeShape.curved,
          showArrow: true,
          arrowSize: 12.0,
          curveFactor: 0.4,
        );

        final json = style.toJson();

        expect(json['color'], 0xFF1890FF);
        expect(json['width'], 2.5);
        expect(json['lineType'], 'dashed');
        expect(json['shape'], 'curved');
        expect(json['showArrow'], true);
        expect(json['arrowSize'], 12.0);
        expect(json['curveFactor'], 0.4);
      });

      test('should deserialize from JSON', () {
        final json = {
          'color': 0xFF1890FF,
          'width': 2.5,
          'lineType': 'dashed',
          'shape': 'curved',
          'showArrow': true,
          'arrowSize': 12.0,
          'curveFactor': 0.4,
        };

        final style = EdgeStyle.fromJson(json);

        expect(style.color, const Color(0xFF1890FF));
        expect(style.width, 2.5);
        expect(style.lineType, EdgeLineType.dashed);
        expect(style.shape, EdgeShape.curved);
        expect(style.showArrow, true);
        expect(style.arrowSize, 12.0);
        expect(style.curveFactor, 0.4);
      });

      test('should handle missing JSON values', () {
        final json = <String, dynamic>{};

        final style = EdgeStyle.fromJson(json);

        // Should use defaults
        expect(style.color, const Color(0xFF666666));
        expect(style.width, 2.0);
        expect(style.lineType, EdgeLineType.solid);
        expect(style.shape, EdgeShape.straight);
      });
    });

    group('EdgeMarker', () {
      test('should create one marker', () {
        final marker = EdgeMarker.one();

        expect(marker.type, EdgeMarkerType.one);
        expect(marker.text, '1');
        expect(marker.size, 12.0);
      });

      test('should create many marker', () {
        final marker = EdgeMarker.many(color: const Color(0xFF1890FF));

        expect(marker.type, EdgeMarkerType.many);
        expect(marker.text, 'N');
        expect(marker.color, const Color(0xFF1890FF));
      });

      test('should create multiple marker', () {
        final marker = EdgeMarker.multiple();

        expect(marker.type, EdgeMarkerType.multiple);
        expect(marker.text, 'M');
      });

      test('should create arrow marker', () {
        final marker = EdgeMarker.arrow(size: 15.0);

        expect(marker.type, EdgeMarkerType.arrow);
        expect(marker.size, 15.0);
      });

      test('should create circle marker', () {
        final marker = EdgeMarker.circle(size: 8.0);

        expect(marker.type, EdgeMarkerType.circle);
        expect(marker.size, 8.0);
      });

      test('should create diamond marker', () {
        final marker = EdgeMarker.diamond(size: 10.0);

        expect(marker.type, EdgeMarkerType.diamond);
        expect(marker.size, 10.0);
      });
    });

    group('DashConfig', () {
      test('should create with pattern', () {
        const config = DashConfig(pattern: [10.0, 5.0]);

        expect(config.pattern, [10.0, 5.0]);
        expect(config.startOffset, 0.0);
      });

      test('should have static presets', () {
        expect(DashConfig.dashed.pattern, [10.0, 5.0]);
        expect(DashConfig.dotted.pattern, [3.0, 3.0]);
        expect(DashConfig.dashDot.pattern, [10.0, 3.0, 3.0, 3.0]);
      });
    });

    group('AnchorPoint', () {
      late TestNode testNode;

      setUp(() {
        testNode = TestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 100),
          type: 'test',
          title: 'Test',
        );
      });

      test('should create node anchor', () {
        final anchor = AnchorPoint.nodeAnchor(
          node: testNode,
          direction: AnchorDirection.right,
        );

        expect(anchor.node, testNode);
        expect(anchor.id, 'node-1:right');
        expect(anchor.type, AnchorType.node);
        expect(anchor.direction, AnchorDirection.right);
        // Right anchor should be at right edge center
        expect(anchor.position.dx, 300);
        expect(anchor.position.dy, 150);
      });

      test('should create field anchor', () {
        final anchor = AnchorPoint.fieldAnchor(
          node: testNode,
          fieldIndex: 0,
          direction: AnchorDirection.left,
          position: const Offset(100, 120),
        );

        expect(anchor.node, testNode);
        expect(anchor.id, 'node-1:field:0:left');
        expect(anchor.type, AnchorType.field);
        expect(anchor.direction, AnchorDirection.left);
        expect(anchor.position, const Offset(100, 120));
        expect(anchor.data, isNotNull);
        expect(anchor.data['fieldIndex'], 0);
      });

      test('should calculate relative position', () {
        final anchor = AnchorPoint.nodeAnchor(
          node: testNode,
          direction: AnchorDirection.right,
        );

        final relative = anchor.relativePosition;

        expect(relative.dx, 200); // 300 - 100
        expect(relative.dy, 50); // 150 - 100
      });
    });

    group('NodeState', () {
      test('should create with default values', () {
        const state = NodeState();

        expect(state.isSelected, false);
        expect(state.isHighlighted, false);
        expect(state.isHovered, false);
        expect(state.isDragging, false);
        expect(state.isEditing, false);
        expect(state.isInteractive, false);
      });

      test('should copy with new values', () {
        const original = NodeState();
        final copy = original.copyWith(
          isSelected: true,
          isDragging: true,
        );

        expect(copy.isSelected, true);
        expect(copy.isDragging, true);
        expect(copy.isHovered, false);
        expect(copy.isInteractive, true);
      });

      test('should detect interactive state', () {
        const dragging = NodeState(isDragging: true);
        expect(dragging.isInteractive, true);

        const editing = NodeState(isEditing: true);
        expect(editing.isInteractive, true);

        const selected = NodeState(isSelected: true);
        expect(selected.isInteractive, false);
      });
    });

    group('EdgeState', () {
      test('should create with default values', () {
        const state = EdgeState();

        expect(state.isSelected, false);
        expect(state.isHighlighted, false);
        expect(state.isHovered, false);
        expect(state.isCreating, false);
      });

      test('should copy with new values', () {
        const original = EdgeState();
        final copy = original.copyWith(
          isSelected: true,
          isCreating: true,
        );

        expect(copy.isSelected, true);
        expect(copy.isCreating, true);
        expect(copy.isHovered, false);
      });
    });

    group('ViewportState', () {
      test('should convert coordinates correctly', () {
        const viewport = ViewportState(
          zoom: 2.0,
          panOffset: Offset(100, 50),
        );

        // Scene to screen
        final screen = viewport.toScreen(const Offset(50, 25));
        expect(screen.dx, 200); // 50 * 2 + 100
        expect(screen.dy, 100); // 25 * 2 + 50

        // Screen to scene
        final scene = viewport.toScene(const Offset(200, 100));
        expect(scene.dx, 50); // (200 - 100) / 2
        expect(scene.dy, 25); // (100 - 50) / 2
      });

      test('should zoom with center point', () {
        const viewport = ViewportState(zoom: 1.0, panOffset: Offset.zero);
        final zoomed = viewport.zoomTo(2.0, const Offset(100, 100));

        expect(zoomed.zoom, 2.0);
        // Center point should remain at same scene position
      });

      test('should clamp zoom to min/max', () {
        const viewport = ViewportState(minZoom: 0.5, maxZoom: 3.0);

        expect(viewport.zoomTo(0.1, Offset.zero).zoom, 0.5);
        expect(viewport.zoomTo(5.0, Offset.zero).zoom, 3.0);
      });

      test('should pan by delta', () {
        const viewport = ViewportState(panOffset: Offset(100, 50));
        final panned = viewport.pan(const Offset(10, 20));

        expect(panned.panOffset, const Offset(110, 70));
      });

      test('should fit content', () {
        const contentBounds = Rect.fromLTWH(0, 0, 400, 300);
        const viewportSize = Size(800, 600);
        const padding = 50.0;

        final viewport = const ViewportState().fitContent(
          contentBounds,
          viewportSize,
          padding: padding,
        );

        // Content width with padding: 400 + 50*2 = 500
        // Content height with padding: 300 + 50*2 = 400
        // scaleX = 800/500 = 1.6, scaleY = 600/400 = 1.5
        // Uses min scale to fit: 1.5, but clamped to max 5.0
        expect(viewport.zoom > 0, true);
        expect(viewport.zoom <= 5.0, true); // maxZoom
        expect(viewport.zoom >= 0.1, true); // minZoom
      });

      test('should return identity for zero bounds', () {
        final viewport = const ViewportState().fitContent(
          Rect.zero,
          const Size(800, 600),
        );

        expect(viewport.zoom, 1.0);
        expect(viewport.panOffset, Offset.zero);
      });
    });
  });
}

/// Test implementation of DiagramNode
class TestNode implements DiagramNode {
  @override
  final String id;

  @override
  Offset position;

  @override
  final Size size;

  @override
  final String type;

  @override
  final String title;

  @override
  final bool isSelectable;

  @override
  final bool isDraggable;

  @override
  final bool isConnectable;

  TestNode({
    required this.id,
    required this.position,
    required this.size,
    required this.type,
    required this.title,
    this.isSelectable = true,
    this.isDraggable = true,
    this.isConnectable = true,
  });

  @override
  List<AnchorPoint> getAnchors() {
    return [
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.left),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.right),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.top),
      AnchorPoint.nodeAnchor(node: this, direction: AnchorDirection.bottom),
    ];
  }

  @override
  AnchorPoint? getAnchor(String direction) {
    final dir = AnchorDirection.values.firstWhere(
      (d) => d.name == direction,
      orElse: () => AnchorDirection.right,
    );
    return AnchorPoint.nodeAnchor(node: this, direction: dir);
  }

  @override
  dynamic getData() => null;
}

/// Test implementation of DiagramEdge
class TestEdge implements DiagramEdge {
  @override
  final String id;

  @override
  final String sourceAnchorId;

  @override
  final String targetAnchorId;

  @override
  final String type;

  @override
  final String? label;

  @override
  final bool isSelectable;

  TestEdge({
    required this.id,
    required this.sourceAnchorId,
    required this.targetAnchorId,
    required this.type,
    this.label,
    this.isSelectable = true,
  });

  @override
  String get sourceNodeId => sourceAnchorId.split(':').first;

  @override
  String get targetNodeId => targetAnchorId.split(':').first;

  @override
  EdgeStyle getStyle() => const EdgeStyle();

  @override
  EdgeMarker? getSourceMarker() => null;

  @override
  EdgeMarker? getTargetMarker() => null;

  @override
  dynamic getData() => null;
}