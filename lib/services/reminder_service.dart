import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ReminderService {
  /// 前景掃描：到時間就把提醒寫入 Announcements（簡易版）。
  static void sweep(BuildContext context) {
    final app = context.read<AppState>();
    final now = DateTime.now();

    for (final hw in app.homeworks) {
      if (hw['doneAt'] != null) continue;
      final DateTime? remindAt = hw['reminderAt'] != null
          ? DateTime.tryParse(hw['reminderAt'])
          : null;
      if (remindAt != null &&
          remindAt.isBefore(now) &&
          hw['__announced__'] != true) {
        app.pushAnnouncement(
          'Homework reminder',
          '${hw['title']} is due on ${(hw['due'] as String).substring(0, 10)}',
        );
        hw['__announced__'] = true;
      }
    }
  }
}
