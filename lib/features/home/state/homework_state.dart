import 'package:flutter/foundation.dart';
import '../../../core/models/homework.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/id.dart';
import '../../../core/services/notification_service.dart';

/// Homework 狀態管理
class HomeworkState extends ChangeNotifier {
  static const _storageKey = 'homeworks';

  List<Homework> _homeworks = [];

  /// 所有作業
  List<Homework> get homeworks => List.unmodifiable(_homeworks);

  /// 未完成的作業（依到期日排序）
  List<Homework> get visibleHomeworks =>
      _homeworks.where((h) => !h.isDone).toList()
        ..sort((a, b) => a.due.compareTo(b.due));

  /// 今天到期的作業
  List<Homework> todayHomeworks(DateTime now) {
    return _homeworks.where((h) {
      return h.due.year == now.year &&
          h.due.month == now.month &&
          h.due.day == now.day;
    }).toList();
  }

  /// 今天的完成數量
  int todayDoneCount(DateTime now) {
    return todayHomeworks(now).where((h) => h.isDone).length;
  }

  /// 今天的總數量
  int todayTotalCount(DateTime now) {
    return todayHomeworks(now).length;
  }

  /// 載入資料
  Future<void> load() async {
    final list = await StorageService.instance.getList(_storageKey);
    _homeworks = list
        .map((e) => Homework.fromJson(e as Map<String, dynamic>))
        .toList();
    _sort();
    notifyListeners();

    // 重新安排未來的提醒
    await _rescheduleAllReminders();
  }

  Future<void> _save() async {
    await StorageService.instance.setJson(
      _storageKey,
      _homeworks.map((h) => h.toJson()).toList(),
    );
  }

  void _sort() {
    _homeworks.sort((a, b) => a.due.compareTo(b.due));
  }

  /// 新增作業
  Future<void> add({
    required String title,
    required String content,
    required DateTime due,
    String? reminderType,
    DateTime? reminderAt,
    String? color,
  }) async {
    final homework = Homework(
      id: IdUtils.generate(),
      title: title,
      content: content,
      due: due,
      reminderType: reminderType,
      reminderAt: reminderAt,
      color: color,
    );
    _homeworks.add(homework);
    _sort();
    await _save();
    notifyListeners();

    // 安排提醒
    await _scheduleReminderIfNeeded(homework);
  }

  /// 更新作業
  Future<void> update(Homework homework) async {
    final index = _homeworks.indexWhere((h) => h.id == homework.id);
    if (index >= 0) {
      _homeworks[index] = homework;
      _sort();
      await _save();
      notifyListeners();

      // 更新提醒
      await _scheduleReminderIfNeeded(homework);
    }
  }

  /// 標記完成
  Future<void> complete(String id) async {
    final index = _homeworks.indexWhere((h) => h.id == id);
    if (index >= 0) {
      _homeworks[index] = _homeworks[index].copyWith(doneAt: DateTime.now());
      await _save();
      notifyListeners();
    }
  }

  /// 取消完成
  Future<void> uncomplete(String id) async {
    final index = _homeworks.indexWhere((h) => h.id == id);
    if (index >= 0) {
      _homeworks[index] = _homeworks[index].copyWith(clearDoneAt: true);
      await _save();
      notifyListeners();
    }
  }

  /// 刪除作業
  Future<void> remove(String id) async {
    _homeworks.removeWhere((h) => h.id == id);
    await _save();
    notifyListeners();
  }

  /// 根據 ID 取得作業
  Homework? getById(String id) {
    try {
      return _homeworks.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 安排作業提醒通知
  Future<void> _scheduleReminderIfNeeded(Homework hw) async {
    if (hw.reminderAt == null) return;
    if (hw.reminderAt!.isBefore(DateTime.now())) return;

    await NotificationService().scheduleAt(
      id: IdUtils.hashId(
        'hwr-${hw.id}-${hw.reminderAt!.millisecondsSinceEpoch}',
      ),
      title: 'Homework reminder',
      body: hw.title,
      when: hw.reminderAt!,
    );
  }

  /// 重新安排所有未完成作業的提醒
  Future<void> _rescheduleAllReminders() async {
    for (final hw in _homeworks) {
      if (hw.isDone) continue;
      await _scheduleReminderIfNeeded(hw);
    }
  }
}
