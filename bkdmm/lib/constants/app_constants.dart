/// 应用常量
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = 'Bkdmm';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 项目文件扩展名
  static const String projectFileExtension = 'bkdmm.json';

  /// 项目文件筛选器
  static const String projectFileFilter = 'Bkdmm Project (*.bkdmm.json)';

  /// 默认数据类型配置
  static const String defaultDataTypeConfig = 'assets/datatypes/default_types.json';

  /// 最大历史记录数量
  static const int maxHistoryCount = 20;

  /// 自动保存间隔（秒）
  static const int autoSaveIntervalSeconds = 30;

  /// ER 图节点默认宽度
  static const double erNodeDefaultWidth = 200;

  /// ER 图节点默认行高
  static const double erNodeRowHeight = 24;

  /// ER 图节点标题栏高度
  static const double erNodeHeaderHeight = 32;

  /// 支持的数据库类型
  static const List<String> supportedDatabases = [
    'MYSQL',
    'ORACLE',
    'POSTGRESQL',
    'SQLSERVER',
    'SQLITE',
  ];
}