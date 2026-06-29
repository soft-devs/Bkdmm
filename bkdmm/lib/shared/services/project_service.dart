import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import 'file_service.dart';
import 'history_service.dart';
import '../../utils/id_generator.dart';

/// 项目服务 - 整合项目操作的统一入口
///
/// 提供项目创建、打开、保存、历史记录管理等核心功能
class ProjectService {
  final FileService _fileService;
  final int _maxHistoryCount;

  ProjectService({
    FileService? fileService,
    int maxHistoryCount = 20,
  })  : _fileService = fileService ?? FileService(),
        _maxHistoryCount = maxHistoryCount;

  /// 创建新项目
  Future<ProjectResult> createProject({
    required String name,
    String? description,
    String? filePath,
  }) async {
    try {
      // 如果未指定路径，弹出保存对话框
      String? targetPath = filePath;
      if (targetPath == null) {
        targetPath = await _pickSavePath(defaultName: name);
        if (targetPath == null) {
          return ProjectResult.cancelled();
        }
      }

      final now = DateTime.now();
      final project = Project(
        id: IdGenerator.generate(),
        name: name,
        description: description,
        version: '1.0.0',
        createdAt: now,
        updatedAt: now,
        modules: [],
        dataTypeDomains: DataTypeDomains(datatype: _getDefaultDataTypes()),
        profile: Profile(),
      );

      await _fileService.saveProject(project, targetPath);

      // 添加到历史记录
      await _addToHistory(targetPath, name);

      return ProjectResult.success(project: project, path: targetPath);
    } catch (e) {
      return ProjectResult.error(e.toString());
    }
  }

  /// 打开项目
  Future<ProjectResult> openProject({String? filePath}) async {
    try {
      // 如果未指定路径，弹出打开对话框
      String? targetPath = filePath;
      if (targetPath == null) {
        targetPath = await _pickOpenPath();
        if (targetPath == null) {
          return ProjectResult.cancelled();
        }
      }

      // 检查文件是否存在
      if (!await _fileService.fileExists(targetPath)) {
        return ProjectResult.error('项目文件不存在: $targetPath');
      }

      final project = await _fileService.readProject(targetPath);

      // 添加到历史记录
      await _addToHistory(targetPath, project.name);

      return ProjectResult.success(project: project, path: targetPath);
    } catch (e) {
      return ProjectResult.error('打开项目失败: $e');
    }
  }

  /// 保存项目
  Future<ProjectResult> saveProject(Project project, String filePath) async {
    try {
      await _fileService.saveProject(project, filePath);
      return ProjectResult.success(project: project, path: filePath);
    } catch (e) {
      return ProjectResult.error('保存项目失败: $e');
    }
  }

  /// 另存为
  Future<ProjectResult> saveProjectAs(Project project, {String? filePath}) async {
    try {
      String? targetPath = filePath;
      if (targetPath == null) {
        targetPath = await _pickSavePath(defaultName: project.name);
        if (targetPath == null) {
          return ProjectResult.cancelled();
        }
      }

      // 创建更新后的项目副本
      final savedProject = project.copyWith(
        updatedAt: DateTime.now(),
      );

      await _fileService.saveProject(savedProject, targetPath);

      // 添加到历史记录
      await _addToHistory(targetPath, project.name);

      return ProjectResult.success(project: savedProject, path: targetPath);
    } catch (e) {
      return ProjectResult.error('另存为失败: $e');
    }
  }

  /// 创建项目备份
  Future<String?> createBackup(String filePath) async {
    try {
      return await _fileService.createBackup(filePath);
    } catch (e) {
      return null;
    }
  }

  /// 获取历史记录列表
  List<ProjectHistory> getHistoryList() {
    return HistoryService.getHistoryList();
  }

  /// 删除历史记录
  Future<void> removeHistory(String path) async {
    await HistoryService.removeHistory(path);
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    await HistoryService.clearHistory();
  }

  /// 检查历史记录是否存在
  bool hasHistory(String path) {
    return HistoryService.hasHistory(path);
  }

  /// 更新历史记录缩略图
  Future<void> updateHistoryThumbnail(String path, String thumbnail) async {
    await HistoryService.updateThumbnail(path, thumbnail);
  }

  /// 验证项目文件
  Future<ProjectValidationResult> validateProject(String filePath) async {
    try {
      if (!await _fileService.fileExists(filePath)) {
        return ProjectValidationResult(
          isValid: false,
          errors: ['文件不存在'],
        );
      }

      final project = await _fileService.readProject(filePath);
      final errors = <String>[];
      final warnings = <String>[];

      // 验证项目基本属性
      if (project.name.isEmpty) {
        errors.add('项目名称不能为空');
      }

      if (project.id.isEmpty) {
        errors.add('项目ID不能为空');
      }

      // 验证模块
      for (final module in project.modules) {
        if (module.name.isEmpty) {
          errors.add('存在未命名的模块');
        }
      }

      return ProjectValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return ProjectValidationResult(
        isValid: false,
        errors: ['解析项目文件失败: $e'],
      );
    }
  }

  /// 获取项目统计信息
  ProjectStatistics getStatistics(Project project) {
    int entityCount = 0;
    int fieldCount = 0;
    int relationCount = 0;

    for (final module in project.modules) {
      entityCount += module.entities.length;
      for (final entity in module.entities) {
        fieldCount += entity.fields.length;
      }
    }

    return ProjectStatistics(
      moduleCount: project.modules.length,
      entityCount: entityCount,
      fieldCount: fieldCount,
      relationCount: relationCount,
    );
  }

  /// 弹出文件保存对话框
  Future<String?> _pickSavePath({String? defaultName}) async {
    final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: '保存项目',
      fileName: '${defaultName ?? 'project'}.bkdmm.json',
    );
    return result;
  }

  /// 弹出文件打开对话框
  Future<String?> _pickOpenPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bkdmm.json'],
      dialogTitle: '打开项目',
    );
    return result?.files.first.path;
  }

  /// 添加到历史记录
  Future<void> _addToHistory(String path, String name) async {
    await HistoryService.addHistory(ProjectHistory(
      path: path,
      name: name,
      lastOpenedAt: DateTime.now(),
    ));

    // 限制历史记录数量
    final history = HistoryService.getHistoryList();
    if (history.length > _maxHistoryCount) {
      for (var i = _maxHistoryCount; i < history.length; i++) {
        await HistoryService.removeHistory(history[i].path);
      }
    }
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

/// 项目操作结果
class ProjectResult {
  final bool success;
  final bool cancelled;
  final Project? project;
  final String? path;
  final String? error;

  ProjectResult._({
    required this.success,
    this.cancelled = false,
    this.project,
    this.path,
    this.error,
  });

  factory ProjectResult.success({required Project project, required String path}) {
    return ProjectResult._(
      success: true,
      project: project,
      path: path,
    );
  }

  factory ProjectResult.error(String error) {
    return ProjectResult._(
      success: false,
      error: error,
    );
  }

  factory ProjectResult.cancelled() {
    return ProjectResult._(
      success: false,
      cancelled: true,
    );
  }
}

/// 项目验证结果
class ProjectValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ProjectValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// 项目统计信息
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
}
