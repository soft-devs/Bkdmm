import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:bkdmm/shared/diagram_editor/src/commands/diagram_command.dart';
import 'package:bkdmm/shared/diagram_editor/src/commands/history_controller.dart';

void main() {
  group('DiagramCommand', () {
    group('MoveNodeCommand', () {
      test('should execute move operation', () {
        final positions = <String, Offset>{};
        final command = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );

        command.execute();

        expect(positions['node1'], const Offset(200, 200));
      });

      test('should undo move operation', () {
        final positions = <String, Offset>{};
        final command = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );

        command.execute();
        command.undo();

        expect(positions['node1'], const Offset(100, 100));
      });

      test('should redo move operation', () {
        final positions = <String, Offset>{};
        final command = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );

        command.execute();
        command.undo();
        command.redo();

        expect(positions['node1'], const Offset(200, 200));
      });

      test('should merge with same node move', () {
        final positions = <String, Offset>{};
        final command1 = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(150, 150),
          onMove: (id, pos) => positions[id] = pos,
        );
        final command2 = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(150, 150),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );

        expect(command1.canMergeWith(command2), true);

        final merged = command1.mergeWith(command2) as MoveNodeCommand;
        expect(merged.oldPosition, const Offset(100, 100));
        expect(merged.newPosition, const Offset(200, 200));
      });

      test('should not merge with different node move', () {
        final positions = <String, Offset>{};
        final command1 = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );
        final command2 = MoveNodeCommand(
          nodeId: 'node2',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );

        expect(command1.canMergeWith(command2), false);
      });

      test('should serialize to JSON', () {
        final positions = <String, Offset>{};
        final command = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
          id: 'cmd1',
        );

        final json = command.toJson();

        expect(json['nodeId'], 'node1');
        expect(json['oldPosition']['x'], 100);
        expect(json['oldPosition']['y'], 100);
        expect(json['newPosition']['x'], 200);
        expect(json['newPosition']['y'], 200);
      });
    });

    group('AddEdgeCommand', () {
      test('should execute add edge operation', () {
        final edges = <String, Map<String, String>>{};
        final command = AddEdgeCommand(
          edgeId: 'edge1',
          sourceAnchorId: 'node1:field:0:right',
          targetAnchorId: 'node2:field:0:left',
          onAdd: (id, source, target) {
            edges[id] = {'source': source, 'target': target};
          },
          onRemove: (id) => edges.remove(id),
        );

        command.execute();

        expect(edges['edge1'], isNotNull);
        expect(edges['edge1']!['source'], 'node1:field:0:right');
        expect(edges['edge1']!['target'], 'node2:field:0:left');
      });

      test('should undo add edge operation', () {
        final edges = <String, Map<String, String>>{};
        final command = AddEdgeCommand(
          edgeId: 'edge1',
          sourceAnchorId: 'node1:field:0:right',
          targetAnchorId: 'node2:field:0:left',
          onAdd: (id, source, target) {
            edges[id] = {'source': source, 'target': target};
          },
          onRemove: (id) => edges.remove(id),
        );

        command.execute();
        command.undo();

        expect(edges['edge1'], isNull);
      });
    });

    group('CompositeCommand', () {
      test('should execute all commands', () {
        final positions = <String, Offset>{};
        final edges = <String, Map<String, String>>{};

        final moveCommand = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );
        final addEdgeCommand = AddEdgeCommand(
          edgeId: 'edge1',
          sourceAnchorId: 'node1:field:0:right',
          targetAnchorId: 'node2:field:0:left',
          onAdd: (id, source, target) {
            edges[id] = {'source': source, 'target': target};
          },
          onRemove: (id) => edges.remove(id),
        );

        final composite = CompositeCommand(commands: [moveCommand, addEdgeCommand]);
        composite.execute();

        expect(positions['node1'], const Offset(200, 200));
        expect(edges['edge1'], isNotNull);
      });

      test('should undo all commands in reverse order', () {
        final positions = <String, Offset>{};
        final edges = <String, Map<String, String>>{};

        final moveCommand = MoveNodeCommand(
          nodeId: 'node1',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );
        final addEdgeCommand = AddEdgeCommand(
          edgeId: 'edge1',
          sourceAnchorId: 'node1:field:0:right',
          targetAnchorId: 'node2:field:0:left',
          onAdd: (id, source, target) {
            edges[id] = {'source': source, 'target': target};
          },
          onRemove: (id) => edges.remove(id),
        );

        final composite = CompositeCommand(commands: [moveCommand, addEdgeCommand]);
        composite.execute();
        composite.undo();

        expect(positions['node1'], const Offset(100, 100));
        expect(edges['edge1'], isNull);
      });
    });
  });

  group('HistoryController', () {
    late HistoryController controller;

    setUp(() {
      controller = HistoryController();
    });

    tearDown(() {
      controller.clear();
    });

    test('should execute command and add to undo stack', () {
      final positions = <String, Offset>{};
      final command = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command);

      expect(controller.canUndo, true);
      expect(controller.undoStackSize, 1);
    });

    test('should undo command', () {
      final positions = <String, Offset>{};
      final command = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command);
      controller.undo();

      expect(positions['node1'], const Offset(100, 100));
      expect(controller.canUndo, false);
      expect(controller.canRedo, true);
    });

    test('should redo command', () {
      final positions = <String, Offset>{};
      final command = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command);
      controller.undo();
      controller.redo();

      expect(positions['node1'], const Offset(200, 200));
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);
    });

    test('should clear redo stack on new execute', () {
      final positions = <String, Offset>{};
      final command1 = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );
      final command2 = MoveNodeCommand(
        nodeId: 'node2',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command1);
      controller.undo();
      controller.execute(command2);

      expect(controller.canRedo, false);
    });

    test('should merge consecutive move commands', () {
      final positions = <String, Offset>{};
      final command1 = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(150, 150),
        onMove: (id, pos) => positions[id] = pos,
      );
      final command2 = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(150, 150),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command1);
      controller.execute(command2);

      // 应该合并为一个命令
      expect(controller.undoStackSize, 1);

      controller.undo();
      expect(positions['node1'], const Offset(100, 100));
    });

    test('should limit history size', () {
      final positions = <String, Offset>{};
      controller = HistoryController(maxHistorySize: 5);

      for (var i = 0; i < 10; i++) {
        final command = MoveNodeCommand(
          nodeId: 'node$i',
          oldPosition: const Offset(100, 100),
          newPosition: const Offset(200, 200),
          onMove: (id, pos) => positions[id] = pos,
        );
        controller.execute(command);
      }

      expect(controller.undoStackSize, 5);
    });

    test('should notify listeners on history change', () {
      var notified = 0;
      controller.addListener(() => notified++);

      final positions = <String, Offset>{};
      final command = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
      );

      controller.execute(command);
      expect(notified, 1);

      controller.undo();
      expect(notified, 2);

      controller.redo();
      expect(notified, 3);
    });

    test('should provide undo history descriptions', () {
      final positions = <String, Offset>{};
      final command1 = MoveNodeCommand(
        nodeId: 'node1',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
        description: 'Move node1',
      );
      final command2 = MoveNodeCommand(
        nodeId: 'node2',
        oldPosition: const Offset(100, 100),
        newPosition: const Offset(200, 200),
        onMove: (id, pos) => positions[id] = pos,
        description: 'Move node2',
      );

      controller.execute(command1);
      controller.execute(command2);

      final history = controller.undoHistory;
      expect(history.length, 2);
      expect(history[0], 'Move node2');
      expect(history[1], 'Move node1');
    });
  });
}