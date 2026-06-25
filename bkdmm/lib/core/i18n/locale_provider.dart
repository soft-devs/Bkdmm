import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 支持的语言列表
const List<Locale> supportedLocales = [
  Locale('zh'),
  Locale('en'),
];

/// 语言代码映射
final Map<Locale, String> localeNames = {
  Locale('zh'): '简体中文',
  Locale('en'): 'English',
};

/// 语言状态
class LocaleState {
  final Locale locale;

  const LocaleState(this.locale);

  /// 是否为中文
  bool get isChinese => locale.languageCode == 'zh';

  /// 获取语言显示名称
  String get displayName => localeNames[locale] ?? 'Unknown';
}

/// 语言 Notifier
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _key = 'locale_language_code';

  LocaleNotifier() : super(const LocaleState(Locale('zh'))) {
    _loadFromStorage();
  }

  /// 从存储加载语言设置
  Future<void> _loadFromStorage() async {
    final box = Hive.box('settings');
    final languageCode = box.get(_key) as String?;

    if (languageCode != null) {
      final locale = Locale(languageCode);
      if (supportedLocales.contains(locale)) {
        state = LocaleState(locale);
      }
    }
  }

  /// 切换语言
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;

    final box = Hive.box('settings');
    await box.put(_key, locale.languageCode);

    state = LocaleState(locale);
  }

  /// 切换到下一个语言
  Future<void> toggleLanguage() async {
    final currentIndex = supportedLocales.indexOf(state.locale);
    final nextIndex = (currentIndex + 1) % supportedLocales.length;
    await setLocale(supportedLocales[nextIndex]);
  }
}

/// 语言 Provider
final appLocaleProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(),
);

// 保持向后兼容的别名
final localeProvider = appLocaleProvider;