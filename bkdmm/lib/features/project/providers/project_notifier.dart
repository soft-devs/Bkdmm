import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/models/models.dart';
import '../../../shared/services/services.dart';
import '../services/project_file_service.dart';
import '../../../utils/id_generator.dart';

/// Project state - Represents the current state of the project
class ProjectState {
  /// The currently loaded project
  final Project? project;

  /// The file path of the current project
  final String? projectPath;

  /// Whether the project has unsaved changes
  final bool isDirty;

  /// Whether the project is currently loading/saving
  final bool isLoading;

  /// Any error message
  final String? error;

  /// The last save time
  final DateTime? lastSavedAt;

  /// The last auto-save time
  final DateTime? lastAutoSavedAt;

  /// Statistics about the project
  final ProjectStatistics? statistics;

  /// List of recent projects
  final List<ProjectHistory> recentProjects;

  const ProjectState({
    this.project,
    this.projectPath,
    this.isDirty = false,
    this.isLoading = false,
    this.error,
    this.lastSavedAt,
    this.lastAutoSavedAt,
    this.statistics,
    this.recentProjects = const [],
  });

  /// Whether a project is currently loaded
  bool get hasProject => project != null;

  /// Whether the project can be saved
  bool get canSave => project != null && projectPath != null && isDirty;

  /// Whether the project can be saved as
  bool get canSaveAs => project != null;

  /// Whether the project path is valid
  bool get hasValidPath => projectPath != null && projectPath!.isNotEmpty;

  /// Copy with new values
  ProjectState copyWith({
    Project? project,
    String? projectPath,
    bool? isDirty,
    bool? isLoading,
    String? error,
    DateTime? lastSavedAt,
    DateTime? lastAutoSavedAt,
    ProjectStatistics? statistics,
    List<ProjectHistory>? recentProjects,
  }) {
    return ProjectState(
      project: project ?? this.project,
      projectPath: projectPath ?? this.projectPath,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastAutoSavedAt: lastAutoSavedAt ?? this.lastAutoSavedAt,
      statistics: statistics ?? this.statistics,
      recentProjects: recentProjects ?? this.recentProjects,
    );
  }

  /// Create empty state
  static const empty = ProjectState();
}

/// Project notifier - Manages project state and operations
///
/// Provides full project management workflow including:
/// - Creating, opening, saving, and closing projects
/// - Managing project history
/// - Auto-save functionality
/// - Dirty tracking
class ProjectNotifier extends StateNotifier<ProjectState> {
  final ProjectFileService _fileService;

  /// Auto-save timer
  Timer? _autoSaveTimer;

  /// Auto-save interval in milliseconds
  static const int defaultAutoSaveInterval = 30000; // 30 seconds

  /// Whether auto-save is enabled
  bool _autoSaveEnabled = true;

  int _autoSaveInterval = defaultAutoSaveInterval;

  ProjectNotifier({
    ProjectFileService? fileService,
  })  : _fileService = fileService ?? ProjectFileService(),
        super(ProjectState.empty);

  /// Initialize the notifier
  Future<void> init() async {
    await _loadRecentProjects();
    _startAutoSaveTimer();
  }

  /// Load recent projects
  Future<void> _loadRecentProjects() async {
    final history = HistoryService.getHistoryList();
    state = state.copyWith(recentProjects: history);
  }

  /// Create a new project
  Future<ProjectOperationResult> createProject({
    required String name,
    String? description,
    String? filePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // If no file path, prompt user
      String? targetPath = filePath;
      if (targetPath == null) {
        targetPath = await _promptSavePath(defaultName: name);
        if (targetPath == null) {
          state = state.copyWith(isLoading: false);
          return ProjectOperationResult.cancelled();
        }
      }

      // Create project
      final result = await _fileService.createNewProject(
        name: name,
        description: description,
        filePath: targetPath,
      );

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return ProjectOperationResult.error(result.error!);
      }

      // Add to history
      await _addToHistory(targetPath, name);

      // Update state
      final stats = _calculateStatistics(result.project!);
      state = state.copyWith(
        project: result.project,
        projectPath: targetPath,
        isDirty: false,
        isLoading: false,
        lastSavedAt: DateTime.now(),
        statistics: stats,
      );

      return ProjectOperationResult.success(
        project: result.project!,
        path: targetPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create project: $e',
      );
      return ProjectOperationResult.error('Failed to create project: $e');
    }
  }

  /// Open an existing project
  Future<ProjectOperationResult> openProject(String? filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // If no file path, prompt user
      String? targetPath = filePath;
      if (targetPath == null) {
        targetPath = await _promptOpenPath();
        if (targetPath == null) {
          state = state.copyWith(isLoading: false);
          return ProjectOperationResult.cancelled();
        }
      }

      // Read project
      final result = await _fileService.readProjectFile(targetPath);

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return ProjectOperationResult.error(result.error!);
      }

      // Add to history
      await _addToHistory(targetPath, result.project!.name);

      // Update state
      final stats = _calculateStatistics(result.project!);
      state = state.copyWith(
        project: result.project,
        projectPath: targetPath,
        isDirty: false,
        isLoading: false,
        statistics: stats,
      );

      return ProjectOperationResult.success(
        project: result.project!,
        path: targetPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open project: $e',
      );
      return ProjectOperationResult.error('Failed to open project: $e');
    }
  }

  /// Open project from history
  Future<ProjectOperationResult> openFromHistory(ProjectHistory history) async {
    return openProject(history.path);
  }

  /// Save the current project
  Future<ProjectOperationResult> saveProject({
    bool createBackup = true,
  }) async {
    if (!state.canSave) {
      return ProjectOperationResult.error('No project to save');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _fileService.saveProjectFile(
        state.project!,
        state.projectPath!,
        createBackup: createBackup,
      );

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return ProjectOperationResult.error(result.error!);
      }

      // Update state
      state = state.copyWith(
        project: result.project,
        isDirty: false,
        isLoading: false,
        lastSavedAt: DateTime.now(),
      );

      return ProjectOperationResult.success(
        project: result.project!,
        path: state.projectPath!,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save project: $e',
      );
      return ProjectOperationResult.error('Failed to save project: $e');
    }
  }

  /// Save project as a new file
  Future<ProjectOperationResult> saveProjectAs(String? newFilePath) async {
    if (!state.canSaveAs) {
      return ProjectOperationResult.error('No project to save');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Prompt for path if not provided
      String? targetPath = newFilePath;
      if (targetPath == null) {
        targetPath = await _promptSavePath(defaultName: state.project!.name);
        if (targetPath == null) {
          state = state.copyWith(isLoading: false);
          return ProjectOperationResult.cancelled();
        }
      }

      final result = await _fileService.saveProjectAs(
        state.project!,
        targetPath,
      );

      if (!result.success) {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
        );
        return ProjectOperationResult.error(result.error!);
      }

      // Add to history
      await _addToHistory(targetPath, result.project!.name);

      // Update state
      state = state.copyWith(
        project: result.project,
        projectPath: targetPath,
        isDirty: false,
        isLoading: false,
        lastSavedAt: DateTime.now(),
      );

      return ProjectOperationResult.success(
        project: result.project!,
        path: targetPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save project: $e',
      );
      return ProjectOperationResult.error('Failed to save project: $e');
    }
  }

  /// Auto-save the project
  Future<bool> autoSave() async {
    if (!state.hasProject || !state.hasValidPath || !state.isDirty) {
      return false;
    }

    try {
      final result = await _fileService.saveProjectFile(
        state.project!,
        state.projectPath!,
        createBackup: false,
      );

      if (result.success) {
        state = state.copyWith(
          project: result.project,
          lastAutoSavedAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Close the current project
  Future<bool> closeProject({
    bool promptSave = true,
  }) async {
    if (!state.hasProject) {
      return true;
    }

    // Check if there are unsaved changes
    if (promptSave && state.isDirty) {
      // This would typically show a dialog - we'll just save
      await saveProject();
    }

    // Clear state
    state = ProjectState.empty.copyWith(
      recentProjects: state.recentProjects,
    );

    return true;
  }

  /// Update the project data
  void updateProject(Project project) {
    if (!state.hasProject) return;

    final stats = _calculateStatistics(project);
    state = state.copyWith(
      project: project,
      isDirty: true,
      statistics: stats,
    );
  }

  /// Update project name
  void updateName(String name) {
    if (!state.hasProject) return;

    final updated = state.project!.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
    updateProject(updated);
  }

  /// Update project description
  void updateDescription(String? description) {
    if (!state.hasProject) return;

    final updated = state.project!.copyWith(
      description: description,
      updatedAt: DateTime.now(),
    );
    updateProject(updated);
  }

  /// Add a module
  void addModule(Module module) {
    if (!state.hasProject) return;

    final modules = [...state.project!.modules, module];
    final updated = state.project!.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );
    updateProject(updated);
  }

  /// Remove a module
  void removeModule(String moduleId) {
    if (!state.hasProject) return;

    final modules = state.project!.modules
        .where((m) => m.id != moduleId)
        .toList();
    final updated = state.project!.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );
    updateProject(updated);
  }

  /// Update a module
  void updateModule(String moduleId, Module module) {
    if (!state.hasProject) return;

    final modules = state.project!.modules.map((m) {
      return m.id == moduleId ? module : m;
    }).toList();
    final updated = state.project!.copyWith(
      modules: modules,
      updatedAt: DateTime.now(),
    );
    updateProject(updated);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Mark as clean (no unsaved changes)
  void markClean() {
    state = state.copyWith(isDirty: false);
  }

  /// Refresh recent projects list
  Future<void> refreshRecentProjects() async {
    await _loadRecentProjects();
  }

  /// Remove from recent projects
  Future<void> removeFromRecent(String path) async {
    await HistoryService.removeHistory(path);
    await _loadRecentProjects();
  }

  /// Clear all recent projects
  Future<void> clearRecentProjects() async {
    await HistoryService.clearHistory();
    state = state.copyWith(recentProjects: []);
  }

  /// Set auto-save enabled
  void setAutoSaveEnabled(bool enabled) {
    _autoSaveEnabled = enabled;
    if (enabled) {
      _startAutoSaveTimer();
    } else {
      _stopAutoSaveTimer();
    }
  }

  /// Set auto-save interval
  void setAutoSaveInterval(int milliseconds) {
    _autoSaveInterval = milliseconds;
    _stopAutoSaveTimer();
    if (_autoSaveEnabled) {
      _startAutoSaveTimer();
    }
  }

  /// Get default data types
  List<DataType> getDefaultDataTypes() {
    return [
      DataType(
        id: '1',
        name: 'IdOrKey',
        chnname: 'Identifier Key',
        apply: {'MYSQL': 'VARCHAR(32)'},
      ),
      DataType(
        id: '2',
        name: 'Name',
        chnname: 'Name',
        apply: {'MYSQL': 'VARCHAR(128)'},
      ),
      DataType(
        id: '3',
        name: 'Intro',
        chnname: 'Introduction',
        apply: {'MYSQL': 'VARCHAR(512)'},
      ),
      DataType(
        id: '4',
        name: 'LongText',
        chnname: 'Long Text',
        apply: {'MYSQL': 'TEXT'},
      ),
      DataType(
        id: '5',
        name: 'Integer',
        chnname: 'Integer',
        apply: {'MYSQL': 'INT'},
      ),
      DataType(
        id: '6',
        name: 'Long',
        chnname: 'Long Integer',
        apply: {'MYSQL': 'BIGINT'},
      ),
      DataType(
        id: '7',
        name: 'Money',
        chnname: 'Money',
        apply: {'MYSQL': 'DECIMAL(32,8)'},
      ),
      DataType(
        id: '8',
        name: 'DateTime',
        chnname: 'Date Time',
        apply: {'MYSQL': 'DATETIME'},
      ),
      DataType(
        id: '9',
        name: 'YesNo',
        chnname: 'Yes/No',
        apply: {'MYSQL': 'VARCHAR(1)'},
      ),
      DataType(
        id: '10',
        name: 'Dict',
        chnname: 'Dictionary',
        apply: {'MYSQL': 'VARCHAR(32)'},
      ),
    ];
  }

  /// Create a new module
  Module createNewModule({
    required String name,
    required String chnname,
    String? description,
  }) {
    final now = DateTime.now();
    return Module(
      id: IdGenerator.generate(),
      name: name,
      chnname: chnname,
      description: description,
      entities: [],
      graphCanvas: GraphCanvas(),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Private helpers

  Future<String?> _promptSavePath({String? defaultName}) async {
    final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: 'Save Project',
      fileName: '${defaultName ?? 'project'}.bkdmm.json',
    );
    return result;
  }

  Future<String?> _promptOpenPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: 'Open Project',
    );
    return result?.files.first.path;
  }

  Future<void> _addToHistory(String path, String name) async {
    await HistoryService.addHistory(ProjectHistory(
      path: path,
      name: name,
      lastOpenedAt: DateTime.now(),
    ));
    await _loadRecentProjects();
  }

  ProjectStatistics _calculateStatistics(Project project) {
    int entityCount = 0;
    int fieldCount = 0;
    int relationCount = 0;

    for (final module in project.modules) {
      entityCount += module.entities.length;
      for (final entity in module.entities) {
        fieldCount += entity.fields.length;
      }
      relationCount += module.graphCanvas.edges.length;
    }

    return ProjectStatistics(
      moduleCount: project.modules.length,
      entityCount: entityCount,
      fieldCount: fieldCount,
      relationCount: relationCount,
    );
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(milliseconds: _autoSaveInterval),
      (_) => autoSave(),
    );
  }

  void _stopAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  @override
  void dispose() {
    _stopAutoSaveTimer();
    super.dispose();
  }
}

/// Result of a project operation
class ProjectOperationResult {
  final bool success;
  final bool cancelled;
  final Project? project;
  final String? path;
  final String? error;

  ProjectOperationResult._({
    required this.success,
    this.cancelled = false,
    this.project,
    this.path,
    this.error,
  });

  factory ProjectOperationResult.success({
    required Project project,
    required String path,
  }) {
    return ProjectOperationResult._(
      success: true,
      project: project,
      path: path,
    );
  }

  factory ProjectOperationResult.error(String error) {
    return ProjectOperationResult._(
      success: false,
      error: error,
    );
  }

  factory ProjectOperationResult.cancelled() {
    return ProjectOperationResult._(
      success: false,
      cancelled: true,
    );
  }
}

/// Project statistics
class ProjectStatistics {
  final int moduleCount;
  final int entityCount;
  final int fieldCount;
  final int relationCount;

  ProjectStatistics({
    required this.moduleCount,
    required this.entityCount,
    required this.fieldCount,
    required this.relationCount,
  });

  bool get isEmpty => moduleCount == 0 && entityCount == 0;
  bool get hasContent => !isEmpty;
}

/// Provider for project file service
final projectFileServiceProvider = Provider<ProjectFileService>((ref) {
  return ProjectFileService();
});

/// Provider for project notifier
final projectNotifierProvider =
    StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  final notifier = ProjectNotifier(
    fileService: ref.watch(projectFileServiceProvider),
  );
  // Initialize the notifier
  notifier.init();
  return notifier;
});

/// Convenience provider for current project
final currentProjectProvider = Provider<Project?>((ref) {
  return ref.watch(projectNotifierProvider).project;
});

/// Convenience provider for dirty state
final isProjectDirtyProvider = Provider<bool>((ref) {
  return ref.watch(projectNotifierProvider).isDirty;
});

/// Convenience provider for loading state
final isProjectLoadingProvider = Provider<bool>((ref) {
  return ref.watch(projectNotifierProvider).isLoading;
});

/// Convenience provider for project error
final projectErrorProvider = Provider<String?>((ref) {
  return ref.watch(projectNotifierProvider).error;
});

/// Convenience provider for project statistics
final projectStatisticsProvider = Provider<ProjectStatistics?>((ref) {
  return ref.watch(projectNotifierProvider).statistics;
});

/// Convenience provider for recent projects
final recentProjectsProvider = Provider<List<ProjectHistory>>((ref) {
  return ref.watch(projectNotifierProvider).recentProjects;
});

/// Convenience provider for project path
final projectPathProvider = Provider<String?>((ref) {
  return ref.watch(projectNotifierProvider).projectPath;
});

/// Provider for checking if project can be saved
final canSaveProjectProvider = Provider<bool>((ref) {
  return ref.watch(projectNotifierProvider).canSave;
});

/// Provider for checking if project can be saved as
final canSaveProjectAsProvider = Provider<bool>((ref) {
  return ref.watch(projectNotifierProvider).canSaveAs;
});