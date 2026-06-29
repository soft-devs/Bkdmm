export const meta = {
  name: 'diagram-editor-refactor',
  description: '图编辑器 V2 全面重构 - 5 阶段执行计划',
  phases: [
    { title: 'Phase 1', detail: '核心框架 - GraphModel, TransformModel, EventCenter' },
    { title: 'Phase 2', detail: '渲染层 - GraphView, CanvasOverlay, CustomPaint' },
    { title: 'Phase 3', detail: '交互行为 - Behavior 系统, 拖拽框选连线' },
    { title: 'Phase 4', detail: 'ER 图迁移 - ERTableNodeModel, 功能验证' },
    { title: 'Phase 5', detail: '清理扩展 - HistoryController, undo/redo' },
  ],
};

const PHASES = [
  {
    id: 1,
    title: '核心框架',
    duration: '2-3 天',
    tasks: [
      { file: 'lib/shared/diagram_editor/src/model/graph_model.dart', desc: '图数据模型 - nodes/edges 管理' },
      { file: 'lib/shared/diagram_editor/src/model/node_model.dart', desc: '节点模型基类 - 位置/尺寸/状态' },
      { file: 'lib/shared/diagram_editor/src/model/edge_model.dart', desc: '边模型基类 - source/target/anchors' },
      { file: 'lib/shared/diagram_editor/src/model/transform_model.dart', desc: '视口变换 - 缩放/平移/坐标转换' },
      { file: 'lib/shared/diagram_editor/src/event/event_center.dart', desc: '事件中心 - on/emit/off' },
      { file: 'lib/shared/diagram_editor/src/event/event_types.dart', desc: '事件类型常量定义' },
    ],
    tests: [
      { file: 'test/shared/diagram_editor/model_test.dart', desc: 'GraphModel/TransformModel 单元测试' },
      { file: 'test/shared/diagram_editor/event_test.dart', desc: 'EventCenter 单元测试' },
    ],
    verify: ['flutter analyze 无错误', '所有单元测试通过'],
  },
  {
    id: 2,
    title: '渲染层',
    duration: '2-3 天',
    tasks: [
      { file: 'lib/shared/diagram_editor/src/view/graph_view.dart', desc: '主视图 - Stack 分层结构' },
      { file: 'lib/shared/diagram_editor/src/view/canvas_overlay.dart', desc: '画布层 - CustomPaint 节点/边' },
      { file: 'lib/shared/diagram_editor/src/view/modification_overlay.dart', desc: '交互层 - 框选/连线预览' },
      { file: 'lib/shared/diagram_editor/src/view/tool_overlay.dart', desc: '工具层 - 缩放控制/位置信息' },
      { file: 'lib/shared/diagram_editor/src/view/painter/node_painter.dart', desc: '节点绘制器' },
      { file: 'lib/shared/diagram_editor/src/view/painter/edge_painter.dart', desc: '边绘制器' },
      { file: 'lib/shared/diagram_editor/src/view/painter/grid_painter.dart', desc: '网格绘制器' },
    ],
    tests: [
      { file: 'test/shared/diagram_editor/view_test.dart', desc: '渲染层测试' },
    ],
    verify: ['节点渲染正常', '边渲染正常', '网格跟随缩放', '无 InteractiveViewer 依赖'],
  },
  {
    id: 3,
    title: '交互行为',
    duration: '2-3 天',
    tasks: [
      { file: 'lib/shared/diagram_editor/src/behavior/behavior.dart', desc: 'Behavior 基类 - priority/canHandle/handle' },
      { file: 'lib/shared/diagram_editor/src/behavior/behavior_registry.dart', desc: 'Behavior 注册表 - 优先级排序' },
      { file: 'lib/shared/diagram_editor/src/handler/pointer_handler.dart', desc: '指针事件入口 - Listener/坐标转换/命中测试' },
      { file: 'lib/shared/diagram_editor/src/behavior/node_drag_behavior.dart', desc: '节点拖拽行为' },
      { file: 'lib/shared/diagram_editor/src/behavior/selection_behavior.dart', desc: '框选行为' },
      { file: 'lib/shared/diagram_editor/src/behavior/connection_behavior.dart', desc: '连线行为' },
      { file: 'lib/shared/diagram_editor/src/behavior/pan_zoom_behavior.dart', desc: '平移缩放行为' },
    ],
    tests: [
      { file: 'test/shared/diagram_editor/behavior_test.dart', desc: '交互行为测试' },
    ],
    verify: ['节点可拖拽', '框选功能正常', '连线功能正常', '滚轮缩放正常'],
  },
  {
    id: 4,
    title: 'ER 图迁移',
    duration: '2-3 天',
    tasks: [
      { file: 'lib/shared/diagram_editor/src/er/er_table_node_model.dart', desc: 'ER 表节点模型' },
      { file: 'lib/shared/diagram_editor/src/er/er_relation_edge_model.dart', desc: 'ER 关系边模型' },
      { file: 'lib/shared/diagram_editor/src/er/er_table_painter.dart', desc: 'ER 表绘制器' },
      { file: 'lib/shared/diagram_editor/src/er/er_relation_painter.dart', desc: 'ER 关系绘制器' },
      { file: 'lib/features/modeling/er_diagram/er_diagram_canvas_v2.dart', desc: 'ER 图画布 V2 - 使用新架构' },
    ],
    tests: [
      { file: 'test/features/modeling/er_diagram/er_canvas_v2_test.dart', desc: 'ER 图 V2 功能测试' },
    ],
    verify: ['V1 所有功能正常', '无性能回退', '代码量减少'],
  },
  {
    id: 5,
    title: '清理扩展',
    duration: '1-2 天',
    tasks: [
      { file: 'lib/shared/diagram_editor/src/history/history_controller.dart', desc: '历史记录 - undo/redo' },
      { file: 'lib/shared/diagram_editor/diagram_editor.dart', desc: '导出文件 - 整理导出' },
      { file: 'lib/shared/diagram_editor/src/diagram_editor.dart', desc: '主入口类 - 完善 API' },
    ],
    cleanup: [
      '删除 V1 旧画布文件',
      '删除旧的 handlers/spatial/commands 目录',
      '更新导入路径',
    ],
    verify: ['undo/redo 正常', '旧代码清理完成', '文档更新', 'flutter analyze 无错误'],
  },
];

// 执行单个阶段
async function executePhase(phase) {
  log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
  log(`Phase ${phase.id}: ${phase.title} (${phase.duration})`);
  log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

  // 1. 创建任务文件
  log(`📂 创建文件:`);
  const fileResults = await parallel(
    phase.tasks.map(task => () =>
      agent(`创建文件 ${task.file}: ${task.desc}`, {
        label: task.file.split('/').pop(),
        phase: `Phase ${phase.id}`,
        schema: {
          type: 'object',
          properties: {
            created: { type: 'boolean' },
            path: { type: 'string' },
            status: { type: 'string' },
          },
          required: ['created', 'path', 'status'],
        },
      })
    )
  );
  const createdFiles = fileResults.filter(Boolean).filter(r => r.created);
  log(`   ✅ 已创建 ${createdFiles.length}/${phase.tasks.length} 个文件\n`);

  // 2. 创建测试文件
  if (phase.tests && phase.tests.length > 0) {
    log(`🧪 创建测试:`);
    const testResults = await parallel(
      phase.tests.map(test => () =>
        agent(`创建测试文件 ${test.file}: ${test.desc}`, {
          label: test.file.split('/').pop(),
          phase: `Phase ${phase.id} Tests`,
        })
      )
    );
    log(`   ✅ 已创建 ${testResults.filter(Boolean).length} 个测试文件\n`);
  }

  // 3. 验证阶段
  log(`🔍 验证:`);
  const verifyResult = await agent(
    `执行验证: ${phase.verify.join(', ')}`,
    {
      label: 'Verify',
      phase: `Phase ${phase.id} Verify`,
      schema: {
        type: 'object',
        properties: {
          passed: { type: 'boolean' },
          details: { type: 'array', items: { type: 'string' } },
        },
        required: ['passed', 'details'],
      },
    }
  );

  if (verifyResult?.passed) {
    log(`   ✅ 验证通过: ${verifyResult.details.join(', ')}\n`);
  } else {
    log(`   ⚠️ 验证待完成: ${phase.verify.join(', ')}\n`);
  }

  // 4. 清理任务 (Phase 5)
  if (phase.cleanup && phase.cleanup.length > 0) {
    log(`🧹 清理:`);
    for (const item of phase.cleanup) {
      log(`   - ${item}`);
    }
    log('');
  }

  return {
    phase: phase.id,
    title: phase.title,
    filesCreated: createdFiles.length,
    verified: verifyResult?.passed ?? false,
  };
}

// 主流程
phase('Planning');
log('图编辑器 V2 重构工作流');
log(`共 ${PHASES.length} 个阶段，预估 10-15 天\n`);

const results = await pipeline(
  PHASES,
  phase => executePhase(phase)
);

// 总结
phase('Summary');
log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
log('重构完成总结');
log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

log('阶段完成情况:');
for (const r of results) {
  const status = r.verified ? '✅' : '⏳';
  log(`  ${status} Phase ${r.phase}: ${r.title} - ${r.filesCreated} 个文件`);
}

const totalFiles = results.reduce((sum, r) => sum + r.filesCreated, 0);
const verifiedCount = results.filter(r => r.verified).length;

log(`\n总计: ${totalFiles} 个文件创建, ${verifiedCount}/${PHASES.length} 阶段验证通过`);

return {
  phases: results,
  totalFiles,
  verifiedPhases: verifiedCount,
  completed: verifiedCount === PHASES.length,
};