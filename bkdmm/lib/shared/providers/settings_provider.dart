import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// Application settings state
class SettingsState {
  /// Theme mode: 'system', 'light', 'dark'
  final String themeMode;

  /// Language code: 'zh', 'en'
  final String locale;

  /// Whether to show welcome page
  final bool showWelcomePage;

  /// Default database type
  final String? defaultDatabase;

  /// Auto-save interval (seconds), 0 means disabled
  final int autoSaveInterval;

  /// Whether to enable auto backup
  final bool enableAutoBackup;

  /// Backup retention count
  final int backupRetentionCount;

  /// Editor font size
  final double editorFontSize;

  /// Whether to enable code completion
  final bool enableCodeCompletion;

  /// Show line numbers in code preview
  final bool showLineNumbers;

  /// Accent color (as 32-bit integer)
  final int? accentColor;

  /// Default fields for new tables
  final bool defaultFieldsRevision;
  final bool defaultFieldsCreatedBy;
  final bool defaultFieldsCreatedTime;
  final bool defaultFieldsUpdatedBy;
  final bool defaultFieldsUpdatedTime;

  const SettingsState({
    this.themeMode = 'system',
    this.locale = 'zh',
    this.showWelcomePage = true,
    this.defaultDatabase,
    this.autoSaveInterval = 60,
    this.enableAutoBackup = true,
    this.backupRetentionCount = 10,
    this.editorFontSize = 14.0,
    this.enableCodeCompletion = true,
    this.showLineNumbers = true,
    this.accentColor,
    this.defaultFieldsRevision = true,
    this.defaultFieldsCreatedBy = true,
    this.defaultFieldsCreatedTime = true,
    this.defaultFieldsUpdatedBy = true,
    this.defaultFieldsUpdatedTime = true,
  });

  SettingsState copyWith({
    String? themeMode,
    String? locale,
    bool? showWelcomePage,
    String? defaultDatabase,
    int? autoSaveInterval,
    bool? enableAutoBackup,
    int? backupRetentionCount,
    double? editorFontSize,
    bool? enableCodeCompletion,
    bool? showLineNumbers,
    int? accentColor,
    bool? defaultFieldsRevision,
    bool? defaultFieldsCreatedBy,
    bool? defaultFieldsCreatedTime,
    bool? defaultFieldsUpdatedBy,
    bool? defaultFieldsUpdatedTime,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      showWelcomePage: showWelcomePage ?? this.showWelcomePage,
      defaultDatabase: defaultDatabase ?? this.defaultDatabase,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      backupRetentionCount: backupRetentionCount ?? this.backupRetentionCount,
      editorFontSize: editorFontSize ?? this.editorFontSize,
      enableCodeCompletion: enableCodeCompletion ?? this.enableCodeCompletion,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      accentColor: accentColor ?? this.accentColor,
      defaultFieldsRevision: defaultFieldsRevision ?? this.defaultFieldsRevision,
      defaultFieldsCreatedBy: defaultFieldsCreatedBy ?? this.defaultFieldsCreatedBy,
      defaultFieldsCreatedTime: defaultFieldsCreatedTime ?? this.defaultFieldsCreatedTime,
      defaultFieldsUpdatedBy: defaultFieldsUpdatedBy ?? this.defaultFieldsUpdatedBy,
      defaultFieldsUpdatedTime: defaultFieldsUpdatedTime ?? this.defaultFieldsUpdatedTime,
    );
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: json['themeMode'] as String? ?? 'system',
      locale: json['locale'] as String? ?? 'zh',
      showWelcomePage: json['showWelcomePage'] as bool? ?? true,
      defaultDatabase: json['defaultDatabase'] as String?,
      autoSaveInterval: json['autoSaveInterval'] as int? ?? 60,
      enableAutoBackup: json['enableAutoBackup'] as bool? ?? true,
      backupRetentionCount: json['backupRetentionCount'] as int? ?? 10,
      editorFontSize: (json['editorFontSize'] as num?)?.toDouble() ?? 14.0,
      enableCodeCompletion: json['enableCodeCompletion'] as bool? ?? true,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      accentColor: json['accentColor'] as int?,
      defaultFieldsRevision: json['defaultFieldsRevision'] as bool? ?? true,
      defaultFieldsCreatedBy: json['defaultFieldsCreatedBy'] as bool? ?? true,
      defaultFieldsCreatedTime: json['defaultFieldsCreatedTime'] as bool? ?? true,
      defaultFieldsUpdatedBy: json['defaultFieldsUpdatedBy'] as bool? ?? true,
      defaultFieldsUpdatedTime: json['defaultFieldsUpdatedTime'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'locale': locale,
      'showWelcomePage': showWelcomePage,
      'defaultDatabase': defaultDatabase,
      'autoSaveInterval': autoSaveInterval,
      'enableAutoBackup': enableAutoBackup,
      'backupRetentionCount': backupRetentionCount,
      'editorFontSize': editorFontSize,
      'enableCodeCompletion': enableCodeCompletion,
      'showLineNumbers': showLineNumbers,
      'accentColor': accentColor,
      'defaultFieldsRevision': defaultFieldsRevision,
      'defaultFieldsCreatedBy': defaultFieldsCreatedBy,
      'defaultFieldsCreatedTime': defaultFieldsCreatedTime,
      'defaultFieldsUpdatedBy': defaultFieldsUpdatedBy,
      'defaultFieldsUpdatedTime': defaultFieldsUpdatedTime,
    };
  }

  /// Get the ThemeMode enum from themeMode string
  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Get accent color as Color object
  Color? get accentColorValue {
    if (accentColor == null) return null;
    return Color(accentColor!);
  }
}

/// Settings state manager
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _settingsKey = 'app_settings';
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(const SettingsState()) {
    _loadSettings();
  }

  /// Load settings from storage
  void _loadSettings() {
    try {
      final settingsJson = _storageService.getSetting<Map<dynamic, dynamic>>(
        _settingsKey,
        defaultValue: null,
      );

      if (settingsJson != null) {
        final convertedJson = Map<String, dynamic>.from(settingsJson);
        state = SettingsState.fromJson(convertedJson);
      }
    } catch (e) {
      // If loading fails, use default settings
      state = const SettingsState();
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      await _storageService.saveSetting(_settingsKey, state.toJson());
    } catch (e) {
      // Log error but don't crash
      debugPrint('Failed to save settings: $e');
    }
  }

  /// Update theme mode
  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// Update language
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _saveSettings();
  }

  /// Set whether to show welcome page
  Future<void> setShowWelcomePage(bool show) async {
    state = state.copyWith(showWelcomePage: show);
    await _saveSettings();
  }

  /// Set default database
  Future<void> setDefaultDatabase(String? database) async {
    state = state.copyWith(defaultDatabase: database);
    await _saveSettings();
  }

  /// Set auto-save interval
  Future<void> setAutoSaveInterval(int interval) async {
    state = state.copyWith(autoSaveInterval: interval);
    await _saveSettings();
  }

  /// Set whether to enable auto backup
  Future<void> setEnableAutoBackup(bool enable) async {
    state = state.copyWith(enableAutoBackup: enable);
    await _saveSettings();
  }

  /// Set backup retention count
  Future<void> setBackupRetentionCount(int count) async {
    state = state.copyWith(backupRetentionCount: count);
    await _saveSettings();
  }

  /// Set editor font size
  Future<void> setEditorFontSize(double size) async {
    state = state.copyWith(editorFontSize: size);
    await _saveSettings();
  }

  /// Set whether to enable code completion
  Future<void> setEnableCodeCompletion(bool enable) async {
    state = state.copyWith(enableCodeCompletion: enable);
    await _saveSettings();
  }

  /// Set whether to show line numbers
  Future<void> setShowLineNumbers(bool show) async {
    state = state.copyWith(showLineNumbers: show);
    await _saveSettings();
  }

  /// Set accent color
  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color.toARGB32());
    await _saveSettings();
  }

  /// Set default fields - revision
  Future<void> setDefaultFieldsRevision(bool value) async {
    state = state.copyWith(defaultFieldsRevision: value);
    await _saveSettings();
  }

  /// Set default fields - created by
  Future<void> setDefaultFieldsCreatedBy(bool value) async {
    state = state.copyWith(defaultFieldsCreatedBy: value);
    await _saveSettings();
  }

  /// Set default fields - created time
  Future<void> setDefaultFieldsCreatedTime(bool value) async {
    state = state.copyWith(defaultFieldsCreatedTime: value);
    await _saveSettings();
  }

  /// Set default fields - updated by
  Future<void> setDefaultFieldsUpdatedBy(bool value) async {
    state = state.copyWith(defaultFieldsUpdatedBy: value);
    await _saveSettings();
  }

  /// Set default fields - updated time
  Future<void> setDefaultFieldsUpdatedTime(bool value) async {
    state = state.copyWith(defaultFieldsUpdatedTime: value);
    await _saveSettings();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = const SettingsState();
    await _saveSettings();
  }

  /// Batch update settings
  Future<void> updateSettings(SettingsState newSettings) async {
    state = newSettings;
    await _saveSettings();
  }
}

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Settings Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SettingsNotifier(storageService);
});

/// Theme mode Provider (convenient access)
final themeModeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Language Provider (convenient access)
final localeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).locale;
});

/// Whether to show welcome page Provider (convenient access)
final showWelcomePageProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showWelcomePage;
});

/// Default database Provider (convenient access)
final defaultDatabaseProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).defaultDatabase;
});

/// Auto-save interval Provider (convenient access)
final autoSaveIntervalProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).autoSaveInterval;
});

/// Whether to enable auto backup Provider (convenient access)
final enableAutoBackupProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableAutoBackup;
});

/// Backup retention count Provider (convenient access)
final backupRetentionCountProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).backupRetentionCount;
});

/// Editor font size Provider (convenient access)
final editorFontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).editorFontSize;
});

/// Whether to enable code completion Provider (convenient access)
final enableCodeCompletionProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableCodeCompletion;
});

/// Show line numbers Provider (convenient access)
final showLineNumbersProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showLineNumbers;
});

/// Accent color Provider (convenient access)
final accentColorProvider = Provider<Color?>((ref) {
  return ref.watch(settingsProvider).accentColorValue;
});
