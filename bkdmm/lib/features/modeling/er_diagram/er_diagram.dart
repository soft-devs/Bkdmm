/// ER 图编辑器
///
/// 使用 graphview 库实现：
/// - GraphView widget 提供图表渲染和交互
/// - SugiyamaAlgorithm 提供层次布局
/// - 自定义 NodeWidgetBuilder 和 EdgeRenderer 实现 ER 特定渲染
/// - 字段级锚点支持字段间连线
///
/// V1 (Canvas) - 基于 CustomPainter 的传统实现（已废弃）
/// V2 (GraphView) - 基于 graphview 库的新实现

library er_diagram;

// 核心模型
export 'models/er_diagram_models.dart';
export 'providers/er_diagram_provider.dart';

// V1: Canvas 实现（传统）
export 'widgets/er_diagram_canvas.dart';
export 'renderers/er_renderers.dart';

// V2: GraphView 实现（推荐）
export 'widgets/er_diagram_canvas_v2.dart';
export 'widgets/er_table_node_widget.dart';
export 'widgets/er_node_builder.dart';
export 'renderers/er_edge_renderer.dart';

// 核心扩展
export 'core/field_anchor_registry.dart';
export 'core/er_graph_edge.dart';
export 'core/graph_sync.dart';

// 布局
export 'layout/layout_adapter.dart';