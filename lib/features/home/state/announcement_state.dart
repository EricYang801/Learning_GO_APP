import 'package:flutter/foundation.dart';
import '../../../core/models/announcement.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/id.dart';
import '../../../core/services/notification_service.dart';

/// 公告狀態管理
class AnnouncementState extends ChangeNotifier {
  static const _storageKey = 'announcements';

  List<Announcement> _announcements = [];

  /// 所有公告（最新的在前）
  List<Announcement> get announcements => List.unmodifiable(_announcements);

  /// 載入資料
  Future<void> load() async {
    final list = await StorageService.instance.getList(_storageKey);
    _announcements = list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.setJson(
      _storageKey,
      _announcements.map((a) => a.toJson()).toList(),
    );
  }

  /// 新增公告（會插入到最前面）
  Future<void> push(String title, String body) async {
    final announcement = Announcement(
      id: IdUtils.generate(),
      title: title,
      body: body,
      at: DateTime.now(),
    );
    _announcements.insert(0, announcement);
    await _save();
    notifyListeners();
  }

  /// 刪除公告
  Future<void> remove(String id) async {
    _announcements.removeWhere((a) => a.id == id);
    await _save();
    notifyListeners();
  }

  /// 清除所有公告
  Future<void> clearAll() async {
    _announcements.clear();
    await _save();
    notifyListeners();
  }

  /// 安排每日午夜檢查通知
  Future<void> scheduleDailyMidnightCheck() async {
    await NotificationService().scheduleDailyMidnight(
      id: IdUtils.hashId('daily-00'),
      title: 'Daily check',
      body: "We checked today's To-Do & Homework deadlines.",
    );
  }
}
