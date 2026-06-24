/// ER 图编辑器
///
/// 使用 graphview 库实现：
/// - GraphView widget 提供图表渲染和交互
/// - SugiyamaAlgorithm 提供层次布局
/// - 自定义 NodeWidgetBuilder 和 EdgeRenderer 实现 ER 特定渲染
/// - 字段级锚点支持字段间连线

library er_diagram;

// 核心模型
export 'models/er_diagram_models.dart';
export 'providers/er_diagram_provider.dart';

// 画布和 Widget
export 'widgets/er_diagram_canvas.dart';
export 'widgets/er_table_node_widget.dart';
export 'widgets/er_node_builder.dart';

// 渲染器
export 'renderers/er_edge_renderer.dart';

// 核心扩展
export 'core/field_anchor_registry.dart';
export 'core/er_graph_edge.dart';
export 'core/graph_sync.dart';

// 布局
export 'layout/layout_adapter.dart';