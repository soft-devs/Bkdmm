export const meta = {
  name: 'bkdmm-continue-dev',
  description: 'Continue Bkdmm Flutter development - fix errors, then implement modules incrementally',
  phases: [
    { title: 'Fix', detail: 'Fix existing compilation errors first' },
    { title: 'Home', detail: 'Fix home page layout and responsiveness' },
    { title: 'Project', detail: 'Fix project creation/open dialogs' },
    { title: 'Settings', detail: 'Implement settings page' },
    { title: 'Workspace', detail: 'Implement workspace with tabs' },
    { title: 'TableEditor', detail: 'Implement table/entity editor' },
    { title: 'ERDiagram', detail: 'Implement ER diagram visualization' },
    { title: 'CodeGen', detail: 'Implement code generation' },
    { title: 'DataType', detail: 'Implement data type management' },
    { title: 'Verify', detail: 'Final verification and testing' },
  ],
  whenToUse: 'Continue development after initial project setup, fix errors and implement all modules',
};

// ============================================
// Phase 1: Fix Existing Errors
// ============================================
phase('Fix');
log('Phase 1: Fixing existing compilation errors...');

const fixResult = await agent(`
Fix all existing errors in the Bkdmm Flutter project at F:\\projects\\Bkdmm\\bkdmm

Steps:
1. Run 'flutter pub get' to ensure dependencies are resolved
2. Run 'flutter analyze' to identify all errors
3. Fix each error category:

**Import Path Fixes:**
- From lib/features/home/views/home_view.dart to lib/shared/ → use ../../../shared/
- From lib/features/home/widgets/history_list_tile.dart to lib/shared/ → use ../../../shared/
- From lib/features/project/views/*.dart to lib/shared/ → use ../../../shared/

**Type Fixes:**
- CardTheme → CardThemeData (Flutter 3.x API change)
- DialogTheme → DialogThemeData (Flutter 3.x API change)

**Widget Fixes:**
- NavigationDestination.icon expects Widget not IconData → wrap with Icon()
- Add missing imports for LoadingOverlay, AppScaffold

**File Cleanup:**
- Remove duplicate lib/app/main.dart if it exists
- Fix widget_test.dart to reference BkdmmApp instead of MyApp

4. Run 'flutter analyze' again to verify all errors are fixed
5. Report the results

Return JSON:
{
  "success": boolean,
  "errorsFixed": number,
  "remainingErrors": number,
  "changes": ["list of changes made"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    errorsFixed: { type: 'number' },
    remainingErrors: { type: 'number' },
    changes: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Fix phase: ${fixResult.success ? '✅ Success' : '⚠️ Issues remain'} - ${fixResult.errorsFixed || 0} errors fixed`);

// ============================================
// Phase 2: Fix Home Page
// ============================================
phase('Home');
log('Phase 2: Fixing home page layout and responsiveness...');

const homeResult = await agent(`
Fix and improve the home page in F:\\projects\\Bkdmm\\bkdmm

**Current Issues to Fix:**
1. Layout is messy - needs proper responsive design
2. Quick actions not responding
3. Recent projects list not displaying properly
4. New project button not working

**Implementation Requirements:**
1. Fix HomeView layout:
   - Use proper LayoutBuilder for responsive design
   - Center content with max width constraint
   - Add proper spacing and padding
   - Make it scrollable for small screens

2. Fix QuickActionCard:
   - Proper InkWell ripple effect
   - Correct tap handling
   - Visual feedback on hover

3. Fix history list:
   - Proper loading state
   - Empty state display
   - Error handling

4. Connect to project provider:
   - Create project dialog should work
   - Open project dialog should work
   - History should load from storage

**Files to modify:**
- lib/features/home/views/home_view.dart
- lib/features/home/widgets/history_list_tile.dart
- lib/features/project/views/create_project_dialog.dart
- lib/features/project/views/open_project_dialog.dart

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Home page: ${homeResult.success ? '✅ Fixed' : '⚠️ Issues remain'}`);

// ============================================
// Phase 3: Fix Project Dialogs
// ============================================
phase('Project');
log('Phase 3: Fixing project creation and open dialogs...');

const projectResult = await agent(`
Fix and implement project management dialogs in F:\\projects\\Bkdmm\\bkdmm

**Create Project Dialog:**
1. Show dialog with form fields:
   - Project name (required)
   - File path (with browse button)
   - Description (optional)
2. Validate inputs
3. Create project file on submit
4. Add to recent history
5. Navigate to workspace

**Open Project Dialog:**
1. Use file_picker to select .bkdmm.json file
2. Read and validate project file
3. Handle data migration if needed
4. Add to recent history
5. Navigate to workspace

**Project Provider Updates:**
1. Ensure ProjectNotifier handles all operations
2. Proper loading states
3. Error handling with user feedback
4. Auto-save functionality

**Files to modify:**
- lib/features/project/views/create_project_dialog.dart
- lib/features/project/views/open_project_dialog.dart
- lib/features/project/providers/project_notifier.dart
- lib/shared/providers/project_provider.dart

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Project dialogs: ${projectResult.success ? '✅ Fixed' : '⚠️ Issues remain'}`);

// ============================================
// Phase 4: Settings Page
// ============================================
phase('Settings');
log('Phase 4: Implementing settings page...');

const settingsResult = await agent(`
Implement settings page in F:\\projects\\Bkdmm\\bkdmm

**Settings Categories:**

1. **Appearance Settings:**
   - Theme mode (Light/Dark/System)
   - Accent color
   - Font size

2. **Editor Settings:**
   - Default database type
   - Auto-save interval
   - Show line numbers in code preview

3. **Default Fields:**
   - Configure default fields for new tables
   - Enable/disable: REVISION, CREATED_BY, CREATED_TIME, UPDATED_BY, UPDATED_TIME

4. **Data Type Settings:**
   - Link to data type management page

**Implementation:**
1. Create SettingsView with proper layout
2. Use SettingsProvider for state management
3. Persist settings to Hive
4. Apply theme changes immediately

**Files to create/modify:**
- lib/features/settings/views/settings_view.dart
- lib/shared/providers/settings_provider.dart (update)

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Settings page: ${settingsResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 5: Workspace with Tabs
// ============================================
phase('Workspace');
log('Phase 5: Implementing workspace with tabs...');

const workspaceResult = await agent(`
Implement workspace view with tab management in F:\\projects\\Bkdmm\\bkdmm

**Workspace Layout:**
\`\`\`
┌─────────────────────────────────────────────────────┐
│ MenuBar                                             │
├─────────┬───────────────────────────────────────────┤
│ Module  │ Tab Bar (closable, scrollable)            │
│ Tree    ├───────────────────────────────────────────┤
│         │                                           │
│ - Module│         Tab Content Area                  │
│   - Table1│                                         │
│   - Table2│   (EntityEditor / ERDiagram / etc)      │
│         │                                           │
├─────────┴───────────────────────────────────────────┤
│ StatusBar                                           │
└─────────────────────────────────────────────────────┘
\`\`\`

**Tab Management:**
1. TabProvider to manage open tabs
2. Tab types: entity, relation, settings
3. Close tab with X button or Ctrl+E
4. Tab overflow handling (scroll or dropdown)
5. Persist open tabs between sessions

**Module Tree:**
1. TreeView for module hierarchy
2. Drag and drop to reorder
3. Context menu (new, delete, rename)
4. Double-click to open in tab

**Files to create:**
- lib/features/modeling/workspace/views/workspace_view.dart
- lib/features/modeling/workspace/providers/tab_provider.dart
- lib/features/modeling/workspace/widgets/module_tree.dart
- lib/features/modeling/workspace/widgets/tab_bar.dart
- lib/shared/widgets/app_scaffold.dart (update)

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Workspace: ${workspaceResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 6: Table Editor
// ============================================
phase('TableEditor');
log('Phase 6: Implementing table/entity editor...');

const tableEditorResult = await agent(`
Implement table/entity editor in F:\\projects\\Bkdmm\\bkdmm

**Entity Editor Layout:**
\`\`\`
┌─────────────────────────────────────────────────────┐
│ Entity Header: TableName[中文名]        [Save]     │
├─────────────────────────────────────────────────────┤
│ [摘要] [字段] [索引] [代码预览]                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│   Tab Content:                                      │
│   - 摘要: Basic info form                           │
│   - 字段: Syncfusion DataGrid with fields           │
│   - 索引: Index management UI                       │
│   - 代码预览: Generated DDL preview                 │
│                                                     │
└─────────────────────────────────────────────────────┘
\`\`\`

**Field Table Features:**
1. Columns: 主键, 字段名, 数据类型, 中文名, 非空, 自增, 备注
2. Inline editing
3. Add/delete rows
4. Drag to reorder
5. Data type dropdown from DataTypeProvider

**Index Editor Features:**
1. Index name and type (NORMAL/UNIQUE/FULLTEXT)
2. Field selection with checkboxes
3. Add/delete indexes

**Code Preview Features:**
1. Database selector dropdown
2. Syntax highlighted DDL
3. Copy to clipboard
4. Download as .sql file

**Files to create:**
- lib/features/modeling/entity_editor/views/entity_editor_view.dart
- lib/features/modeling/entity_editor/widgets/field_table.dart
- lib/features/modeling/entity_editor/widgets/index_editor.dart
- lib/features/modeling/entity_editor/widgets/code_preview.dart
- lib/features/modeling/entity_editor/providers/entity_provider.dart

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Table editor: ${tableEditorResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 7: ER Diagram
// ============================================
phase('ERDiagram');
log('Phase 7: Implementing ER diagram visualization...');

const erDiagramResult = await agent(`
Implement ER diagram visualization in F:\\projects\\Bkdmm\\bkdmm

This is the MOST COMPLEX module - requires CustomPainter self-implementation.

**ER Diagram Widget Architecture:**
\`\`\`
ERDiagramWidget (ConsumerStatefulWidget)
├── InteractiveViewer (zoom/pan)
│   └── CustomPaint
│       └── ERGraphPainter
│           ├── NodePainter (draw table nodes)
│           └── EdgePainter (draw relation lines)
├── GestureDetector (interaction)
│   ├── onPanStart/Update/End (drag nodes)
│   ├── onTapDown (select)
│   └── onDoubleTapDown (open editor)
└── Toolbar (overlay)
    ├── Zoom in/out
    ├── Fit to screen
    ├── Search nodes
    ├── Auto layout
    └── Export image
\`\`\`

**Node Drawing:**
1. Draw rounded rectangle for each table
2. Header with table name (colored background)
3. Field list with primary key indicator (🔑)
4. Selection highlight

**Edge Drawing:**
1. Draw lines between related tables
2. Arrow heads for direction
3. Relation labels

**Interaction:**
1. Click to select node
2. Drag to move node
3. Double-click to open table editor
4. Right-click for context menu
5. Ctrl+click for multi-select

**Toolbar:**
1. Zoom controls
2. Fit all nodes to screen
3. Search node by name
4. Auto layout (hierarchical)
5. Export to PNG

**Files to create:**
- lib/features/modeling/er_diagram/widgets/er_diagram_widget.dart
- lib/features/modeling/er_diagram/painters/er_graph_painter.dart
- lib/features/modeling/er_diagram/painters/node_painter.dart
- lib/features/modeling/er_diagram/painters/edge_painter.dart
- lib/features/modeling/er_diagram/layout/dagre_layout.dart
- lib/features/modeling/er_diagram/export/image_export.dart
- lib/features/modeling/er_diagram/providers/graph_provider.dart

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`ER diagram: ${erDiagramResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 8: Code Generation
// ============================================
phase('CodeGen');
log('Phase 8: Implementing code generation...');

const codeGenResult = await agent(`
Implement code generation in F:\\projects\\Bkdmm\\bkdmm

**Template Engine:**
Use mustache_template package for template rendering.

**DDL Generation:**
1. Create table DDL for each database type
2. Drop table DDL
3. Alter table DDL (for schema changes)

**Database Templates:**
1. MySQL
2. PostgreSQL
3. Oracle
4. SQL Server
5. SQLite

**Template Variables:**
\`\`\`
{{entity.title}} - Table name
{{entity.chnname}} - Chinese name
{{#fields}}...{{/fields}} - Iterate fields
{{field.name}} - Field name
{{field.typeDB}} - Database type
{{field.pk}} - Is primary key
{{func.camel}} - Camel case conversion
\`\`\`

**Code Preview Widget:**
1. Database selector
2. Syntax highlighted preview
3. Copy/download buttons
4. Real-time generation

**Files to create:**
- lib/features/codegen/services/codegen_service.dart
- lib/features/codegen/services/template_service.dart
- lib/features/codegen/views/codegen_view.dart
- lib/features/codegen/providers/codegen_provider.dart
- assets/templates/ddl/mysql_create_table.mustache
- assets/templates/ddl/postgresql_create_table.mustache
- assets/templates/ddl/oracle_create_table.mustache

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Code generation: ${codeGenResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 9: Data Type Management
// ============================================
phase('DataType');
log('Phase 9: Implementing data type management...');

const dataTypeResult = await agent(`
Implement data type management in F:\\projects\\Bkdmm\\bkdmm

**Default Data Types:**
1. IdOrKey - 标识键
2. Name - 名称
3. Intro - 简介
4. LongText - 长文本
5. Integer - 整数
6. Long - 长整数
7. Money - 金额
8. DateTime - 日期时间
9. YesNo - 是否
10. Dict - 字典

**Data Type Editor:**
1. List all data types
2. Add new data type
3. Edit existing type
4. Delete type (check usage)
5. Restore defaults

**Type Mapping UI:**
For each data type, show mapping for:
- MySQL
- PostgreSQL
- Oracle
- SQL Server
- SQLite
- Java

**Files to create:**
- lib/features/datatype/views/datatype_view.dart
- lib/features/datatype/views/datatype_edit_dialog.dart
- lib/features/datatype/providers/datatype_provider.dart
- lib/shared/constants/default_data_types.dart
- assets/datatypes/default_types.json (update if needed)

Return JSON:
{
  "success": boolean,
  "changes": ["list of changes made"],
  "issues": ["any remaining issues"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    changes: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

log(`Data type management: ${dataTypeResult.success ? '✅ Implemented' : '⚠️ Issues remain'}`);

// ============================================
// Phase 10: Final Verification
// ============================================
phase('Verify');
log('Phase 10: Final verification and testing...');

const verifyResult = await agent(`
Final verification of the Bkdmm Flutter project at F:\\projects\\Bkdmm\\bkdmm

**Verification Steps:**

1. Run 'flutter analyze' - should have no errors
2. Run 'flutter build windows --debug' - should compile
3. Check all routes work:
   - Home page
   - Workspace
   - Settings
   - Data types

4. Test core workflows:
   - Create new project
   - Open existing project
   - Add/edit/delete entity
   - View ER diagram
   - Generate DDL
   - Configure data types

5. Check responsive design:
   - Window resize
   - Tab overflow
   - Scroll areas

**Report:**
Return JSON:
{
  "success": boolean,
  "analyzePassed": boolean,
  "buildPassed": boolean,
  "features": {
    "homePage": "working|issues",
    "projectManagement": "working|issues",
    "workspace": "working|issues",
    "tableEditor": "working|issues",
    "erDiagram": "working|issues",
    "codeGen": "working|issues",
    "dataType": "working|issues",
    "settings": "working|issues"
  },
  "issues": ["list of remaining issues"],
  "nextSteps": ["recommended next steps"]
}
`, { schema: {
  type: 'object',
  properties: {
    success: { type: 'boolean' },
    analyzePassed: { type: 'boolean' },
    buildPassed: { type: 'boolean' },
    features: {
      type: 'object',
      properties: {
        homePage: { type: 'string' },
        projectManagement: { type: 'string' },
        workspace: { type: 'string' },
        tableEditor: { type: 'string' },
        erDiagram: { type: 'string' },
        codeGen: { type: 'string' },
        dataType: { type: 'string' },
        settings: { type: 'string' },
      },
    },
    issues: { type: 'array', items: { type: 'string' } },
    nextSteps: { type: 'array', items: { type: 'string' } },
  },
  required: ['success'],
}});

// ============================================
// Final Summary
// ============================================
log('\n========================================');
log('Bkdmm Development Workflow Complete');
log('========================================\n');

const allPhases = [
  { name: 'Fix', result: fixResult },
  { name: 'Home', result: homeResult },
  { name: 'Project', result: projectResult },
  { name: 'Settings', result: settingsResult },
  { name: 'Workspace', result: workspaceResult },
  { name: 'TableEditor', result: tableEditorResult },
  { name: 'ERDiagram', result: erDiagramResult },
  { name: 'CodeGen', result: codeGenResult },
  { name: 'DataType', result: dataTypeResult },
];

log('Phase Results:');
for (const p of allPhases) {
  log(`  ${p.result?.success ? '✅' : '⚠️'} ${p.name}`);
}

log(`\nFinal Verification:`);
log(`  Flutter Analyze: ${verifyResult.analyzePassed ? '✅ Passed' : '❌ Failed'}`);
log(`  Build: ${verifyResult.buildPassed ? '✅ Passed' : '❌ Failed'}`);

if (verifyResult.issues && verifyResult.issues.length > 0) {
  log(`\nRemaining Issues:`);
  for (const issue of verifyResult.issues) {
    log(`  - ${issue}`);
  }
}

if (verifyResult.nextSteps && verifyResult.nextSteps.length > 0) {
  log(`\nRecommended Next Steps:`);
  for (const step of verifyResult.nextSteps) {
    log(`  - ${step}`);
  }
}

return {
  status: verifyResult.success ? 'success' : 'partial',
  phases: allPhases.map(p => ({ name: p.name, success: p.result?.success ?? false })),
  verification: verifyResult,
};
