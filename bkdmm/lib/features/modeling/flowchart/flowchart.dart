/// 流程图编辑器
///
/// 使用混合架构实现：
/// - DiagramCanvas 基类提供通用画布功能
/// - FlowNodeRenderer/FlowEdgeRenderer 提供自定义渲染
/// - TreeLayout 提供树形布局

library flowchart;

export 'models/flowchart_models.dart';
export 'renderers/flowchart_renderers.dart';
export 'widgets/flowchart_canvas.dart';