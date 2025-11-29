import 'package:uuid/uuid.dart';

/// ID 產生工具
class IdUtils {
  IdUtils._(); // 防止實例化

  static const _uuid = Uuid();

  /// 產生新的 UUID v4
  static String generate() => _uuid.v4();

  /// 根據種子產生 hash ID (用於通知 ID 等)
  static int hashId(String seed) => seed.hashCode & 0x7fffffff;
}

// 為了向後相容，保留原本的全域函數
String newId() => IdUtils.generate();
