import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project/providers/project_notifier.dart';
import '../models/project.dart';
import 'settings_provider.dart';

/// Project-specific settings state
///
/// These settings can override global settings for a specific project.
/// Settings can be inherited from global settings or customized.
class ProjectSettingsState {
  /// Project ID these settings belong to
  final String projectId;

  // === Inheritance flags ===
  /// Whether to inherit default fields settings from global settings
  final bool inheritDefaultFields;

  /// Whether to inherit default database from global settings
  final bool inheritDefaultDatabase;

  // === Project-specific settings ===
  /// Default fields for new tables (project-specific)
  final bool? defaultFieldsRevision;
  final bool? defaultFieldsCreatedBy;
  final bool? defaultFieldsCreatedTime;
  final bool? defaultFieldsUpdatedBy;
  final bool? defaultFieldsUpdatedTime;

  /// Default database (project-specific)
  final String? defaultDatabase;

  /// Custom project settings stored in profile.settings
  final Map<String, dynamic>? customSettings;

  const ProjectSettingsState({
    required this.projectId,
    this.inheritDefaultFields = true,
    this.inheritDefaultDatabase = true,
    this.defaultFieldsRevision,
    this.defaultFieldsCreatedBy,
    this.defaultFieldsCreatedTime,
    this.defaultFieldsUpdatedBy,
    this.defaultFieldsUpdatedTime,
    this.defaultDatabase,
    this.customSettings,
  });

  /// Create from Project's Profile
  factory ProjectSettingsState.fromProfile(String projectId, Map<String, dynamic>? profileSettings) {
    if (profileSettings == null) {
      return ProjectSettingsState(projectId: projectId);
    }

    return ProjectSettingsState(
      projectId: projectId,
      inheritDefaultFields: profileSettings['inheritDefaultFields'] as bool? ?? true,
      inheritDefaultDatabase: profileSettings['inheritDefaultDatabase'] as bool? ?? true,
      defaultFieldsRevision: profileSettings['defaultFieldsRevision'] as bool?,
      defaultFieldsCreatedBy: profileSettings['defaultFieldsCreatedBy'] as bool?,
      defaultFieldsCreatedTime: profileSettings['defaultFieldsCreatedTime'] as bool?,
      defaultFieldsUpdatedBy: profileSettings['defaultFieldsUpdatedBy'] as bool?,
      defaultFieldsUpdatedTime: profileSettings['defaultFieldsUpdatedTime'] as bool?,
      defaultDatabase: profileSettings['defaultDatabase'] as String?,
      customSettings: profileSettings['customSettings'] as Map<String, dynamic>?,
    );
  }

  /// Convert to storage map (stored in profile.settings)
  Map<String, dynamic> toStorageMap() {
    return {
      'inheritDefaultFields': inheritDefaultFields,
      'inheritDefaultDatabase': inheritDefaultDatabase,
      if (defaultFieldsRevision != null) 'defaultFieldsRevision': defaultFieldsRevision,
      if (defaultFieldsCreatedBy != null) 'defaultFieldsCreatedBy': defaultFieldsCreatedBy,
      if (defaultFieldsCreatedTime != null) 'defaultFieldsCreatedTime': defaultFieldsCreatedTime,
      if (defaultFieldsUpdatedBy != null) 'defaultFieldsUpdatedBy': defaultFieldsUpdatedBy,
      if (defaultFieldsUpdatedTime != null) 'defaultFieldsUpdatedTime': defaultFieldsUpdatedTime,
      if (defaultDatabase != null) 'defaultDatabase': defaultDatabase,
      if (customSettings != null) 'customSettings': customSettings,
    };
  }

  ProjectSettingsState copyWith({
    String? projectId,
    bool? inheritDefaultFields,
    bool? inheritDefaultDatabase,
    bool? defaultFieldsRevision,
    bool? defaultFieldsCreatedBy,
    bool? defaultFieldsCreatedTime,
    bool? defaultFieldsUpdatedBy,
    bool? defaultFieldsUpdatedTime,
    String? defaultDatabase,
    Map<String, dynamic>? customSettings,
  }) {
    return ProjectSettingsState(
      projectId: projectId ?? this.projectId,
      inheritDefaultFields: inheritDefaultFields ?? this.inheritDefaultFields,
      inheritDefaultDatabase: inheritDefaultDatabase ?? this.inheritDefaultDatabase,
      defaultFieldsRevision: defaultFieldsRevision ?? this.defaultFieldsRevision,
      defaultFieldsCreatedBy: defaultFieldsCreatedBy ?? this.defaultFieldsCreatedBy,
      defaultFieldsCreatedTime: defaultFieldsCreatedTime ?? this.defaultFieldsCreatedTime,
      defaultFieldsUpdatedBy: defaultFieldsUpdatedBy ?? this.defaultFieldsUpdatedBy,
      defaultFieldsUpdatedTime: defaultFieldsUpdatedTime ?? this.defaultFieldsUpdatedTime,
      defaultDatabase: defaultDatabase ?? this.defaultDatabase,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Project settings notifier - manages project-specific settings
class ProjectSettingsNotifier extends StateNotifier<ProjectSettingsState?> {
  final Ref _ref;

  ProjectSettingsNotifier(this._ref) : super(null);

  /// Load settings from current project
  void loadFromProject(Project? project) {
    if (project == null) {
      state = null;
      return;
    }

    final settings = project.profile.settings;
    state = ProjectSettingsState.fromProfile(project.id, settings);
  }

  /// Clear settings (when project is closed)
  void clear() {
    state = null;
  }

  /// Update inheritance for default fields
  Future<void> setInheritDefaultFields(bool inherit) async {
    if (state == null) return;
    state = state!.copyWith(inheritDefaultFields: inherit);
    await _saveToProject();
  }

  /// Update inheritance for default database
  Future<void> setInheritDefaultDatabase(bool inherit) async {
    if (state == null) return;
    state = state!.copyWith(inheritDefaultDatabase: inherit);
    await _saveToProject();
  }

  /// Set default fields - revision
  Future<void> setDefaultFieldsRevision(bool? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultFieldsRevision: value);
    await _saveToProject();
  }

  /// Set default fields - created by
  Future<void> setDefaultFieldsCreatedBy(bool? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultFieldsCreatedBy: value);
    await _saveToProject();
  }

  /// Set default fields - created time
  Future<void> setDefaultFieldsCreatedTime(bool? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultFieldsCreatedTime: value);
    await _saveToProject();
  }

  /// Set default fields - updated by
  Future<void> setDefaultFieldsUpdatedBy(bool? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultFieldsUpdatedBy: value);
    await _saveToProject();
  }

  /// Set default fields - updated time
  Future<void> setDefaultFieldsUpdatedTime(bool? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultFieldsUpdatedTime: value);
    await _saveToProject();
  }

  /// Set default database
  Future<void> setDefaultDatabase(String? value) async {
    if (state == null) return;
    state = state!.copyWith(defaultDatabase: value);
    await _saveToProject();
  }

  /// Reset project settings to defaults (inherit all)
  Future<void> resetToDefaults() async {
    if (state == null) return;
    state = ProjectSettingsState(projectId: state!.projectId);
    await _saveToProject();
  }

  /// Save settings to project profile
  Future<void> _saveToProject() async {
    if (state == null) return;

    final projectNotifier = _ref.read(projectNotifierProvider.notifier);
    final currentProject = _ref.read(currentProjectProvider);

    if (currentProject == null) return;

    // Update project profile with new settings
    final updatedProfile = currentProject.profile.copyWith(
      settings: state!.toStorageMap(),
    );

    final updatedProject = currentProject.copyWith(
      profile: updatedProfile,
      updatedAt: DateTime.now(),
    );

    projectNotifier.updateProject(updatedProject);
  }
}

/// Project settings provider
final projectSettingsProvider =
    StateNotifierProvider<ProjectSettingsNotifier, ProjectSettingsState?>((ref) {
  return ProjectSettingsNotifier(ref);
});

/// Provider to check if project settings are available
final hasProjectSettingsProvider = Provider<bool>((ref) {
  return ref.watch(projectSettingsProvider) != null;
});

/// Effective default fields provider - resolves project/global inheritance
///
/// Returns the effective default fields settings that should be used
/// when creating new tables. Resolves inheritance hierarchy:
/// 1. If project settings exist and not inheriting -> use project settings
/// 2. If project settings exist and inheriting -> use global settings
/// 3. If no project settings -> use global settings
final effectiveDefaultFieldsProvider = Provider<EffectiveDefaultFields>((ref) {
  final projectSettings = ref.watch(projectSettingsProvider);
  final globalSettings = ref.watch(settingsProvider);

  // If no project or project inherits from global
  if (projectSettings == null || projectSettings.inheritDefaultFields) {
    return EffectiveDefaultFields(
      revision: globalSettings.defaultFieldsRevision,
      createdBy: globalSettings.defaultFieldsCreatedBy,
      createdTime: globalSettings.defaultFieldsCreatedTime,
      updatedBy: globalSettings.defaultFieldsUpdatedBy,
      updatedTime: globalSettings.defaultFieldsUpdatedTime,
      source: 'global',
    );
  }

  // Project has custom settings - use project values (fallback to global for nulls)
  return EffectiveDefaultFields(
    revision: projectSettings.defaultFieldsRevision ?? globalSettings.defaultFieldsRevision,
    createdBy: projectSettings.defaultFieldsCreatedBy ?? globalSettings.defaultFieldsCreatedBy,
    createdTime: projectSettings.defaultFieldsCreatedTime ?? globalSettings.defaultFieldsCreatedTime,
    updatedBy: projectSettings.defaultFieldsUpdatedBy ?? globalSettings.defaultFieldsUpdatedBy,
    updatedTime: projectSettings.defaultFieldsUpdatedTime ?? globalSettings.defaultFieldsUpdatedTime,
    source: 'project',
  );
});

/// Effective default database provider - resolves project/global inheritance
final effectiveDefaultDatabaseProvider = Provider<String?>((ref) {
  final projectSettings = ref.watch(projectSettingsProvider);
  final globalSettings = ref.watch(settingsProvider);

  if (projectSettings == null || projectSettings.inheritDefaultDatabase) {
    return globalSettings.defaultDatabase;
  }

  return projectSettings.defaultDatabase ?? globalSettings.defaultDatabase;
});

/// Effective default fields data class
class EffectiveDefaultFields {
  final bool revision;
  final bool createdBy;
  final bool createdTime;
  final bool updatedBy;
  final bool updatedTime;
  final String source; // 'global' or 'project'

  const EffectiveDefaultFields({
    required this.revision,
    required this.createdBy,
    required this.createdTime,
    required this.updatedBy,
    required this.updatedTime,
    required this.source,
  });

  /// Generate default field templates for a new entity
  /// Returns a list of Field objects based on enabled default fields
  List<Map<String, dynamic>> generateDefaultFieldTemplates() {
    final fields = <Map<String, dynamic>>[];

    if (revision) {
      fields.add({
        'name': 'REVISION',
        'chnname': '乐观锁',
        'type': 'Integer',
        'pk': false,
        'notNull': true,
        'autoIncrement': false,
        'remark': 'Optimistic lock version',
      });
    }

    if (createdBy) {
      fields.add({
        'name': 'CREATED_BY',
        'chnname': '创建人',
        'type': 'IdOrKey',
        'pk': false,
        'notNull': true,
        'autoIncrement': false,
        'remark': 'Creator ID',
      });
    }

    if (createdTime) {
      fields.add({
        'name': 'CREATED_TIME',
        'chnname': '创建时间',
        'type': 'DateTime',
        'pk': false,
        'notNull': true,
        'autoIncrement': false,
        'remark': 'Creation timestamp',
      });
    }

    if (updatedBy) {
      fields.add({
        'name': 'UPDATED_BY',
        'chnname': '更新人',
        'type': 'IdOrKey',
        'pk': false,
        'notNull': true,
        'autoIncrement': false,
        'remark': 'Updater ID',
      });
    }

    if (updatedTime) {
      fields.add({
        'name': 'UPDATED_TIME',
        'chnname': '更新时间',
        'type': 'DateTime',
        'pk': false,
        'notNull': true,
        'autoIncrement': false,
        'remark': 'Update timestamp',
      });
    }

    return fields;
  }
}
