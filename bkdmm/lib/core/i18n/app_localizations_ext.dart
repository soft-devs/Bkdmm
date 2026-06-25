import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// AppLocalizations 扩展方法
///
/// 提供简洁的访问方式
extension AppLocalizationsExt on BuildContext {
  /// 获取本地化实例
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// 获取本地化实例（可空）
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}