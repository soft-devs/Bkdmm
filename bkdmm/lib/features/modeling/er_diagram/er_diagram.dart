/// ER 图编辑器
///
/// 使用 graphview 库实现：
/// - GraphView widget 提供图表渲染和交互
/// - SugiyamaAlgorithm 提供层次布局
/// - 自定义 NodeWidgetBuilder 和 EdgeRenderer 实现 ER 特定渲染
/// - 字段级锚点支持字段间连线

library er_diagram;

// 新版模型和 Provider（重构后）
export 'models/er_diagram_ui_state.dart';
export 'providers/er_diagram_ui_provider.dart';

// 新版画布和 Widget（重构后）
export 'widgets/er_diagram_canvas_new.dart';
export 'widgets/er_node_widget_new.dart';

// Graph 构建器
export 'core/er_graph_builder.dart';

// 旧版（保留兼容）
export 'models/er_diagram_models.dart';
export 'providers/er_diagram_provider.dart';
export 'widgets/er_diagram_canvas.dart';
export 'widgets/er_table_node_widget.dart';
export 'widgets/er_node_builder.dart';
export 'renderers/er_edge_renderer.dart';
export 'core/field_anchor_registry.dart';
export 'core/er_graph_edge.dart';
export 'core/graph_sync.dart';
export 'layout/layout_adapter.dart';