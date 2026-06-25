# Command Pattern for Undo/Redo in Flutter

## Overview

The Command Pattern encapsulates operations as objects, enabling:
- **Undo/Redo**: Reverse any operation
- **History Tracking**: Log all user actions
- **Batch Operations**: Execute multiple commands atomically
- **Macro Recording**: Record and replay sequences

## Problem: Irreversible Operations

### Current Approach (No Undo)

```dart
// In er_diagram_ui_provider.dart
class ERDiagramUINotifier extends StateNotifier<ERDiagramUIState> {
  void moveNode(String entityId, double x, double y) {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    projectNotifier.updateGraphNode(moduleId, entityId, x, y);
    // ❌ No way to undo this!
  }

  void completeConnection(ERFieldAnchor targetAnchor) {
    // ... create edge
    projectNotifier.addGraphEdge(moduleId, edge);
    // ❌ No way to undo this!
  }
}
```

**Issues:**
1. Users cannot recover from mistakes
2. No operation history for debugging
3. Cannot implement "revert to version X" feature
4. Testing is harder (no operation replay)

## Solution: Command Pattern

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          User Action                                 │
│              (e.g., drag node, create connection)                    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Command Creation                              │
│                                                                      │
│  final command = MoveNodeCommand(                                   │
│    nodeId: 'table1',                                                │
│    oldPosition: Offset(100, 100),                                   │
│    newPosition: Offset(200, 150),                                   │
│  );                                                                 │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       HistoryController                             │
│                                                                      │
│  ┌────────────────┐    ┌────────────────┐                          │
│  │  Undo Stack    │    │  Redo Stack    │                          │
│  │  ────────────  │    │  ────────────  │                          │
│  │  MoveNode #1   │    │  (empty)       │                          │
│  │  AddEdge #2    │    │                │                          │
│  │  DeleteNode #3 │    │                │                          │
│  └────────────────┘    └────────────────┘                          │
│                                                                      │
│  execute(command) → runs command, adds to undo stack                │
│  undo() → pops from undo stack, runs undo(), adds to redo           │
│  redo() → pops from redo stack, runs execute(), adds to undo        │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       State Update                                  │
│              (via ProjectNotifier)                                   │
└─────────────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. DiagramCommand Interface

```dart
/// lib/shared/diagram_editor/commands/diagram_command.dart

/// Base interface for all diagram commands
abstract class DiagramCommand {
  /// Unique identifier for this command instance
  String get id;

  /// Human-readable description for UI (e.g., "Move node 'User'")
  String get description;

  /// Execute the command (perform the action)
  void execute();

  /// Undo the command (reverse the action)
  void undo();

  /// Redo the command (re-execute after undo)
  /// Default implementation calls execute(), but can be overridden
  void redo() => execute();

  /// Timestamp when command was created
  DateTime get timestamp;

  /// Whether this command can be merged with another
  /// Used for continuous operations like dragging
  bool canMergeWith(DiagramCommand other) => false;

  /// Merge another command into this one
  /// Returns a new combined command
  DiagramCommand mergeWith(DiagramCommand other) {
    throw UnsupportedError('This command does not support merging');
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Create from JSON (factory constructor in subclasses)
  // static DiagramCommand fromJson(Map<String, dynamic> json) { ... }
}
```

#### 2. HistoryController

```dart
/// lib/shared/diagram_editor/controllers/history_controller.dart

class HistoryController {
  /// Undo stack (most recent at end)
  final List<DiagramCommand> _undoStack = [];

  /// Redo stack (most recent at end)
  final List<DiagramCommand> _redoStack = [];

  /// Maximum history size
  final int maxHistorySize;

  /// Stream of history changes (for UI updates)
  final _historyChanges = StreamController<void>.broadcast();
  Stream<void> get historyChanges => _historyChanges.stream;

  HistoryController({this.maxHistorySize = 50});

  /// Whether undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of undoable operations
  int get undoCount => _undoStack.length;

  /// Number of redoable operations
  int get redoCount => _redoStack.length;

  /// Execute a command and add to history
  void execute(DiagramCommand command) {
    // Try to merge with previous command if possible
    if (_undoStack.isNotEmpty) {
      final lastCommand = _undoStack.last;
      if (lastCommand.canMergeWith(command)) {
        _undoStack.removeLast();
        _undoStack.add(lastCommand.mergeWith(command));
        command.execute();
        _historyChanges.add(null);
        return;
      }
    }

    // Execute and add to undo stack
    command.execute();
    _undoStack.add(command);

    // Limit history size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    // Clear redo stack (new action invalidates redo)
    _redoStack.clear();

    _historyChanges.add(null);
  }

  /// Undo the last command
  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    _historyChanges.add(null);
  }

  /// Redo the last undone command
  void redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    command.redo();
    _undoStack.add(command);

    _historyChanges.add(null);
  }

  /// Undo multiple commands
  void undoMultiple(int count) {
    for (var i = 0; i < count && canUndo; i++) {
      undo();
    }
  }

  /// Redo multiple commands
  void redoMultiple(int count) {
    for (var i = 0; i < count && canRedo; i++) {
      redo();
    }
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _historyChanges.add(null);
  }

  /// Get undo history for display (e.g., in a dropdown menu)
  List<DiagramCommand> getUndoHistory() => List.unmodifiable(_undoStack);

  /// Get redo history for display
  List<DiagramCommand> getRedoHistory() => List.unmodifiable(_redoStack.reversed);

  /// Undo all commands up to a specific point
  void undoTo(DiagramCommand command) {
    final index = _undoStack.indexOf(command);
    if (index >= 0) {
      undoMultiple(_undoStack.length - index);
    }
  }

  void dispose() {
    _historyChanges.close();
  }
}
```

### Concrete Commands

#### MoveNodeCommand

```dart
/// lib/shared/diagram_editor/commands/move_node_command.dart

class MoveNodeCommand extends DiagramCommand {
  final String moduleId;
  final String nodeId;
  final Offset oldPosition;
  final Offset newPosition;
  final void Function(String moduleId, String nodeId, Offset position) updatePosition;

  final String _id;
  final DateTime _timestamp;

  MoveNodeCommand({
    required this.moduleId,
    required this.nodeId,
    required this.oldPosition,
    required this.newPosition,
    required this.updatePosition,
    String? id,
    DateTime? timestamp,
  }) : _id = id ?? const Uuid().v4(),
       _timestamp = timestamp ?? DateTime.now();

  @override
  String get id => _id;

  @override
  String get description => 'Move node "$nodeId" to (${newPosition.dx.toStringAsFixed(0)}, ${newPosition.dy.toStringAsFixed(0)})';

  @override
  DateTime get timestamp => _timestamp;

  @override
  void execute() {
    updatePosition(moduleId, nodeId, newPosition);
  }

  @override
  void undo() {
    updatePosition(moduleId, nodeId, oldPosition);
  }

  @override
  bool canMergeWith(DiagramCommand other) {
    // Merge with another move of the same node within a short time
    if (other is! MoveNodeCommand) return false;
    if (other.nodeId != nodeId) return false;
    if (other.moduleId != moduleId) return false;
    // Only merge if commands are close in time (within 500ms)
    return other.timestamp.difference(timestamp).inMilliseconds.abs() < 500;
  }

  @override
  DiagramCommand mergeWith(DiagramCommand other) {
    if (other is! MoveNodeCommand) {
      throw ArgumentError('Cannot merge with non-MoveNodeCommand');
    }
    return MoveNodeCommand(
      moduleId: moduleId,
      nodeId: nodeId,
      oldPosition: oldPosition, // Keep original start position
      newPosition: other.newPosition, // Use latest end position
      updatePosition: updatePosition,
      timestamp: other.timestamp, // Use latest timestamp
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'MoveNodeCommand',
    'id': _id,
    'moduleId': moduleId,
    'nodeId': nodeId,
    'oldPosition': {'x': oldPosition.dx, 'y': oldPosition.dy},
    'newPosition': {'x': newPosition.dx, 'y': newPosition.dy},
    'timestamp': _timestamp.toIso8601String(),
  };

  factory MoveNodeCommand.fromJson(
    Map<String, dynamic> json,
    void Function(String, String, Offset) updatePosition,
  ) {
    return MoveNodeCommand(
      id: json['id'],
      moduleId: json['moduleId'],
      nodeId: json['nodeId'],
      oldPosition: Offset(json['oldPosition']['x'], json['oldPosition']['y']),
      newPosition: Offset(json['newPosition']['x'], json['newPosition']['y']),
      timestamp: DateTime.parse(json['timestamp']),
      updatePosition: updatePosition,
    );
  }
}
```

#### AddEdgeCommand

```dart
/// lib/shared/diagram_editor/commands/add_edge_command.dart

class AddEdgeCommand extends DiagramCommand {
  final String moduleId;
  final GraphEdge edge;
  final void Function(String moduleId, GraphEdge edge) addEdge;
  final void Function(String moduleId, String edgeId) removeEdge;

  final String _id;
  final DateTime _timestamp;

  AddEdgeCommand({
    required this.moduleId,
    required this.edge,
    required this.addEdge,
    required this.removeEdge,
    String? id,
    DateTime? timestamp,
  }) : _id = id ?? const Uuid().v4(),
       _timestamp = timestamp ?? DateTime.now();

  @override
  String get id => _id;

  @override
  String get description => 'Create connection: ${edge.source} → ${edge.target}';

  @override
  DateTime get timestamp => _timestamp;

  @override
  void execute() {
    addEdge(moduleId, edge);
  }

  @override
  void undo() {
    removeEdge(moduleId, edge.id);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'AddEdgeCommand',
    'id': _id,
    'moduleId': moduleId,
    'edge': edge.toJson(),
    'timestamp': _timestamp.toIso8601String(),
  };
}
```

#### DeleteElementsCommand

```dart
/// lib/shared/diagram_editor/commands/delete_elements_command.dart

class DeleteElementsCommand extends DiagramCommand {
  final String moduleId;
  final List<String> nodeIds;
  final List<String> edgeIds;
  final Map<String, DiagramNode> deletedNodes; // Store deleted data for undo
  final Map<String, DiagramEdge> deletedEdges;
  final void Function(String moduleId, String nodeId) deleteNode;
  final void Function(String moduleId, String edgeId) deleteEdge;
  final void Function(String moduleId, DiagramNode node) addNode;
  final void Function(String moduleId, DiagramEdge edge) addEdge;

  final String _id;
  final DateTime _timestamp;

  DeleteElementsCommand({
    required this.moduleId,
    required this.nodeIds,
    required this.edgeIds,
    required this.deletedNodes,
    required this.deletedEdges,
    required this.deleteNode,
    required this.deleteEdge,
    required this.addNode,
    required this.addEdge,
    String? id,
    DateTime? timestamp,
  }) : _id = id ?? const Uuid().v4(),
       _timestamp = timestamp ?? DateTime.now();

  @override
  String get id => _id;

  @override
  String get description {
    final parts = <String>[];
    if (nodeIds.isNotEmpty) parts.add('${nodeIds.length} nodes');
    if (edgeIds.isNotEmpty) parts.add('${edgeIds.length} edges');
    return 'Delete ${parts.join(', ')}';
  }

  @override
  DateTime get timestamp => _timestamp;

  @override
  void execute() {
    // Delete edges first (they reference nodes)
    for (final edgeId in edgeIds) {
      deleteEdge(moduleId, edgeId);
    }
    // Then delete nodes
    for (final nodeId in nodeIds) {
      deleteNode(moduleId, nodeId);
    }
  }

  @override
  void undo() {
    // Restore nodes first
    for (final entry in deletedNodes.entries) {
      addNode(moduleId, entry.value);
    }
    // Then restore edges
    for (final entry in deletedEdges.entries) {
      addEdge(moduleId, entry.value);
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'DeleteElementsCommand',
    'id': _id,
    'moduleId': moduleId,
    'nodeIds': nodeIds,
    'edgeIds': edgeIds,
    'deletedNodes': deletedNodes.map((k, v) => MapEntry(k, v.toJson())),
    'deletedEdges': deletedEdges.map((k, v) => MapEntry(k, v.toJson())),
    'timestamp': _timestamp.toIso8601String(),
  };
}
```

#### CompositeCommand (Batch Operations)

```dart
/// lib/shared/diagram_editor/commands/composite_command.dart

/// A command that contains multiple sub-commands
/// All sub-commands are executed/undone together
class CompositeCommand extends DiagramCommand {
  final List<DiagramCommand> commands;
  final String _description;

  final String _id;
  final DateTime _timestamp;

  CompositeCommand({
    required this.commands,
    String? description,
    String? id,
    DateTime? timestamp,
  }) : _description = description ?? 'Composite (${commands.length} operations)',
       _id = id ?? const Uuid().v4(),
       _timestamp = timestamp ?? DateTime.now();

  @override
  String get id => _id;

  @override
  String get description => _description;

  @override
  DateTime get timestamp => _timestamp;

  @override
  void execute() {
    for (final command in commands) {
      command.execute();
    }
  }

  @override
  void undo() {
    // Undo in reverse order
    for (final command in commands.reversed) {
      command.undo();
    }
  }

  @override
  void redo() {
    // Redo in original order
    for (final command in commands) {
      command.redo();
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'CompositeCommand',
    'id': _id,
    'description': _description,
    'commands': commands.map((c) => c.toJson()).toList(),
    'timestamp': _timestamp.toIso8601String(),
  };

  /// Create a composite command for moving multiple nodes
  static CompositeCommand moveNodes({
    required String moduleId,
    required Map<String, (Offset, Offset)> movements, // nodeId -> (oldPos, newPos)
    required void Function(String, String, Offset) updatePosition,
  }) {
    final commands = movements.entries.map((entry) {
      return MoveNodeCommand(
        moduleId: moduleId,
        nodeId: entry.key,
        oldPosition: entry.value.$1,
        newPosition: entry.value.$2,
        updatePosition: updatePosition,
      );
    }).toList();

    return CompositeCommand(
      commands: commands,
      description: 'Move ${movements.length} nodes',
    );
  }
}
```

### Integration with Riverpod

```dart
/// lib/shared/diagram_editor/providers/history_provider.dart

/// History controller provider (singleton per diagram)
final historyControllerProvider = Provider.family<HistoryController, String>((ref, diagramId) {
  final controller = HistoryController(maxHistorySize: 50);

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Provider for undo availability
final canUndoProvider = Provider.family<bool, String>((ref, diagramId) {
  final controller = ref.watch(historyControllerProvider(diagramId));
  return controller.canUndo;
});

/// Provider for redo availability
final canRedoProvider = Provider.family<bool, String>((ref, diagramId) {
  final controller = ref.watch(historyControllerProvider(diagramId));
  return controller.canRedo;
});
```

### Integration with DiagramCanvas

```dart
/// lib/shared/diagram_editor/core/diagram_canvas.dart (enhanced)

abstract class DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  late final HistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = ref.read(historyControllerProvider(widget.diagramId));

    // Listen to keyboard shortcuts
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlLeft);

    if (isCtrlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.shiftLeft);
        if (isShiftPressed) {
          _historyController.redo();
        } else {
          _historyController.undo();
        }
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyY) {
        _historyController.redo();
        return true;
      }
    }

    return false;
  }

  /// Execute a command with history tracking
  void executeCommand(DiagramCommand command) {
    _historyController.execute(command);
  }
}
```

### Usage in ER Diagram

```dart
/// lib/features/modeling/er_diagram/er_diagram_canvas.dart

class _ERDiagramCanvasState extends DiagramCanvasState {
  // ... other methods

  void _handleNodeDragEnd(String nodeId, Offset endPosition) {
    final node = ref.read(projectNotifierProvider).project
        ?.modules.firstWhere((m) => m.id == widget.diagramId)
        .graphCanvas.nodes.firstWhere((n) => n.moduleName == nodeId);

    if (node == null) return;

    final command = MoveNodeCommand(
      moduleId: widget.diagramId,
      nodeId: nodeId,
      oldPosition: Offset(node.x, node.y),
      newPosition: endPosition,
      updatePosition: _updateNodePosition,
    );

    executeCommand(command);
  }

  void _updateNodePosition(String moduleId, String nodeId, Offset position) {
    ref.read(projectNotifierProvider.notifier)
        .updateGraphNode(moduleId, nodeId, position.dx, position.dy);
  }

  void _handleConnectionComplete(String sourceAnchorId, String targetAnchorId) {
    final sourceAnchor = _parseAnchor(sourceAnchorId);
    final targetAnchor = _parseAnchor(targetAnchorId);

    final edge = GraphEdge(
      source: sourceAnchor.nodeId,
      target: targetAnchor.nodeId,
      sourceField: sourceAnchor.fieldIndex.toString(),
      targetField: targetAnchor.fieldIndex.toString(),
      relationType: '1:N',
    );

    final command = AddEdgeCommand(
      moduleId: widget.diagramId,
      edge: edge,
      addEdge: _addEdge,
      removeEdge: _removeEdge,
    );

    executeCommand(command);
  }

  void _addEdge(String moduleId, GraphEdge edge) {
    ref.read(projectNotifierProvider.notifier).addGraphEdge(moduleId, edge);
  }

  void _removeEdge(String moduleId, String edgeId) {
    ref.read(projectNotifierProvider.notifier).removeGraphEdge(moduleId, edgeId);
  }
}
```

### UI: Undo/Redo Toolbar

```dart
/// lib/shared/diagram_editor/widgets/diagram_toolbar.dart

class DiagramToolbar extends ConsumerWidget {
  final String diagramId;

  const DiagramToolbar({required this.diagramId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider(diagramId));
    final canRedo = ref.watch(canRedoProvider(diagramId));
    final history = ref.watch(historyControllerProvider(diagramId));

    return Row(
      children: [
        // Undo button
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo (Ctrl+Z)',
          onPressed: canUndo ? () => history.undo() : null,
        ),

        // Redo button
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo (Ctrl+Y)',
          onPressed: canRedo ? () => history.redo() : null,
        ),

        // History dropdown (optional)
        PopupMenuButton<DiagramCommand>(
          icon: const Icon(Icons.history),
          tooltip: 'History',
          enabled: history.undoCount > 0,
          itemBuilder: (context) {
            return history.getUndoHistory().reversed.map((cmd) {
              return PopupMenuItem(
                value: cmd,
                child: Text(cmd.description),
              );
            }).toList();
          },
          onSelected: (cmd) {
            history.undoTo(cmd);
          },
        ),
      ],
    );
  }
}
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `Ctrl+Y` | Redo (alternative) |
| `Ctrl+A` | Select all |
| `Delete` | Delete selected |
| `Escape` | Cancel current operation |

## Persistence

Commands can be serialized for:
- Saving operation history to disk
- Replaying operations from a file
- Collaborative editing (send commands over network)

```dart
// Save history to file
final historyJson = historyController.getUndoHistory()
    .map((c) => c.toJson())
    .toList();
await File('history.json').writeAsString(jsonEncode(historyJson));

// Load and replay
final historyJson = jsonDecode(await File('history.json').readAsString());
for (final cmdJson in historyJson) {
  final command = CommandFactory.fromJson(cmdJson);
  historyController.execute(command);
}
```

## References

- [Command Pattern - Refactoring Guru](https://refactoring.guru/design-patterns/command)
- [Undo/Redo in Flutter](https://blog.csdn.net/...)
- [Memento Pattern](https://refactoring.guru/design-patterns/memento)

---

*Document Version: 1.0*
*Last Updated: 2025-06-25*