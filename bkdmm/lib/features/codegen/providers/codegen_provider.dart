import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/providers.dart';
import '../services/codegen_service.dart';

/// Code generation state
class CodegenState {
  /// Selected database code
  final String selectedDatabase;

  /// Generated DDL output
  final String generatedDdl;

  /// Whether DDL is currently being generated
  final bool isGenerating;

  /// Currently selected entity (for single entity preview)
  final Entity? selectedEntity;

  /// Currently selected module (for module preview)
  final Module? selectedModule;

  /// Whether to generate for entire project
  final bool generateProject;

  /// Selected generation type
  final DdlType ddlType;

  /// Error message if any
  final String? error;

  const CodegenState({
    this.selectedDatabase = 'MYSQL',
    this.generatedDdl = '',
    this.isGenerating = false,
    this.selectedEntity,
    this.selectedModule,
    this.generateProject = false,
    this.ddlType = DdlType.createTable,
    this.error,
  });

  CodegenState copyWith({
    String? selectedDatabase,
    String? generatedDdl,
    bool? isGenerating,
    Entity? selectedEntity,
    Module? selectedModule,
    bool? generateProject,
    DdlType? ddlType,
    String? error,
    bool clearEntity = false,
    bool clearModule = false,
    bool clearError = false,
  }) {
    return CodegenState(
      selectedDatabase: selectedDatabase ?? this.selectedDatabase,
      generatedDdl: generatedDdl ?? this.generatedDdl,
      isGenerating: isGenerating ?? this.isGenerating,
      selectedEntity: clearEntity ? null : (selectedEntity ?? this.selectedEntity),
      selectedModule: clearModule ? null : (selectedModule ?? this.selectedModule),
      generateProject: generateProject ?? this.generateProject,
      ddlType: ddlType ?? this.ddlType,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether there's DDL to display
  bool get hasOutput => generatedDdl.isNotEmpty;

  /// Whether an entity is selected
  bool get hasEntity => selectedEntity != null;

  /// Whether a module is selected
  bool get hasModule => selectedModule != null;
}

/// Notifier for managing code generation state
class CodegenNotifier extends StateNotifier<CodegenState> {
  final Ref _ref;
  final CodegenService _codegenService;

  CodegenNotifier(this._ref, {CodegenService? codegenService})
      : _codegenService = codegenService ?? CodegenService(),
        super(const CodegenState());

  /// Get available databases
  List<DatabaseTemplate> get databases => _codegenService.getDefaultDatabases();

  /// Get current database template
  DatabaseTemplate? get currentDatabase {
    return databases.firstWhere(
      (db) => db.code == state.selectedDatabase,
      orElse: () => databases.first,
    );
  }

  /// Select database
  void selectDatabase(String databaseCode) {
    state = state.copyWith(selectedDatabase: databaseCode);
    _regenerateDdl();
  }

  /// Select an entity for preview
  void selectEntity(Entity entity) {
    state = state.copyWith(
      selectedEntity: entity,
      clearModule: true,
      generateProject: false,
    );
    _regenerateDdl();
  }

  /// Select a module for preview
  void selectModule(Module module) {
    state = state.copyWith(
      selectedModule: module,
      clearEntity: true,
      generateProject: false,
    );
    _regenerateDdl();
  }

  /// Select entire project for generation
  void selectProject() {
    state = state.copyWith(
      generateProject: true,
      clearEntity: true,
      clearModule: true,
    );
    _regenerateDdl();
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(
      clearEntity: true,
      clearModule: true,
      generateProject: false,
      generatedDdl: '',
    );
  }

  /// Set DDL type
  void setDdlType(DdlType type) {
    state = state.copyWith(ddlType: type);
    _regenerateDdl();
  }

  /// Regenerate DDL based on current selection
  void _regenerateDdl() {
    final project = _ref.read(currentProjectProvider);
    if (project == null) {
      state = state.copyWith(generatedDdl: '', clearError: true);
      return;
    }

    final dataTypes = _ref.read(dataTypeProvider);

    try {
      String ddl = '';

      if (state.selectedEntity != null) {
        // Generate for single entity
        final entity = state.selectedEntity!;
        final dbTemplate = currentDatabase;

        switch (state.ddlType) {
          case DdlType.createTable:
            ddl = _codegenService.generateCreateTable(
              entity,
              databaseCode: state.selectedDatabase,
              dataTypes: dataTypes,
              dbTemplate: dbTemplate,
            );
            break;
          case DdlType.dropTable:
            ddl = _codegenService.generateDropTable(
              entity,
              databaseCode: state.selectedDatabase,
              dbTemplate: dbTemplate,
            );
            break;
          case DdlType.createIndex:
            if (entity.indexes.isNotEmpty) {
              ddl = entity.indexes
                  .map((index) => _codegenService.generateCreateIndex(
                        entity,
                        index,
                        databaseCode: state.selectedDatabase,
                        dbTemplate: dbTemplate,
                      ))
                  .join('\n\n');
            }
            break;
          case DdlType.dropIndex:
            if (entity.indexes.isNotEmpty) {
              ddl = entity.indexes
                  .map((index) => _codegenService.generateDropIndex(
                        entity,
                        index,
                        databaseCode: state.selectedDatabase,
                        dbTemplate: dbTemplate,
                      ))
                  .join('\n');
            }
            break;
          default:
            // Generate all DDL for entity
            ddl = _codegenService.generateAllDdl(
              entity,
              databaseCode: state.selectedDatabase,
              dataTypes: dataTypes,
              dbTemplate: dbTemplate,
            );
        }
      } else if (state.selectedModule != null) {
        // Generate for module
        ddl = _codegenService.generateModuleDdl(
          state.selectedModule!,
          databaseCode: state.selectedDatabase,
          dataTypes: dataTypes,
          dbTemplate: currentDatabase,
        );
      } else if (state.generateProject) {
        // Generate for entire project
        ddl = _codegenService.generateProjectDdl(
          project,
          databaseCode: state.selectedDatabase,
          dataTypes: dataTypes,
          dbTemplate: currentDatabase,
        );
      }

      state = state.copyWith(generatedDdl: ddl, clearError: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to generate DDL: $e');
    }
  }

  /// Generate DDL for a specific entity
  String generateEntityDdl(Entity entity) {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return '';

    final dataTypes = _ref.read(dataTypeProvider);
    final dbTemplate = currentDatabase;

    return _codegenService.generateAllDdl(
      entity,
      databaseCode: state.selectedDatabase,
      dataTypes: dataTypes,
      dbTemplate: dbTemplate,
    );
  }

  /// Generate DDL for a specific module
  String generateModuleDdl(Module module) {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return '';

    final dataTypes = _ref.read(dataTypeProvider);

    return _codegenService.generateModuleDdl(
      module,
      databaseCode: state.selectedDatabase,
      dataTypes: dataTypes,
      dbTemplate: currentDatabase,
    );
  }

  /// Generate DDL for the entire project
  String generateProjectDdl() {
    final project = _ref.read(currentProjectProvider);
    if (project == null) return '';

    final dataTypes = _ref.read(dataTypeProvider);

    return _codegenService.generateProjectDdl(
      project,
      databaseCode: state.selectedDatabase,
      dataTypes: dataTypes,
      dbTemplate: currentDatabase,
    );
  }

  /// Refresh generated DDL
  void refresh() {
    _regenerateDdl();
  }
}

/// Provider for codegen service
final codegenServiceProvider = Provider<CodegenService>((ref) {
  return CodegenService();
});

/// Provider for codegen state
final codegenProvider =
    StateNotifierProvider<CodegenNotifier, CodegenState>((ref) {
  return CodegenNotifier(ref);
});

/// Provider for available databases
final availableDatabasesProvider = Provider<List<DatabaseTemplate>>((ref) {
  final codegen = ref.watch(codegenProvider.notifier);
  return codegen.databases;
});

/// Provider for current database template
final currentDatabaseTemplateProvider = Provider<DatabaseTemplate?>((ref) {
  final state = ref.watch(codegenProvider);
  final databases = ref.watch(availableDatabasesProvider);
  return databases.firstWhere(
    (db) => db.code == state.selectedDatabase,
    orElse: () => databases.first,
  );
});