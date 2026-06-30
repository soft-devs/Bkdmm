/// ER 图控制器
///
/// 包装 [DiagramEditor]，为 ER 图提供专门的 API，
/// 集成命令系统和项目数据同步。
library;

import 'dart:async';
import 'dart:ui';

import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/anchor_click_handler.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/node_drag_handler.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/selection_handler.dart';
import 'package:bkdmm/shared/diagram_editor/handlers/canvas_pan_handler.dart';
import 'package:bkdmm/shared/models/module.dart';
import 'package:bkdmm/features/project/providers/project_notifier.dart';
import '../models/er_diagram_ui_state.dart';

/// ER 图控制器
///
/// 作为 ER 图与 diagram_editor 框架的桥梁，提供：
/// - 数据同步：将 DiagramEditor 的变更同步到 ProjectNotifier
/// - 命令包装：使用命令系统包装所有变更操作，支持撤销/重做
/// - 事件监听：监听 DiagramEditor 事件并触发外部回调
///
/// ## 使用示例
///
/// ```dart
/// // 在 Provider 中创建
/// final controller = ERDiagramController(
///   editor: DiagramEditor(diagramType: 'er-diagram'),
///   projectNotifier: ref.read(projectNotifierProvider.notifier),
///   moduleId: module.id,
/// );
///
/// // 移动节点
/// controller.moveNode(entityId, newPosition);
///
/// // 撤销
/// controller.undo();
///
/// // 重做
/// controller.redo();
/// ```
class ERDiagramController {
  /// DiagramEditor 实例
  final DiagramEditor editor;

  /// ProjectNotifier 实例（用于同步数据）
  final ProjectNotifier _projectNotifier;

  /// 模块 ID
  final String moduleId;

  /// 状态变更监听器
  final List<VoidCallback> _stateListeners = [];

  /// 状态变更流控制器
  final StreamController<DiagramState> _stateController =
      StreamController<DiagramState>.broadcast();

  /// 是否已初始化
  bool _initialized = false;

  /// 创建 ER 图控制器
  ERDiagramController({
    required this.editor,
    required ProjectNotifier projectNotifier,
    required this.moduleId,
  }) : _projectNotifier = projectNotifier;

  /// 获取当前状态
  DiagramState get state => editor.state;

  /// 状态变更流
  Stream<DiagramState> get stateStream => _stateController.stream;

  /// 是否可以撤销
  bool get canUndo => editor.canUndo;

  /// 是否可以重做
  bool get canRedo => editor.canRedo;

  /// 撤销历史描述
  List<String> get undoHistory => editor.undoHistory;

  /// 重做历史描述
  List<String> get redoHistory => editor.redoHistory;

  /// 当前交互模式
  ERInteractionMode get interactionMode => _convertInteractionMode(editor.interactionMode);

  /// 转换交互模式
  ERInteractionMode _convertInteractionMode(InteractionMode mode) {
    switch (mode) {
      case InteractionMode.edit:
        return ERInteractionMode.edit;
      case InteractionMode.move:
        return ERInteractionMode.preview;
      case InteractionMode.readonly:
        return ERInteractionMode.preview;
    }
  }

  /// 初始化控制器
  ///
  /// 从项目数据加载初始节点和边，设置事件监听。
  void initialize(Module module) {
    if (_initialized) return;

    // 注册事件处理器（激活框架 Handler 系统）
    editor.registerHandlers([
      AnchorClickHandler(priority: 10),
      ConnectionHandler(priority: 30),
      NodeDragHandler(priority: 20),
      SelectionHandler(priority: 50),
      CanvasPanHandler(priority: 100),
    ]);

    // 加载节点
    final nodes = ERNodeAdapter.fromModule(module);
    for (final node in nodes) {
      editor.addNode(node);
    }

    // 加载边
    final edges = EREdgeAdapter.fromModule(module);
    for (final edge in edges) {
      editor.addEdge(edge);
    }

    // 设置事件监听
    _setupEventListeners();

    // 订阅 DiagramEditor 状态变更
    editor.subscribeToStateChanges(_onEditorStateChange);

    _initialized = true;
  }

  /// 设置事件监听
  void _setupEventListeners() {
    // 监听拖拽结束事件，同步位置到项目
    editor.eventCenter.on<DragEndedEvent>((event) {
      _syncNodePosition(event.nodeId);
    });

    // 监听连线完成事件，同步连线到项目
    editor.eventCenter.on<ConnectionCompletedEvent>((event) {
      // 从锚点 ID 生成边 ID
      final edgeId = _generateEdgeId(event.sourceAnchorId, event.targetAnchorId);
      _syncEdgeToProject(edgeId);
    });

    // 监听节点编辑请求事件
    editor.eventCenter.on<NodeEditorRequestedEvent>((event) {
      onEntityEditRequest?.call(event.nodeId);
    });

    // 监听上下文菜单请求事件
    editor.eventCenter.on<ContextMenuRequestedEvent>((event) {
      onContextMenuRequest?.call(event.position, event.nodeId);
    });
  }

  /// 处理 DiagramEditor 状态变更
  void _onEditorStateChange() {
    // 通知所有监听器
    for (final listener in _stateListeners) {
      listener();
    }

    // 发送到流
    _stateController.add(state);
  }

  // ===========================================================================
  // 节点操作
  // ===========================================================================

  /// 移动节点
  ///
  /// 使用命令系统包装，支持撤销。
  void moveNode(String entityId, Offset newPosition) {
    final node = editor.getNode(entityId);
    if (node == null) return;

    final command = MoveNodeCommand(
      nodeId: entityId,
      oldPosition: node.position,
      newPosition: newPosition,
      onMove: (id, pos) {
        editor.updateNode(id, (n) {
          if (n is ERTableNodeModel) {
            return n.copyWith(position: pos);
          }
          return n;
        });
        _syncNodePositionToProject(id, pos);
      },
    );

    editor.executeCommand(command);
  }

  /// 批量移动节点
  ///
  /// 使用复合命令包装，支持撤销。
  void moveNodes(Map<String, Offset> positions) {
    final commands = <DiagramCommand>[];

    for (final entry in positions.entries) {
      final node = editor.getNode(entry.key);
      if (node == null) continue;

      commands.add(MoveNodeCommand(
        nodeId: entry.key,
        oldPosition: node.position,
        newPosition: entry.value,
        onMove: (id, pos) {
          editor.updateNode(id, (n) {
            if (n is ERTableNodeModel) {
              return n.copyWith(position: pos);
            }
            return n;
          });
          _syncNodePositionToProject(id, pos);
        },
      ));
    }

    if (commands.isEmpty) return;

    final compositeCommand = CompositeCommand(commands: commands);
    editor.executeCommand(compositeCommand);
  }

  /// 选择节点
  void selectNode(String entityId, {bool addToSelection = false}) {
    editor.selectNode(entityId, addToSelection: addToSelection);
  }

  /// 取消选择节点
  void deselectNode(String entityId) {
    editor.deselectNode(entityId);
  }

  /// 清空选择
  void clearSelection() {
    editor.clearSelection();
  }

  /// 获取选中的节点 ID
  Set<String> get selectedNodeIds => editor.selectedNodeIds;

  // ===========================================================================
  // 连线操作
  // ===========================================================================

  /// 开始连线
  void startConnection(String anchorId, String nodeId, Offset position) {
    editor.eventCenter.emit(ConnectionStartedEvent(
      sourceAnchorId: anchorId,
      sourceNodeId: nodeId,
      position: position,
    ));
  }

  /// 更新连线预览
  void updateConnectionPreview(Offset position) {
    editor.eventCenter.emit(ConnectionPreviewUpdatedEvent(position));
  }

  /// 完成连线
  void completeConnection(String targetAnchorId, String targetNodeId) {
    final sourceAnchorId = state.interaction.connectionSourceAnchorId ?? '';
    editor.eventCenter.emit(ConnectionCompletedEvent(
      sourceAnchorId: sourceAnchorId,
      targetAnchorId: targetAnchorId,
      sourceNodeId: _extractNodeId(sourceAnchorId),
      targetNodeId: targetNodeId,
    ));
  }

  /// 取消连线
  void cancelConnection() {
    editor.eventCenter.emit(const ConnectionCancelledEvent());
  }

  /// 从锚点 ID 提取节点 ID
  String _extractNodeId(String anchorId) {
    final parts = anchorId.split(':');
    return parts.first;
  }

  /// 添加关系
  ///
  /// 使用命令系统包装，支持撤销。
  void addRelation(ERRelationEdgeModel relation) {
    final command = AddEdgeCommand(
      edgeId: relation.id,
      sourceAnchorId: relation.sourceAnchorId,
      targetAnchorId: relation.targetAnchorId,
      onAdd: (id, source, target) {
        editor.addEdge(relation);
        _syncEdgeToProject(id);
      },
      onRemove: (id) {
        editor.removeEdge(id);
        _removeEdgeFromProject(id);
      },
    );

    editor.executeCommand(command);
  }

  /// 删除关系
  void removeRelation(String edgeId) {
    final edge = editor.getEdge(edgeId);
    if (edge == null) return;

    editor.removeEdge(edgeId);
    _removeEdgeFromProject(edgeId);
  }

  // ===========================================================================
  // 视口操作
  // ===========================================================================

  /// 缩放到指定级别
  void zoomTo(double zoom, {Offset? center}) {
    editor.zoomTo(zoom, center: center);
  }

  /// 放大
  void zoomIn({Offset? center}) {
    editor.zoomIn(center: center);
  }

  /// 缩小
  void zoomOut({Offset? center}) {
    editor.zoomOut(center: center);
  }

  /// 平移画布
  void pan(Offset delta) {
    editor.pan(delta);
  }

  /// 平移到指定位置
  void panTo(Offset offset) {
    editor.panTo(offset);
  }

  /// 适应内容
  void fitContent({double padding = 50.0, Size? viewportSize}) {
    editor.fitContent(padding: padding, viewportSize: viewportSize);
  }

  /// 重置视口
  void resetViewport() {
    editor.resetViewport();
  }

  /// 屏幕坐标转场景坐标
  Offset toScene(Offset screen) {
    return editor.toScene(screen);
  }

  /// 场景坐标转屏幕坐标
  Offset toScreen(Offset scene) {
    return editor.toScreen(scene);
  }

  // ===========================================================================
  // 交互模式
  // ===========================================================================

  /// 设置交互模式
  void setInteractionMode(ERInteractionMode mode) {
    editor.setInteractionMode(_toDiagramInteractionMode(mode));
  }

  /// 进入编辑模式
  void enterEditMode() {
    editor.enterEditMode();
  }

  /// 进入预览模式
  void enterMoveMode() {
    editor.enterMoveMode();
  }

  /// 切换交互模式
  void toggleMode() {
    editor.toggleMode();
  }

  /// 转换 ERInteractionMode 到 DiagramEditor 的 InteractionMode
  InteractionMode _toDiagramInteractionMode(ERInteractionMode mode) {
    switch (mode) {
      case ERInteractionMode.edit:
        return InteractionMode.edit;
      case ERInteractionMode.preview:
        return InteractionMode.move;
    }
  }

  // ===========================================================================
  // 撤销/重做
  // ===========================================================================

  /// 撤销
  void undo() {
    editor.undo();
  }

  /// 重做
  void redo() {
    editor.redo();
  }

  /// 清空历史
  void clearHistory() {
    editor.clearHistory();
  }

  // ===========================================================================
  // 数据同步
  // ===========================================================================

  /// 同步节点位置到项目
  void _syncNodePosition(String entityId) {
    final node = editor.getNode(entityId);
    if (node == null) return;

    _syncNodePositionToProject(entityId, node.position);
  }

  /// 同步节点位置到 ProjectNotifier
  void _syncNodePositionToProject(String entityId, Offset position) {
    _projectNotifier.updateGraphNode(
      moduleId,
      entityId,
      position.dx,
      position.dy,
    );
  }

  /// 同步连线到项目
  void _syncEdgeToProject(String edgeId) {
    final edge = editor.getEdge(edgeId);
    if (edge == null || edge is! ERRelationEdgeModel) return;

    // 获取实体标题映射
    final project = _projectNotifier.state.project;
    if (project == null) return;

    final module = project.modules.firstWhere((m) => m.id == moduleId);
    final entityIdToTitleMap = <String, String>{};
    for (final entity in module.entities) {
      entityIdToTitleMap[entity.id] = entity.title;
    }

    final graphEdge = EREdgeAdapter.toGraphEdge(
      edge,
      entityIdToTitleMap[edge.sourceEntityId] ?? '',
      entityIdToTitleMap[edge.targetEntityId] ?? '',
    );

    _projectNotifier.addGraphEdge(moduleId, graphEdge);
  }

  /// 从项目删除连线
  void _removeEdgeFromProject(String edgeId) {
    final edge = editor.getEdge(edgeId);
    if (edge == null) return;

    _projectNotifier.removeGraphEdge(
      moduleId,
      edge.sourceNodeId,
      edge.targetNodeId,
    );
  }

  /// 生成边 ID
  String _generateEdgeId(String sourceAnchorId, String targetAnchorId) {
    // 从锚点 ID 提取节点 ID 和字段索引
    final sourceParts = sourceAnchorId.split(':');
    final targetParts = targetAnchorId.split(':');

    final sourceNodeId = sourceParts.first;
    final targetNodeId = targetParts.first;

    String sourceField = 'node';
    String targetField = 'node';

    if (sourceParts.length >= 3 && sourceParts[1] == 'field') {
      sourceField = sourceParts[2];
    }
    if (targetParts.length >= 3 && targetParts[1] == 'field') {
      targetField = targetParts[2];
    }

    return '${sourceNodeId}_${targetNodeId}_${sourceField}_${targetField}';
  }

  // ===========================================================================
  // 回调
  // ===========================================================================

  /// 实体编辑请求回调
  ///
  /// 双击节点时触发，参数为实体 ID。
  void Function(String entityId)? onEntityEditRequest;

  /// 实体预览请求回调
  ///
  /// 预览模式下双击节点时触发。
  void Function(String entityId)? onEntityPreviewRequest;

  /// 上下文菜单请求回调
  ///
  /// 右键点击时触发，参数为位置和可选的实体 ID。
  void Function(Offset position, String? entityId)? onContextMenuRequest;

  // ===========================================================================
  // 状态监听
  // ===========================================================================

  /// 订阅状态变更
  VoidCallback subscribeToStateChanges(VoidCallback listener) {
    _stateListeners.add(listener);
    return () => _stateListeners.remove(listener);
  }

  // ===========================================================================
  // 生命周期
  // ===========================================================================

  /// 释放资源
  void dispose() {
    _stateListeners.clear();
    _stateController.close();
    editor.dispose();
  }
}