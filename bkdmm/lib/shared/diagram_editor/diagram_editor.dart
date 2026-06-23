/// 图表编辑器框架 - 核心抽象层
///
/// 提供通用的图表编辑基础设施，支持多种图表类型扩展

library diagram_editor;

// Core exports
export 'src/core/diagram_node.dart';
export 'src/core/diagram_edge.dart';
export 'src/core/diagram_canvas.dart';
export 'src/core/diagram_state.dart';

// Controllers (TODO: implement these controllers)
// export 'src/controllers/viewport_controller.dart';
// export 'src/controllers/selection_controller.dart';
// export 'src/controllers/gesture_handler.dart';
// export 'src/controllers/history_manager.dart';

// Layout
export 'src/layout/layout_engine.dart';
export 'src/layout/graphview_layout.dart';

// Render
export 'src/render/renderers.dart';
export 'src/render/anchor_renderer.dart';