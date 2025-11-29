import 'package:intl/intl.dart';

/// 日期時間格式化工具
class FormatUtils {
  FormatUtils._(); // 防止實例化

  static final dateFmt = DateFormat('yyyy-MM-dd');
  static final timeFmt = DateFormat('HH:mm');
  static final dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');

  /// 格式化為人類可讀的到期日 (e.g., "Mon, Dec 25")
  static String humanDue(DateTime d) => DateFormat('EEE, MMM d').format(d);

  /// 秒數轉成 "HH:mm" 格式
  static String hhmm(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// 秒數轉成 "HH:mm:ss" 格式
  static String hhmmss(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 取得今天的日期字串 (yyyy-MM-dd)
  static String todayKey() => dateFmt.format(DateTime.now());

  /// 判斷兩個日期是否為同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判斷日期是否為今天
  static bool isToday(DateTime d) => isSameDay(d, DateTime.now());
}

// 為了向後相容，保留原本的全域函數
final dateFmt = FormatUtils.dateFmt;
final timeFmt = FormatUtils.timeFmt;
String humanDue(DateTime d) => FormatUtils.humanDue(d);
String hhmm(int seconds) => FormatUtils.hhmm(seconds);
