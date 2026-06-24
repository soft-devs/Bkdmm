import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project/providers/project_notifier.dart';
import '../models/project.dart';

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
