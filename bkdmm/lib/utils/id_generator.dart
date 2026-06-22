import 'package:uuid/uuid.dart';

/// ID 生成器
class IdGenerator {
  IdGenerator._();

  static final _uuid = const Uuid();

  /// 生成唯一 ID
  static String generate() {
    return _uuid.v4();
  }

  /// 生成短 ID (8位)
  static String generateShort() {
    return _uuid.v4().substring(0, 8);
  }

  /// 生成时间戳 ID
  static String generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 生成带前缀的 ID
  static String generateWithPrefix(String prefix) {
    return '${prefix}_$_uuid.v4()';
  }
}