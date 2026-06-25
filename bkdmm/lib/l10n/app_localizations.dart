import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'Bkdmm'**
  String get appName;

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'Bkdmm - 数据建模工具'**
  String get appTitle;

  /// 欢迎语
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 Bkdmm'**
  String get welcomeTo;

  /// 应用描述
  ///
  /// In zh, this message translates to:
  /// **'数据库模型建模工具'**
  String get appDescription;

  /// 快速操作区域标题
  ///
  /// In zh, this message translates to:
  /// **'快速操作'**
  String get quickActions;

  /// 新建项目按钮
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get newProject;

  /// 创建新项目完整文本
  ///
  /// In zh, this message translates to:
  /// **'创建新项目'**
  String get createNewProject;

  /// 创建新项目描述
  ///
  /// In zh, this message translates to:
  /// **'创建一个新项目'**
  String get createNewProjectHint;

  /// 打开项目按钮
  ///
  /// In zh, this message translates to:
  /// **'打开项目'**
  String get openProject;

  /// 打开已有项目描述
  ///
  /// In zh, this message translates to:
  /// **'打开已有项目'**
  String get openExistingProject;

  /// 导入按钮
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get import;

  /// 从文件导入描述
  ///
  /// In zh, this message translates to:
  /// **'从文件导入'**
  String get importFromFile;

  /// 最近项目标题
  ///
  /// In zh, this message translates to:
  /// **'最近项目'**
  String get recentProjects;

  /// 查看全部按钮
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get viewAll;

  /// 空状态提示
  ///
  /// In zh, this message translates to:
  /// **'暂无最近项目'**
  String get noRecentProjects;

  /// 空状态提示详情
  ///
  /// In zh, this message translates to:
  /// **'创建新项目或打开已有项目开始使用'**
  String get noRecentProjectsHint;

  /// 所有最近项目对话框标题
  ///
  /// In zh, this message translates to:
  /// **'所有最近项目'**
  String get allRecentProjects;

  /// 取消按钮
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// 确认按钮
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// 删除按钮
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// 编辑按钮
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// 保存按钮
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// 关闭按钮
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// 加载状态
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// 空数据状态
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// 选择提示
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get select;

  /// 浏览按钮
  ///
  /// In zh, this message translates to:
  /// **'浏览'**
  String get browse;

  /// 恢复默认按钮
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get restoreDefaults;

  /// 恢复按钮
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get restore;

  /// 仍然删除按钮
  ///
  /// In zh, this message translates to:
  /// **'仍然删除'**
  String get deleteAnyway;

  /// 复制按钮
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// 下载按钮
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// 添加按钮
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// 复制按钮
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get duplicate;

  /// 重试按钮
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// 重置按钮
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get reset;

  /// 保存更改按钮
  ///
  /// In zh, this message translates to:
  /// **'保存更改'**
  String get saveChanges;

  /// 操作列
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get actions;

  /// 设置
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// 语言设置
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// 主题设置
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// 浅色模式
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// 深色模式
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// 跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemDefault;

  /// 项目名称
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// 项目描述
  ///
  /// In zh, this message translates to:
  /// **'项目描述'**
  String get projectDescription;

  /// 项目路径
  ///
  /// In zh, this message translates to:
  /// **'项目路径'**
  String get projectPath;

  /// 实体
  ///
  /// In zh, this message translates to:
  /// **'实体'**
  String get entity;

  /// 实体(复数)
  ///
  /// In zh, this message translates to:
  /// **'实体'**
  String get entities;

  /// 字段
  ///
  /// In zh, this message translates to:
  /// **'字段'**
  String get field;

  /// 字段(复数)
  ///
  /// In zh, this message translates to:
  /// **'字段'**
  String get fields;

  /// 索引
  ///
  /// In zh, this message translates to:
  /// **'索引'**
  String get index;

  /// 索引(复数)
  ///
  /// In zh, this message translates to:
  /// **'索引'**
  String get indexes;

  /// 关系
  ///
  /// In zh, this message translates to:
  /// **'关系'**
  String get relation;

  /// 数据类型
  ///
  /// In zh, this message translates to:
  /// **'数据类型'**
  String get dataType;

  /// 数据类型名称
  ///
  /// In zh, this message translates to:
  /// **'类型名称'**
  String get dataTypeName;

  /// 数据类型中文名称
  ///
  /// In zh, this message translates to:
  /// **'中文名称'**
  String get dataTypeChnname;

  /// 数据类型备注
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get dataTypeRemark;

  /// 添加数据类型标题
  ///
  /// In zh, this message translates to:
  /// **'添加数据类型'**
  String get addDataType;

  /// 编辑数据类型标题
  ///
  /// In zh, this message translates to:
  /// **'编辑数据类型'**
  String get editDataType;

  /// 删除数据类型标题
  ///
  /// In zh, this message translates to:
  /// **'删除数据类型'**
  String get deleteDataType;

  /// 类型正在使用标题
  ///
  /// In zh, this message translates to:
  /// **'类型正在使用'**
  String get dataTypeInUse;

  /// 添加类型按钮
  ///
  /// In zh, this message translates to:
  /// **'添加类型'**
  String get addType;

  /// 添加数据库类型按钮
  ///
  /// In zh, this message translates to:
  /// **'添加数据库类型'**
  String get addDatabaseType;

  /// 基本信息
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get basicInfo;

  /// 数据库
  ///
  /// In zh, this message translates to:
  /// **'数据库'**
  String get database;

  /// DDL生成
  ///
  /// In zh, this message translates to:
  /// **'DDL 生成'**
  String get ddlGeneration;

  /// 选择数据库
  ///
  /// In zh, this message translates to:
  /// **'选择数据库'**
  String get selectDatabase;

  /// 选择DDL类型
  ///
  /// In zh, this message translates to:
  /// **'选择 DDL 类型'**
  String get selectDdlType;

  /// 生成DDL按钮
  ///
  /// In zh, this message translates to:
  /// **'生成 DDL'**
  String get generateDdl;

  /// DDL生成成功
  ///
  /// In zh, this message translates to:
  /// **'DDL 已生成'**
  String get ddlGenerated;

  /// 下载SQL按钮
  ///
  /// In zh, this message translates to:
  /// **'下载 .sql'**
  String get downloadSql;

  /// 导出全部按钮
  ///
  /// In zh, this message translates to:
  /// **'导出全部'**
  String get exportAll;

  /// 概览标签页
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get summary;

  /// 预览标签页
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// 添加字段按钮
  ///
  /// In zh, this message translates to:
  /// **'添加字段'**
  String get addField;

  /// 编辑字段标题
  ///
  /// In zh, this message translates to:
  /// **'编辑字段'**
  String get editField;

  /// 删除字段标题
  ///
  /// In zh, this message translates to:
  /// **'删除字段'**
  String get deleteField;

  /// 字段名称
  ///
  /// In zh, this message translates to:
  /// **'字段名称'**
  String get fieldName;

  /// 字段中文名称
  ///
  /// In zh, this message translates to:
  /// **'中文名称'**
  String get fieldChnname;

  /// 字段类型
  ///
  /// In zh, this message translates to:
  /// **'字段类型'**
  String get fieldType;

  /// 字段长度
  ///
  /// In zh, this message translates to:
  /// **'长度'**
  String get fieldLength;

  /// 字段小数位
  ///
  /// In zh, this message translates to:
  /// **'小数位'**
  String get fieldDecimal;

  /// 字段默认值
  ///
  /// In zh, this message translates to:
  /// **'默认值'**
  String get fieldDefault;

  /// 字段备注
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get fieldRemark;

  /// 主键
  ///
  /// In zh, this message translates to:
  /// **'主键'**
  String get primaryKey;

  /// 非空
  ///
  /// In zh, this message translates to:
  /// **'非空'**
  String get notNull;

  /// 自增
  ///
  /// In zh, this message translates to:
  /// **'自增'**
  String get autoIncrement;

  /// 选择数据类型标题
  ///
  /// In zh, this message translates to:
  /// **'选择数据类型'**
  String get selectDataType;

  /// 字段名称必填提示
  ///
  /// In zh, this message translates to:
  /// **'字段名称不能为空'**
  String get fieldNameRequired;

  /// 添加索引按钮
  ///
  /// In zh, this message translates to:
  /// **'添加索引'**
  String get addIndex;

  /// 编辑索引标题
  ///
  /// In zh, this message translates to:
  /// **'编辑索引'**
  String get editIndex;

  /// 删除索引标题
  ///
  /// In zh, this message translates to:
  /// **'删除索引'**
  String get deleteIndex;

  /// 索引名称
  ///
  /// In zh, this message translates to:
  /// **'索引名称'**
  String get indexName;

  /// 索引类型
  ///
  /// In zh, this message translates to:
  /// **'索引类型'**
  String get indexType;

  /// 选择索引类型标题
  ///
  /// In zh, this message translates to:
  /// **'选择索引类型'**
  String get selectIndexType;

  /// 选择字段提示
  ///
  /// In zh, this message translates to:
  /// **'选择字段'**
  String get selectFields;

  /// 索引名称必填提示
  ///
  /// In zh, this message translates to:
  /// **'索引名称不能为空'**
  String get indexNameRequired;

  /// 选择字段提示
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个字段'**
  String get selectAtLeastOneField;

  /// 主键标签
  ///
  /// In zh, this message translates to:
  /// **'主键'**
  String get primaryKeys;

  /// 编辑字段按钮
  ///
  /// In zh, this message translates to:
  /// **'编辑字段'**
  String get editFields;

  /// 实体更新成功提示
  ///
  /// In zh, this message translates to:
  /// **'实体已更新'**
  String get entityUpdated;

  /// 打开按钮
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get open;

  /// 取消收藏按钮
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get removeFromFavorites;

  /// 收藏按钮
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get addToFavorites;

  /// 从列表移除按钮
  ///
  /// In zh, this message translates to:
  /// **'从列表移除'**
  String get removeFromList;

  /// 功能即将推出提示
  ///
  /// In zh, this message translates to:
  /// **'功能即将推出'**
  String get featureComingSoon;

  /// 项目创建成功
  ///
  /// In zh, this message translates to:
  /// **'项目已创建'**
  String get projectCreated;

  /// 项目打开成功
  ///
  /// In zh, this message translates to:
  /// **'项目已打开'**
  String get projectOpened;

  /// 创建项目失败
  ///
  /// In zh, this message translates to:
  /// **'创建项目失败'**
  String get failedToCreateProject;

  /// 打开项目失败
  ///
  /// In zh, this message translates to:
  /// **'打开项目失败'**
  String get failedToOpenProject;

  /// 移除成功
  ///
  /// In zh, this message translates to:
  /// **'已从最近项目中移除'**
  String get removedFromRecent;

  /// 移除失败
  ///
  /// In zh, this message translates to:
  /// **'移除失败'**
  String get failedToRemove;

  /// DDL复制成功提示
  ///
  /// In zh, this message translates to:
  /// **'DDL 已复制到剪贴板'**
  String get ddlCopiedToClipboard;

  /// 准备下载提示
  ///
  /// In zh, this message translates to:
  /// **'准备下载: {fileName}'**
  String readyToDownload(String fileName);

  /// 生成DDL进度提示
  ///
  /// In zh, this message translates to:
  /// **'正在为 {count} 个模块生成 DDL...'**
  String generatingDdlForModules(int count);

  /// DDL准备完成提示
  ///
  /// In zh, this message translates to:
  /// **'DDL 已准备好: {fileName}'**
  String ddlReadyFor(String fileName);

  /// 删除确认标题
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get deleteConfirmTitle;

  /// 删除确认消息
  ///
  /// In zh, this message translates to:
  /// **'确定要删除 \"{name}\" 吗？'**
  String deleteConfirmMessage(String name);

  /// 恢复默认确认
  ///
  /// In zh, this message translates to:
  /// **'确定要恢复默认设置吗？'**
  String get restoreDefaultsConfirm;

  /// 类型使用中消息
  ///
  /// In zh, this message translates to:
  /// **'该数据类型正在被以下字段使用：'**
  String get typeInUseMessage;

  /// 简体中文
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// 英文
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
