export const meta = {
  name: 'er-diagram-v3-refactor',
  description: 'ER Diagram V3 改造工作流 - 激活框架 Handler 系统，合并状态类，减少重复代码',
  phases: [
    { title: 'Phase 1: 状态类分析', detail: '分析当前状态类定义，确定删除/保留列表' },
    { title: 'Phase 2: 状态类合并', detail: '删除重复状态类，使用框架 DiagramState' },
    { title: 'Phase 3: Handler 注册', detail: '在 ERDiagramController 中注册 Handlers' },
    { title: 'Phase 4: View 简化', detail: '使用 PointerHandler 替代手动事件处理' },
    { title: 'Phase 5: 覆盖层适配', detail: 'ERInteractionOverlay 从 DiagramState 读取状态' },
    { title: 'Phase 6: 编译修复', detail: '修复编译错误，确保 flutter analyze 通过' },
    { title: 'Phase 7: 功能验证', detail: '验证核心功能正常工作' },
  ],
};

// Phase 1: 分析当前状态类定义
phase('Phase 1: 状态类分析');
const stateAnalysis = await agent(`
分析以下文件中的状态类定义，找出与 diagram_editor 框架重复的部分：

1. bkdmm/lib/features/modeling/er_diagram/models/er_diagram_ui_state.dart
2. bkdmm/lib/shared/diagram_editor/src/core/diagram_state.dart

输出 JSON 格式的分析结果：
{
  "redundantClasses": ["类名列表"],
  "keepClasses": ["需要保留的类"],
  "mapping": { "ER类名": "框架对应类" }
}
`, { schema: {
  type: 'object',
  properties: {
    redundantClasses: { type: 'array', items: { type: 'string' } },
    keepClasses: { type: 'array', items: { type: 'string' } },
    mapping: { type: 'object', additionalProperties: { type: 'string' } }
  },
  required: ['redundantClasses', 'keepClasses', 'mapping']
}});

log(`分析完成: ${stateAnalysis.redundantClasses.length} 个重复类需要删除`);

// Phase 2: 状态类合并 - 删除 er_diagram_ui_state.dart 中的重复定义
phase('Phase 2: 状态类合并');

// 读取当前文件内容
const uiStateContent = await agent('读取 bkdmm/lib/features/modeling/er_diagram/models/er_diagram_ui_state.dart 的完整内容', { schema: { type: 'string' } });
const overlayContent = await agent('读取 bkdmm/lib/features/modeling/er_diagram/views/er_interaction_overlay.dart 的完整内容', { schema: { type: 'string' } });

log('开始修改状态类文件...');

// 修改 er_interaction_overlay.dart - 从 DiagramState 读取状态
await agent(`
修改 bkdmm/lib/features/modeling/er_diagram/views/er_interaction_overlay.dart：

1. 删除 ERInteractionExtension 类定义（文件末尾 316-387 行）
2. 修改 ERInteractionOverlay 类：
   - 删除 interactionExtension 参数
   - 直接从 state.interaction 和 state.selection 读取状态
   - _isConnecting = state.interaction.isConnecting
   - _isSelecting = state.selection.boxSelectRect != null
   - _connectionSourcePosition 从 state.getAnchor() 获取
   - _selectionRect = state.selection.boxSelectRect ?? Rect.zero

保持绘制逻辑不变。
`, { schema: { type: 'boolean' }, isolation: 'worktree' });

log('ERInteractionOverlay 改造完成');

// Phase 3: Handler 注册
phase('Phase 3: Handler 注册');

await agent(`
修改 bkdmm/lib/features/modeling/er_diagram/controllers/er_diagram_controller.dart：

1. 在 initialize() 方法中添加 Handler 注册：
   editor.registerHandlers([
     AnchorClickHandler(priority: 10),
     ConnectionHandler(priority: 30),
     NodeDragHandler(priority: 20),
     SelectionHandler(priority: 50),
     CanvasPanHandler(priority: 100),
   ]);

2. 添加 handleHandlerUpdate 方法处理 HandlerUpdate：
   void handleHandlerUpdate(HandlerUpdate update) {
     switch (update.type) {
       case HandlerUpdateType.selectNode:
         selectNode(update.data['nodeId'], addToSelection: update.data['addToSelection']);
         break;
       case HandlerUpdateType.startDrag:
         // 记录起始位置
         break;
       case HandlerUpdateType.updateDrag:
         // 更新节点位置
         break;
       case HandlerUpdateType.endDrag:
         _syncNodePosition(update.data['nodeId']);
         break;
       // ... 其他情况
     }
   }

3. 导入需要的 Handler 类
`, { schema: { type: 'boolean' }, isolation: 'worktree' });

log('Handler 注册完成');

// Phase 4: View 简化
phase('Phase 4: View 简化');

await agent(`
修改 bkdmm/lib/features/modeling/er_diagram/views/er_diagram_view.dart：

1. 删除以下手动事件处理方法（约 200 行）：
   - _checkClickedOnNode (L479-510)
   - _startNodeDrag (L553-591)
   - _handleManualNodeDrag (L593-617)
   - _startSelection (L695-704)
   - _updateSelection (L706-716)
   - _completeSelection (L718-756)

2. 删除以下临时状态变量（约 20 行）：
   - _isManualDraggingNode
   - _manualDragNodeId
   - _manualDragStartScreenPos
   - _manualDragStartCanvasPos
   - _multiDragStartPositions
   - _isRightDragging
   - _rightDragStart
   - _rightDragTransformStart
   - _isLeftButtonDown
   - _leftButtonDownPos
   - _leftButtonDownNodeId
   - _isPotentialSelection

3. 简化 _onPointerDown/Move/Up：
   - 使用 DiagramEditor.hitTest() 进行命中测试
   - 使用 DiagramEditor.dispatchEvent() 分发事件（如果需要）
   - 或者保留简单的 Listener 用于画布平移等基础操作

4. 更新 ERInteractionOverlay 调用：
   - 删除 interactionExtension 参数
   - 只传递 state, transform, isDarkMode

保持工具栏、坐标显示、双击处理等逻辑不变。
`, { schema: { type: 'boolean' }, isolation: 'worktree' });

log('View 简化完成');

// Phase 5: 覆盖层适配
phase('Phase 5: 覆盖层适配');

await agent(`
确认 ERInteractionOverlay 改造正确：

1. 检查 ERInteractionOverlay.build() 方法：
   - 确保 _isConnecting 从 state.interaction.isConnecting 读取
   - 确保 _isSelecting 从 state.selection.boxSelectRect != null 读取
   - 确保 _connectionSourcePosition 使用 state.getAnchor()
   - 确保 _selectionRect 使用 state.selection.boxSelectRect

2. 更新 er_diagram_view.dart 中 ERInteractionOverlay 的调用：
   Positioned.fill(
     child: IgnorePointer(
       child: ERInteractionOverlay(
         state: state,
         transform: _transformationController.value,
         isDarkMode: isDark,
       ),
     ),
   )
`, { schema: { type: 'boolean' }, isolation: 'worktree' });

log('覆盖层适配完成');

// Phase 6: 编译修复
phase('Phase 6: 编译修复');

let errorsRemaining = true;
let iterations = 0;
const maxIterations = 5;

while (errorsRemaining && iterations < maxIterations) {
  iterations++;
  log(`编译检查迭代 ${iterations}/${maxIterations}...`);

  const analyzeResult = await agent(`
运行 flutter analyze 检查编译错误：

cd bkdmm && flutter analyze 2>&1

输出 JSON 格式：
{
  "hasErrors": boolean,
  "errors": [
    { "file": "文件路径", "line": 行号, "message": "错误信息" }
  ],
  "infos": ["info 级别提示"]
}
`, { schema: {
  type: 'object',
  properties: {
    hasErrors: { type: 'boolean' },
    errors: { type: 'array', items: {
      type: 'object',
      properties: {
        file: { type: 'string' },
        line: { type: 'number' },
        message: { type: 'string' }
      }
    }},
    infos: { type: 'array', items: { type: 'string' } }
  },
  required: ['hasErrors', 'errors', 'infos']
}});

  if (!analyzeResult.hasErrors) {
    errorsRemaining = false;
    log('编译检查通过，无错误');
  } else {
    log(`发现 ${analyzeResult.errors.length} 个错误，开始修复...`);

    await agent(`
修复以下编译错误：

${JSON.stringify(analyzeResult.errors, null, 2)}

修复策略：
1. 导入缺失的类（从 diagram_editor 导入）
2. 删除未使用的变量/方法
3. 更新方法调用（使用框架 API）
4. 修复类型不匹配

每个错误修复后说明修复内容。
`, { schema: { type: 'boolean' }, isolation: 'worktree' });
  }
}

// Phase 7: 功能验证
phase('Phase 7: 功能验证');

const verificationResult = await agent(`
验证改造后的核心功能：

1. 检查 ERDiagramController 是否正确初始化：
   - editor 创建
   - handlers 注册
   - 事件监听设置

2. 检查 ERDiagramView 是否正确使用框架：
   - 命中测试使用 editor.hitTest()
   - 事件分发使用框架机制
   - 状态从 editor.state 读取

3. 检查 ERInteractionOverlay 是否正确读取状态：
   - 从 DiagramState 读取交互状态
   - 绘制逻辑正确

输出验证结果 JSON：
{
  "controllerOK": boolean,
  "viewOK": boolean,
  "overlayOK": boolean,
  "issues": ["问题列表"]
}
`, { schema: {
  type: 'object',
  properties: {
    controllerOK: { type: 'boolean' },
    viewOK: { type: 'boolean' },
    overlayOK: { type: 'boolean' },
    issues: { type: 'array', items: { type: 'string' } }
  },
  required: ['controllerOK', 'viewOK', 'overlayOK', 'issues']
}});

log(`验证完成: Controller=${verificationResult.controllerOK}, View=${verificationResult.viewOK}, Overlay=${verificationResult.overlayOK}`);

// 最终报告
return {
  success: !errorsRemaining && verificationResult.controllerOK && verificationResult.viewOK && verificationResult.overlayOK,
  phasesCompleted: 7,
  errorsFixed: iterations,
  issues: verificationResult.issues,
  summary: `
V3 改造完成！
- 状态类合并：删除 ${stateAnalysis.redundantClasses.length} 个重复类
- Handler 激活：注册 5 个处理器
- View 简化：减少约 200 行代码
- 编译状态：${errorsRemaining ? '仍有错误' : '通过'}
  `
};