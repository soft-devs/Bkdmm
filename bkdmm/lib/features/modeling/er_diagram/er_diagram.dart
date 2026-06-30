/// ER 图编辑器
///
/// 使用 diagram_editor 框架实现：
/// - DiagramState 管理状态
/// - GraphView 分层渲染
/// - ERInteractionManager 处理交互
/// - NodeModel 封装节点数据
/// - 字段级锚点支持字段间连线
/// - 预览模式：左键拖动画布，双击打开预览弹窗
/// - 编辑模式：左键框选/拖动节点，右键拖动画布，双击打开编辑弹窗

library er_diagram;

// ============================================================================
// 新架构 (diagram_editor 框架)
// ============================================================================

// 控制器
export 'controllers/er_diagram_controller.dart';

// 视图
export 'views/er_diagram_view.dart';
export 'views/er_interaction_overlay.dart';

// 绘制器
export 'painters/er_relation_painter_adapter.dart';

// Widget
export 'widgets/er_table_node_widget_v2.dart';
export 'widgets/er_field_anchor_widget.dart';

// 模型和状态
export 'models/er_diagram_ui_state.dart';