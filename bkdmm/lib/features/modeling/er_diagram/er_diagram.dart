/// ER 图编辑器
///
/// 使用 graphview 库实现：
/// - GraphView widget 提供图表渲染和交互
/// - SugiyamaAlgorithm 提供层次布局
/// - 自定义 NodeWidgetBuilder 实现 ER 特定渲染
/// - 字段级锚点支持字段间连线
/// - 预览模式：左键拖动画布，双击打开预览弹窗
/// - 编辑模式：左键框选/拖动节点，右键拖动画布，双击打开编辑弹窗

library er_diagram;

// 模型和状态
export 'models/er_diagram_ui_state.dart';
export 'providers/er_diagram_ui_provider.dart';

// 画布和 Widget
export 'widgets/er_diagram_canvas_v2.dart';
export 'widgets/er_table_node_widget.dart';
export 'widgets/er_field_anchor_widget.dart';

// Graph 构建器
export 'core/er_graph_builder.dart';

// 布局
export 'layout/layout_adapter.dart';