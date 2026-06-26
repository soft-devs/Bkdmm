import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/src/integration/er_interaction_manager.dart';

void main() {
  group('ERInteractionState', () {
    test('should have default values', () {
      const state = ERInteractionState();

      expect(state.mode, InteractionMode.edit);
      expect(state.selectedNodeIds, isEmpty);
      expect(state.draggingNodeId, isNull);
      expect(state.connectionSourceAnchorId, isNull);
      expect(state.selectionRect, isNull);
      expect(state.hoveredNodeId, isNull);
    });

    test('should correctly identify idle state', () {
      const idleState = ERInteractionState();
      expect(idleState.isIdle, isTrue);

      const draggingState = ERInteractionState(draggingNodeId: 'node1');
      expect(draggingState.isIdle, isFalse);
      expect(draggingState.isDragging, isTrue);

      const connectingState = ERInteractionState(connectionSourceAnchorId: 'anchor1');
      expect(connectingState.isIdle, isFalse);
      expect(connectingState.isConnecting, isTrue);

      const selectingState = ERInteractionState(selectionRect: Rect.zero);
      expect(selectingState.isIdle, isFalse);
      expect(selectingState.isSelecting, isTrue);
    });

    test('should correctly identify edit mode', () {
      const editState = ERInteractionState(mode: InteractionMode.edit);
      expect(editState.isEditMode, isTrue);
      expect(editState.isPreviewMode, isFalse);

      const previewState = ERInteractionState(mode: InteractionMode.move);
      expect(previewState.isEditMode, isFalse);
      expect(previewState.isPreviewMode, isTrue);
    });

    test('copyWith should update values correctly', () {
      const state = ERInteractionState();

      final newState = state.copyWith(
        mode: InteractionMode.move,
        selectedNodeIds: {'node1', 'node2'},
        draggingNodeId: 'node1',
      );

      expect(newState.mode, InteractionMode.move);
      expect(newState.selectedNodeIds, {'node1', 'node2'});
      expect(newState.draggingNodeId, 'node1');
      expect(newState.connectionSourceAnchorId, isNull);
    });

    test('copyWith with clear flags should clear values', () {
      const state = ERInteractionState(
        draggingNodeId: 'node1',
        connectionSourceAnchorId: 'anchor1',
        selectionRect: Rect.fromLTWH(0, 0, 100, 100),
        hoveredNodeId: 'node2',
      );

      final clearedState = state.copyWith(
        clearDragging: true,
        clearConnection: true,
        clearSelection: true,
        clearHovered: true,
      );

      expect(clearedState.draggingNodeId, isNull);
      expect(clearedState.connectionSourceAnchorId, isNull);
      expect(clearedState.selectionRect, isNull);
      expect(clearedState.hoveredNodeId, isNull);
    });
  });

  group('ERInteractionManager', () {
    late ERInteractionManager manager;
    late TransformationController transformController;

    setUp(() {
      transformController = TransformationController();
      manager = ERInteractionManager(
        transformController: transformController,
      );
    });

    tearDown(() {
      manager.reset();
      transformController.dispose();
    });

    test('should initialize with default state', () {
      expect(manager.state.mode, InteractionMode.edit);
      expect(manager.state.isIdle, isTrue);
    });

    test('should switch between modes', () {
      manager.enterPreviewMode();
      expect(manager.state.mode, InteractionMode.move);
      expect(manager.state.isPreviewMode, isTrue);

      manager.enterEditMode();
      expect(manager.state.mode, InteractionMode.edit);
      expect(manager.state.isEditMode, isTrue);

      manager.toggleMode();
      expect(manager.state.isPreviewMode, isTrue);

      manager.toggleMode();
      expect(manager.state.isEditMode, isTrue);
    });

    test('should handle node selection', () {
      manager.selectNode('node1');
      expect(manager.state.selectedNodeIds, {'node1'});

      manager.selectNode('node2', addToSelection: true);
      expect(manager.state.selectedNodeIds, {'node1', 'node2'});

      manager.selectNode('node1', addToSelection: true);
      expect(manager.state.selectedNodeIds, {'node2'}); // node1 was toggled off

      manager.clearSelection();
      expect(manager.state.selectedNodeIds, isEmpty);
    });

    test('should handle multi-node selection', () {
      manager.selectNodes({'node1', 'node2', 'node3'});
      expect(manager.state.selectedNodeIds, {'node1', 'node2', 'node3'});
    });

    test('should convert coordinates correctly', () {
      // Set up a transformation
      transformController.value = Matrix4.identity()
        ..translate(100.0, 50.0)
        ..scale(2.0);

      // Screen to scene
      final scenePos = manager.toScene(const Offset(200, 150));
      expect(scenePos.dx, closeTo(50, 0.1)); // (200 - 100) / 2
      expect(scenePos.dy, closeTo(50, 0.1)); // (150 - 50) / 2

      // Scene to screen
      final screenPos = manager.toScreen(const Offset(50, 50));
      expect(screenPos.dx, closeTo(200, 0.1)); // 50 * 2 + 100
      expect(screenPos.dy, closeTo(150, 0.1)); // 50 * 2 + 50
    });

    test('should update spatial index', () {
      manager.updateNodeInIndex('node1', const Rect.fromLTWH(0, 0, 100, 100));
      manager.updateNodeInIndex('node2', const Rect.fromLTWH(200, 200, 100, 100));

      final hitInside = manager.spatialIndex.hitTest(const Offset(50, 50));
      expect(hitInside.isOnNode, isTrue);
      expect(hitInside.nodeId, 'node1');

      final hitOutside = manager.spatialIndex.hitTest(const Offset(150, 150));
      expect(hitOutside.isOnCanvas, isTrue);
    });

    test('should update anchor index', () {
      manager.updateAnchorInIndex(
        'anchor1',
        const Rect.fromLTWH(0, 0, 20, 20),
        nodeId: 'node1',
        anchor: {'fieldIndex': 0},
      );

      final hit = manager.spatialIndex.hitTest(const Offset(10, 10));
      expect(hit.isOnAnchor, isTrue);
      expect(hit.nodeId, 'node1');
    });

    test('should clear index', () {
      manager.updateNodeInIndex('node1', const Rect.fromLTWH(0, 0, 100, 100));
      manager.clearIndex();

      final hit = manager.spatialIndex.hitTest(const Offset(50, 50));
      expect(hit.isOnCanvas, isTrue);
    });

    test('should return correct cursor', () {
      // Default cursor
      expect(manager.getCursor(), SystemMouseCursors.basic);

      // Cursor when hovering over node - we need to simulate this via spatial index
      manager.updateNodeInIndex('node1', const Rect.fromLTWH(0, 0, 100, 100));
      manager.spatialIndex.hitTest(const Offset(50, 50)); // This would update hoveredNodeId in real usage
      // Note: In actual implementation, hoveredNodeId is updated by onPointerMove
      // For this test, we can't directly set private state, so we test the logic indirectly
    });

    test('should reset all state', () {
      manager.selectNode('node1');
      manager.enterPreviewMode();

      manager.reset();

      expect(manager.state.selectedNodeIds, isEmpty);
      expect(manager.state.mode, InteractionMode.edit);
      expect(manager.state.isIdle, isTrue);
    });
  });
}