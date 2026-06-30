/// 图表编辑器框架 - 核心抽象层
///
/// 提供通用的图表编辑基础设施，支持多种图表类型扩展
///
/// ## 架构层次
///
/// 1. **Core 层** - 核心抽象：DiagramNode, DiagramEdge, DiagramState
/// 2. **Model 层** - 数据模型：NodeModel, EdgeModel, TransformModel, GraphModel
/// 3. **Event 层** - 事件系统：DiagramEvent, EventCenter, DiagramEventTypes
/// 4. **Handler 层** - 事件处理：DiagramHandler, HandlerRegistry, 各具体处理器
/// 5. **Behavior 层** - 可复用行为：Behavior, BehaviorRegistry, 各具体行为
/// 6. **Spatial 层** - 空间索引：SpatialIndex, SimpleIndex
/// 7. **Command 层** - 命令系统：DiagramCommand, HistoryController
/// 8. **View 层** - 视图渲染：GraphView, 各 Painter
/// 9. **ER 层** - ER 图扩展：ERTableNodeModel, ERRelationEdgeModel
///
/// ## 使用方式
///
/// ### 快速开始
///
/// ```dart
/// import 'package:bkdmm/shared/diagram_editor/diagram_editor.dart';
///
/// // 使用 DiagramEditor 作为统一入口
/// final editor = DiagramEditor(
///   id: 'my-diagram',
///   diagramType: 'er-diagram',
/// );
///
/// // 添加节点
/// editor.addNode(MyNode(id: 'node-1', position: Offset(100, 100)));
///
/// // 选择节点
/// editor.selectNode('node-1');
///
/// // 撤销/重做
/// editor.executeCommand(MyCommand());
/// if (editor.canUndo) editor.undo();
///
/// // 监听事件
/// editor.eventCenter.on<NodeSelectedEvent>((e) {
///   print('Node selected: ${e.nodeId}');
/// });
///
/// // 清理
/// editor.dispose();
/// ```
///
/// ### 底层组件（高级用法）
///
/// ```dart
/// // 直接使用图模型
/// final graphModel = GraphModel();
///
/// // 直接使用事件中心
/// final eventCenter = EventCenter();
///
/// // 直接使用变换模型
/// final transform = TransformModel();
/// ```

library;

// ============================================================================
// Main Entry - 主入口类（门面 API）
// ============================================================================

export 'diagram_editor_impl.dart' show DiagramEditor;

// ============================================================================
// Core 层 - 核心抽象
// ============================================================================

export 'core/diagram_node.dart';
export 'core/diagram_edge.dart';
export 'core/diagram_state.dart' hide InteractionMode;

// ============================================================================
// Model 层 - 数据模型
// ============================================================================

export 'model/node_model.dart';
export 'model/edge_model.dart';
export 'model/transform_model.dart';
export 'model/graph_model.dart';

// ============================================================================
// Event 层 - 事件系统
// ============================================================================

export 'event/event_types.dart';
export 'event/event_center.dart';

// ============================================================================
// Handlers 层 - 事件处理
// ============================================================================

// 基础抽象
export 'handlers/diagram_event.dart';
export 'handlers/diagram_context.dart';
export 'handlers/diagram_handler.dart';
export 'handlers/handler_registry.dart';

// 具体处理器
export 'handlers/anchor_click_handler.dart';
export 'handlers/node_drag_handler.dart';
export 'handlers/selection_handler.dart';
export 'handlers/canvas_pan_handler.dart';
export 'handlers/pointer_handler.dart';

// ============================================================================
// Behavior 层 - 可复用行为
// ============================================================================

// 基础抽象
// 注意：behavior.dart 和 behavior_registry.dart 都定义了 Behavior 类
// behavior_registry.dart 中的 Behavior 是简化版本，用于注册表管理
// behavior.dart 中的 Behavior<T> 是泛型版本，用于具体行为实现
export 'behavior/behavior.dart';
export 'behavior/behavior_registry.dart' hide Behavior;

// 具体行为
// 注意：多个行为文件定义了 kPrimaryMouseButton 等鼠标按钮常量
// 以及其他重复的类型定义，使用 hide 隐藏重复定义
export 'behavior/node_drag_behavior.dart';
export 'behavior/selection_behavior.dart';
export 'behavior/connection_behavior.dart'
    hide
        kPrimaryMouseButton,
        kSecondaryMouseButton,
        kTertiaryMouseButton,
        AnchorDirection;
export 'behavior/pan_zoom_behavior.dart'
    hide
        kPrimaryMouseButton,
        kSecondaryMouseButton,
        kTertiaryMouseButton,
        TransformModel;

// ============================================================================
// Spatial 层 - 空间索引
// ============================================================================

export 'spatial/spatial_index.dart';
export 'spatial/simple_index.dart';

// ============================================================================
// Commands 层 - 命令系统
// ============================================================================

export 'commands/diagram_command.dart';
export 'commands/history_controller.dart';
export 'commands/er/er_commands.dart';

// ============================================================================
// Integration 层 - 集成管理
// ============================================================================

export 'integration/er_interaction_manager.dart'
    show InteractionMode, ERInteractionState, ERInteractionManager;
export 'integration/er_interaction_provider.dart';

// ============================================================================
// View 层 - 视图渲染
// ============================================================================

export 'view/graph_view.dart' show GraphView, GraphGridConfig, ViewportConfig, GraphEdgePainter;
export 'view/tool_overlay.dart';
export 'view/modification_overlay.dart';
export 'view/canvas_overlay.dart';

// Painter
export 'view/painter/node_painter.dart';
export 'view/painter/edge_painter.dart';
export 'view/painter/grid_painter.dart';

// ============================================================================
// ER 层 - ER 图扩展
// ============================================================================

export 'er/er_table_node_model.dart';
export 'er/er_relation_edge_model.dart';
export 'er/er_relation_painter.dart' show ERRelationPainter, ERRelationPainterConfig;

// ============================================================================
// Adapters 层 - 数据适配器
// ============================================================================

export 'adapters/er_node_adapter.dart';
export 'adapters/er_edge_adapter.dart' hide AnchorDirection;
