/// 图表编辑器框架 - 核心抽象层
///
/// 提供通用的图表编辑基础设施，支持多种图表类型扩展

library;

// Core exports
export 'src/core/diagram_node.dart';
export 'src/core/diagram_edge.dart';
export 'src/core/diagram_state.dart' hide InteractionMode;

// Handlers (Phase 1-2)
export 'src/handlers/diagram_event.dart';
export 'src/handlers/diagram_context.dart';
export 'src/handlers/diagram_handler.dart';
export 'src/handlers/handler_registry.dart';
export 'src/handlers/anchor_click_handler.dart';
export 'src/handlers/node_drag_handler.dart';
export 'src/handlers/selection_handler.dart';
export 'src/handlers/canvas_pan_handler.dart';

// Model
export 'src/model/node_model.dart';
export 'src/model/edge_model.dart';
export 'src/model/transform_model.dart';

// Spatial (Phase 1)
export 'src/spatial/spatial_index.dart';
export 'src/spatial/simple_index.dart';

// Commands (Phase 3)
export 'src/commands/diagram_command.dart';
export 'src/commands/history_controller.dart';

// Integration (Phase 4)
export 'src/integration/er_interaction_manager.dart' show InteractionMode, ERInteractionState, ERInteractionManager;
export 'src/integration/er_interaction_provider.dart';

// View (Phase 5)
export 'src/view/tool_overlay.dart';
