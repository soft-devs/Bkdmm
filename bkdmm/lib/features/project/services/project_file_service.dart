import 'dart:io';
import 'dart:convert';
import '../../shared/models/models.dart';
import '../../shared/services/file_service.dart';
import '../../utils/id_generator.dart';

/// Project file service - Handles project file read/write operations
///
/// Provides specialized file operations for project files including:
/// - Reading and writing project files
/// - File validation
/// - Backup management
/// - Auto-save functionality
class ProjectFileService {
  final FileService _fileService;

  /// Current file version for new projects
  static const String currentFileVersion = '1.0.0';

  /// File extension for project files
  static const String fileExtension = 'bkdmm.json';

  ProjectFileService({FileService? fileService})
      : _fileService = fileService ?? FileService();

  /// Create a new project with default configuration
  Future<ProjectCreateResult> createNewProject({
    required String name,
    String? description,
    required String filePath,
  }) async {
    try {
      final now = DateTime.now();
      final project = Project(
        id: IdGenerator.generate(),
        name: name,
        description: description,
        version: currentFileVersion,
        createdAt: now,
        updatedAt: now,
        modules: [],
        dataTypeDomains: DataTypeDomains(datatype: _getDefaultDataTypes()),
        profile: Profile(),
      );

      await saveProjectFile(project, filePath);

      return ProjectCreateResult.success(
        project: project,
        filePath: filePath,
      );
    } catch (e) {
      return ProjectCreateResult.error('Failed to create project: $e');
    }
  }

  /// Read project from file
  Future<ProjectReadResult> readProjectFile(String filePath) async {
    try {
      // Check file existence
      if (!await _fileService.fileExists(filePath)) {
        return ProjectReadResult.error('Project file not found: $filePath');
      }

      // Read and parse project
      final project = await _fileService.readProject(filePath);

      // Validate project
      final validationResult = await validateProjectFile(filePath);
      if (!validationResult.isValid) {
        return ProjectReadResult.error(
          'Invalid project file: ${validationResult.errors.join(", ")}',
        );
      }

      return ProjectReadResult.success(
        project: project,
        filePath: filePath,
      );
    } on ProjectFileException catch (e) {
      return ProjectReadResult.error(e.message);
    } catch (e) {
      return ProjectReadResult.error('Failed to read project: $e');
    }
  }

  /// Save project to file
  Future<ProjectSaveResult> saveProjectFile(
    Project project,
    String filePath, {
    bool createBackup = true,
  }) async {
    try {
      // Create backup if file exists and backup is requested
      if (createBackup && await _fileService.fileExists(filePath)) {
        await _fileService.createBackup(filePath);
      }

      // Update timestamps
      final updatedProject = project.copyWith(
        updatedAt: DateTime.now(),
      );

      // Save project
      await _fileService.saveProject(updatedProject, filePath);

      return ProjectSaveResult.success(
        project: updatedProject,
        filePath: filePath,
      );
    } on ProjectFileException catch (e) {
      return ProjectSaveResult.error(e.message);
    } catch (e) {
      return ProjectSaveResult.error('Failed to save project: $e');
    }
  }

  /// Save project with new file path (Save As)
  Future<ProjectSaveResult> saveProjectAs(
    Project project,
    String newFilePath,
  ) async {
    try {
      // Create new project with updated timestamps
      final now = DateTime.now();
      final updatedProject = project.copyWith(
        updatedAt: now,
      );

      await _fileService.saveProject(updatedProject, newFilePath);

      return ProjectSaveResult.success(
        project: updatedProject,
        filePath: newFilePath,
      );
    } catch (e) {
      return ProjectSaveResult.error('Failed to save project as: $e');
    }
  }

  /// Validate project file
  Future<ProjectValidationResult> validateProjectFile(String filePath) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      if (!await _fileService.fileExists(filePath)) {
        return ProjectValidationResult(
          isValid: false,
          errors: ['File does not exist'],
          warnings: [],
        );
      }

      final project = await _fileService.readProject(filePath);

      // Validate required fields
      if (project.id.isEmpty) {
        errors.add('Project ID is required');
      }

      if (project.name.isEmpty) {
        errors.add('Project name is required');
      }

      // Validate modules
      final moduleNames = <String>{};
      for (final module in project.modules) {
        if (module.name.isEmpty) {
          errors.add('Module has empty name');
        }
        if (moduleNames.contains(module.name)) {
          warnings.add('Duplicate module name: ${module.name}');
        }
        moduleNames.add(module.name);

        // Validate entities
        final entityNames = <String>{};
        for (final entity in module.entities) {
          if (entity.title.isEmpty) {
            errors.add('Entity has empty title in module ${module.name}');
          }
          if (entityNames.contains(entity.title)) {
            warnings.add('Duplicate entity title: ${entity.title} in module ${module.name}');
          }
          entityNames.add(entity.title);

          // Validate fields
          final fieldNames = <String>{};
          for (final field in entity.fields) {
            if (field.name.isEmpty) {
              errors.add('Field has empty name in entity ${entity.title}');
            }
            if (fieldNames.contains(field.name)) {
              warnings.add('Duplicate field name: ${field.name} in entity ${entity.title}');
            }
            fieldNames.add(field.name);
          }
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
        errors: ['Failed to parse project file: $e'],
        warnings: [],
      );
    }
  }

  /// Check if file is a valid project file
  Future<bool> isValidProjectFile(String filePath) async {
    try {
      if (!filePath.endsWith('.$fileExtension')) {
        return false;
      }

      final result = await validateProjectFile(filePath);
      return result.isValid;
    } catch (_) {
      return false;
    }
  }

  /// Get file information
  Future<ProjectFileInfo?> getFileInfo(String filePath) async {
    try {
      final info = await _fileService.getFileInfo(filePath);
      if (info == null) return null;

      final project = await _fileService.readProject(filePath);

      return ProjectFileInfo(
        path: filePath,
        name: project.name,
        size: info.size,
        modifiedTime: info.modifiedTime,
        moduleCount: project.modules.length,
        entityCount: project.modules.fold(0, (sum, m) => sum + m.entities.length),
      );
    } catch (_) {
      return null;
    }
  }

  /// Create automatic backup
  Future<String?> createAutoSave(String filePath) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final autoSavePath = '$filePath.autosave.$timestamp';
      await _fileService.copyFile(filePath, autoSavePath);
      return autoSavePath;
    } catch (_) {
      return null;
    }
  }

  /// Clean up old auto-save files
  Future<void> cleanupAutoSaveFiles(
    String filePath, {
    int keepCount = 5,
  }) async {
    try {
      final file = File(filePath);
      final dir = file.parent;
      final baseName = file.uri.pathSegments.last;

      final autoSaveFiles = await dir
          .list()
          .where((entity) =>
              entity.path.startsWith('${file.path}.autosave.'))
          .toList();

      // Sort by modification time (newest first)
      autoSaveFiles.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      // Delete old files
      for (var i = keepCount; i < autoSaveFiles.length; i++) {
        await autoSaveFiles[i].delete();
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  /// Get default data types for new projects
  List<DataType> _getDefaultDataTypes() {
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
}

/// Result of project creation operation
class ProjectCreateResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;

  ProjectCreateResult._({
    required this.success,
    this.project,
    this.filePath,
    this.error,
  });

  factory ProjectCreateResult.success({
    required Project project,
    required String filePath,
  }) {
    return ProjectCreateResult._(
      success: true,
      project: project,
      filePath: filePath,
    );
  }

  factory ProjectCreateResult.error(String error) {
    return ProjectCreateResult._(
      success: false,
      error: error,
    );
  }
}

/// Result of project read operation
class ProjectReadResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;

  ProjectReadResult._({
    required this.success,
    this.project,
    this.filePath,
    this.error,
  });

  factory ProjectReadResult.success({
    required Project project,
    required String filePath,
  }) {
    return ProjectReadResult._(
      success: true,
      project: project,
      filePath: filePath,
    );
  }

  factory ProjectReadResult.error(String error) {
    return ProjectReadResult._(
      success: false,
      error: error,
    );
  }
}

/// Result of project save operation
class ProjectSaveResult {
  final bool success;
  final Project? project;
  final String? filePath;
  final String? error;

  ProjectSaveResult._({
    required this.success,
    this.project,
    this.filePath,
    this.error,
  });

  factory ProjectSaveResult.success({
    required Project project,
    required String filePath,
  }) {
    return ProjectSaveResult._(
      success: true,
      project: project,
      filePath: filePath,
    );
  }

  factory ProjectSaveResult.error(String error) {
    return ProjectSaveResult._(
      success: false,
      error: error,
    );
  }
}

/// Result of project validation
class ProjectValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ProjectValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Project file information
class ProjectFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final int moduleCount;
  final int entityCount;

  ProjectFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.moduleCount,
    required this.entityCount,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
