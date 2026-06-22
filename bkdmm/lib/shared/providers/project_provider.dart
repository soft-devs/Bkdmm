import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/models/models.dart';
import '../../shared/services/services.dart';

/// 文件服务 Provider
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

/// 项目状态
class ProjectState {
  final Project? project;
  final String? projectPath;
  final bool isDirty;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.project,
    this.projectPath,
    this.isDirty = false,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    Project? project,
    String? projectPath,
    bool? isDirty,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      project: project ?? this.project,
      projectPath: projectPath ?? this.projectPath,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 项目状态管理器
class ProjectNotifier extends StateNotifier<ProjectState> {
  final FileService _fileService;

  ProjectNotifier(this._fileService) : super(const ProjectState());

  /// 创建新项目
  Future<void> createProject({
    required String name,
    String? description,
    required String filePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final project = Project(
        id: _generateId(),
        name: name,
        description: description,
        version: '1.0.0',
        createdAt: now,
        updatedAt: now,
        modules: [],
        dataTypeDomains: DataTypeDomains(datatype: _getDefaultDataTypes()),
        profile: Profile(),
      );

      await _fileService.saveProject(project, filePath);

      // 添加到历史记录
      await HistoryService.addHistory(ProjectHistory(
        path: filePath,
        name: name,
        lastOpenedAt: now,
      ));

      state = ProjectState(
        project: project,
        projectPath: filePath,
        isDirty: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 打开项目
  Future<void> openProject(String? path) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      String? filePath = path;

      // 如果没有指定路径，弹出文件选择对话框
      if (filePath == null) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bkdmm.json'],
          dialogTitle: '打开项目',
        );
        filePath = result?.files.first.path;
      }

      if (filePath == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final project = await _fileService.readProject(filePath);

      // 添加到历史记录
      await HistoryService.addHistory(ProjectHistory(
        path: filePath,
        name: project.name,
        lastOpenedAt: DateTime.now(),
      ));

      state = ProjectState(
        project: project,
        projectPath: filePath,
        isDirty: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 保存项目
  Future<void> saveProject() async {
    if (state.project == null || state.projectPath == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _fileService.saveProject(state.project!, state.projectPath!);
      state = state.copyWith(isDirty: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 更新项目数据
  void updateProject(Project project) {
    state = state.copyWith(
      project: project,
      isDirty: true,
    );
  }

  /// 关闭项目
  void closeProject() {
    state = const ProjectState();
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 获取默认数据类型
  List<DataType> _getDefaultDataTypes() {
    return [
      DataType(id: '1', name: 'IdOrKey', chnname: '标识键', apply: {'MYSQL': 'VARCHAR(32)'}),
      DataType(id: '2', name: 'Name', chnname: '名称', apply: {'MYSQL': 'VARCHAR(128)'}),
      DataType(id: '3', name: 'Intro', chnname: '简介', apply: {'MYSQL': 'VARCHAR(512)'}),
      DataType(id: '4', name: 'LongText', chnname: '长文本', apply: {'MYSQL': 'TEXT'}),
      DataType(id: '5', name: 'Integer', chnname: '整数', apply: {'MYSQL': 'INT'}),
      DataType(id: '6', name: 'Long', chnname: '长整数', apply: {'MYSQL': 'BIGINT'}),
      DataType(id: '7', name: 'Money', chnname: '金额', apply: {'MYSQL': 'DECIMAL(32,8)'}),
      DataType(id: '8', name: 'DateTime', chnname: '日期时间', apply: {'MYSQL': 'DATETIME'}),
      DataType(id: '9', name: 'YesNo', chnname: '是否', apply: {'MYSQL': 'VARCHAR(1)'}),
      DataType(id: '10', name: 'Dict', chnname: '字典', apply: {'MYSQL': 'VARCHAR(32)'}),
    ];
  }
}

/// 项目 Provider
final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier(ref.watch(fileServiceProvider));
});

/// 当前项目 Provider (便捷访问)
final currentProjectProvider = Provider<Project?>((ref) {
  return ref.watch(projectProvider).project;
});

/// 项目是否脏标记 Provider
final isDirtyProvider = Provider<bool>((ref) {
  return ref.watch(projectProvider).isDirty;
});

/// 项目是否加载中 Provider
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(projectProvider).isLoading;
});

/// 项目错误 Provider
final projectErrorProvider = Provider<String?>((ref) {
  return ref.watch(projectProvider).error;
});