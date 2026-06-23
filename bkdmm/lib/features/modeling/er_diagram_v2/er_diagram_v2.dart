/// ER 图编辑器 v2
///
/// 使用混合架构实现：
/// - DiagramCanvas 基类提供通用画布功能
/// - ERNodeRenderer/EREdgeRenderer 提供自定义渲染
/// - GraphViewLayoutEngine 提供布局算法

library er_diagram_v2;

export 'models/er_diagram_models.dart';
export 'providers/er_diagram_provider.dart';
export 'widgets/er_diagram_canvas.dart';
export 'renderers/er_renderers.dart';