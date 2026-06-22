export const meta = {
  name: 'bkdmm-flutter-init',
  description: 'Initialize Bkdmm Flutter project with complete architecture',
  phases: [
    { title: 'Research', detail: 'Research Flutter desktop best practices' },
    { title: 'Architecture', detail: 'Update architecture documentation' },
    { title: 'Dependencies', detail: 'Configure Flutter dependencies' },
    { title: 'Models', detail: 'Create core data models' },
    { title: 'Services', detail: 'Implement service layer' },
    { title: 'State', detail: 'Setup Riverpod state management' },
    { title: 'UI', detail: 'Build basic UI framework' },
    { title: 'Project', detail: 'Implement project management' },
    { title: 'Verify', detail: 'Verify and test project' },
  ],
}

// Phase 1: Research Flutter desktop best practices
phase('Research')
log('Researching Flutter desktop development patterns...')

const flutterResearch = await agent(`
Research Flutter desktop application development best practices for a data modeling tool. Focus on:
1. Flutter Windows desktop app architecture patterns
2. Riverpod state management best practices
3. Hive/Isar local storage patterns
4. File picker and file system operations in Flutter
5. CustomPainter for graph visualization
6. Tab-based workspace management

Return a structured summary of key patterns and recommendations.
`, { label: 'flutter-desktop-research', phase: 'Research' })

// Phase 2: Update architecture documentation
phase('Architecture')
log('Updating architecture documentation for Flutter...')

const archUpdate = await agent(`
Based on the existing documentation at F:/projects/Bkdmm/docs, update the architecture to reflect Flutter-specific patterns.
Key changes needed:
1. Update TECH-ARCHITECTURE.md to describe Flutter 4-layer architecture
2. Ensure all feature docs use Flutter/Dart code examples
3. Add Flutter-specific ADR (Architecture Decision Records)

Read the existing docs and update them to be Flutter-native.
`, { label: 'architecture-update', phase: 'Architecture', isolation: 'worktree' })

// Phase 3: Configure dependencies
phase('Dependencies')
log('Configuring Flutter dependencies...')

const depsConfig = await agent(`
Update the Flutter pubspec.yaml at F:/projects/Bkdmm/bkdmm/pubspec.yaml to include:
- flutter_riverpod: ^2.4.0 (state management)
- hive_flutter: ^1.1.0 (local storage)
- file_picker: ^8.0.0 (file operations)
- path_provider: ^2.1.0 (path utilities)
- json_annotation: ^4.8.0 (JSON serialization)
- uuid: ^4.0.0 (ID generation)
- intl: ^0.19.0 (internationalization)
- syncfusion_flutter_datagrid: ^24.1.0 (data grid)

Also add dev_dependencies:
- build_runner: ^2.4.0
- json_serializable: ^6.7.0
- hive_generator: ^2.0.0

Update the pubspec.yaml file with these dependencies.
`, { label: 'dependencies-config', phase: 'Dependencies', isolation: 'worktree' })

// Phase 4: Create core data models
phase('Models')
log('Creating core data models...')

const modelsCreate = await agent(`
Create the core Dart data models for the Bkdmm project at F:/projects/Bkdmm/bkdmm/lib/shared/models/.
Based on the data model design at F:/projects/Bkdmm/docs/data-model/README.md, create:
1. project.dart - Project model with JSON serialization
2. module.dart - Module, GraphCanvas, GraphNode, GraphEdge models
3. entity.dart - Entity, Field, Index models
4. data_type.dart - DataTypeDomains, DataType, DatabaseTemplate models
5. version.dart - VersionSnapshot, ChangeRecord models
6. project_history.dart - ProjectHistory model

Use json_annotation for serialization. Create the directory structure and files.
`, { label: 'models-create', phase: 'Models', isolation: 'worktree' })

// Phase 5: Implement service layer
phase('Services')
log('Implementing service layer...')

const servicesCreate = await agent(`
Create the service layer at F:/projects/Bkdmm/bkdmm/lib/shared/services/.
Based on the project management design at F:/projects/Bkdmm/docs/features/project/README.md, create:
1. storage_service.dart - Hive storage initialization and operations
2. file_service.dart - File read/write operations
3. history_service.dart - Project history management
4. project_service.dart - Combined project operations service

Create the directory structure and implement these services.
`, { label: 'services-create', phase: 'Services', isolation: 'worktree' })

// Phase 6: Setup state management
phase('State')
log('Setting up Riverpod state management...')

const stateSetup = await agent(`
Create Riverpod providers at F:/projects/Bkdmm/bkdmm/lib/shared/providers/.
Based on the project management design, create:
1. project_provider.dart - Current project state management
2. history_provider.dart - Project history state
3. settings_provider.dart - App settings state

Use StateNotifierProvider pattern for each. Create the providers.
`, { label: 'state-setup', phase: 'State', isolation: 'worktree' })

// Phase 7: Build UI framework
phase('UI')
log('Building basic UI framework...')

const uiBuild = await agent(`
Create the basic UI framework at F:/projects/Bkdmm/bkdmm/lib/.
Create:
1. app/app_theme.dart - Material Design 3 theme configuration
2. app/main.dart - Updated app entry point with Riverpod
3. features/home/views/home_view.dart - Home page with project history
4. features/home/widgets/history_list_tile.dart - History list tile widget
5. shared/widgets/app_scaffold.dart - Common scaffold widget
6. shared/widgets/loading_overlay.dart - Loading indicator

Create the directory structure and implement these UI components.
`, { label: 'ui-build', phase: 'UI', isolation: 'worktree' })

// Phase 8: Implement project management
phase('Project')
log('Implementing project management feature...')

const projectImpl = await agent(`
Complete the project management feature at F:/projects/Bkdmm/bkdmm/lib/features/project/.
Create:
1. services/project_file_service.dart - Project file read/write
2. services/data_migration.dart - Data version migration
3. views/create_project_dialog.dart - New project creation dialog
4. views/open_project_dialog.dart - Open project dialog
5. providers/project_notifier.dart - Full project state notifier

Implement the complete project management workflow.
`, { label: 'project-impl', phase: 'Project', isolation: 'worktree' })

// Phase 9: Verify project
phase('Verify')
log('Verifying project structure...')

const verifyResult = await agent(`
Verify the Flutter project at F:/projects/Bkdmm/bkdmm/ is correctly set up:
1. Check all directories exist (lib/shared/models, lib/shared/services, lib/shared/providers, lib/features/project, etc.)
2. Check pubspec.yaml has all required dependencies
3. Check main.dart correctly initializes Riverpod and Hive
4. List all created Dart files
5. Run flutter analyze if possible and report any errors

Return a comprehensive verification report.
`, { label: 'verify-project', phase: 'Verify' })

// Return final summary
return {
  flutterResearch,
  archUpdate,
  depsConfig,
  modelsCreate,
  servicesCreate,
  stateSetup,
  uiBuild,
  projectImpl,
  verifyResult,
  summary: 'Bkdmm Flutter project initialization completed. Check verification report for any issues.'
}