import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用设置状态
class SettingsState {
  /// 主题模式: 'system', 'light', 'dark'
  final String themeMode;

  /// 语言代码: 'zh', 'en'
  final String locale;

  /// 是否显示欢迎页面
  final bool showWelcomePage;

  /// 最近使用的数据库类型
  final String? defaultDatabase;

  /// 自动保存间隔(秒), 0表示禁用
  final int autoSaveInterval;

  /// 是否启用自动备份
  final bool enableAutoBackup;

  /// 备份保留数量
  final int backupRetentionCount;

  /// 编辑器字体大小
  final double editorFontSize;

  /// 是否启用代码提示
  final bool enableCodeCompletion;

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
    };
  }
}

/// 设置状态管理器
class SettingsNotifier extends StateNotifier<SettingsState> {
  // Settings key for persistent storage (reserved for future use)
  // static const String _settingsKey = 'app_settings';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  /// 从存储加载设置
  void _loadSettings() {
    // TODO: 实现从持久化存储加载设置
    // 当前使用默认值，后续可集成 shared_preferences 或 hive
  }

  /// 保存设置到存储
  Future<void> _saveSettings() async {
    // TODO: 实现持久化存储保存
    // 当前仅更新内存状态，后续可集成 shared_preferences 或 hive
  }

  /// 更新主题模式
  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// 更新语言
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _saveSettings();
  }

  /// 设置是否显示欢迎页面
  Future<void> setShowWelcomePage(bool show) async {
    state = state.copyWith(showWelcomePage: show);
    await _saveSettings();
  }

  /// 设置默认数据库
  Future<void> setDefaultDatabase(String? database) async {
    state = state.copyWith(defaultDatabase: database);
    await _saveSettings();
  }

  /// 设置自动保存间隔
  Future<void> setAutoSaveInterval(int interval) async {
    state = state.copyWith(autoSaveInterval: interval);
    await _saveSettings();
  }

  /// 设置是否启用自动备份
  Future<void> setEnableAutoBackup(bool enable) async {
    state = state.copyWith(enableAutoBackup: enable);
    await _saveSettings();
  }

  /// 设置备份保留数量
  Future<void> setBackupRetentionCount(int count) async {
    state = state.copyWith(backupRetentionCount: count);
    await _saveSettings();
  }

  /// 设置编辑器字体大小
  Future<void> setEditorFontSize(double size) async {
    state = state.copyWith(editorFontSize: size);
    await _saveSettings();
  }

  /// 设置是否启用代码提示
  Future<void> setEnableCodeCompletion(bool enable) async {
    state = state.copyWith(enableCodeCompletion: enable);
    await _saveSettings();
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    state = const SettingsState();
    await _saveSettings();
  }

  /// 批量更新设置
  Future<void> updateSettings(SettingsState newSettings) async {
    state = newSettings;
    await _saveSettings();
  }
}

/// 设置 Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// 主题模式 Provider (便捷访问)
final themeModeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// 语言 Provider (便捷访问)
final localeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).locale;
});

/// 是否显示欢迎页面 Provider (便捷访问)
final showWelcomePageProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showWelcomePage;
});

/// 默认数据库 Provider (便捷访问)
final defaultDatabaseProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).defaultDatabase;
});

/// 自动保存间隔 Provider (便捷访问)
final autoSaveIntervalProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).autoSaveInterval;
});

/// 是否启用自动备份 Provider (便捷访问)
final enableAutoBackupProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableAutoBackup;
});

/// 备份保留数量 Provider (便捷访问)
final backupRetentionCountProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).backupRetentionCount;
});

/// 编辑器字体大小 Provider (便捷访问)
final editorFontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).editorFontSize;
});

/// 是否启用代码提示 Provider (便捷访问)
final enableCodeCompletionProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableCodeCompletion;
});
