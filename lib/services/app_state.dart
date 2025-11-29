import 'package:flutter/foundation.dart';
import '../utils/storage.dart';
import '../utils/id.dart';
import 'dart:io';
import 'notification_service.dart';

/// Data models (simple Maps for brevity)
/// ToDo: {id,title,desc,due,doneAt?}
/// Homework: {id,title,content,due,reminderType,reminderAt?,color,doneAt?}
/// Timer record: {date:'yyyy-MM-dd', seconds:int}
/// Announcement: {id, title, body, at}

class AppState extends ChangeNotifier {
  // 轉寫文字與狀態（跨頁保存）
  String _voiceText = '';
  bool _voiceTranscribing = false;

  String get voiceText => _voiceText;
  bool get voiceTranscribing => _voiceTranscribing;

  void setVoiceText(String value) {
    if (_voiceText == value) return;
    _voiceText = value;
    notifyListeners();
  }

  void setVoiceTranscribing(bool value) {
    if (_voiceTranscribing == value) return;
    _voiceTranscribing = value;
    notifyListeners();
  }

  bool _recording = false;
  String? _recordingPath;

  bool get recording => _recording;
  String? get recordingPath => _recordingPath;

  void setRecording({required bool value, String? path}) {
    _recording = value;
    _recordingPath = path;
    notifyListeners();
  }

  File? _currentImage;
  File? get currentImage => _currentImage;

  void setCurrentImage(File? f) {
    _currentImage = f;
    notifyListeners();
  }

  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> homeworks = [];
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> timerDaily = []; // per-day seconds
  int? todayGoalSeconds; // nullable
  String? lastTimerMode; // 'stopwatch' | 'countdown'
  int? lastCountdownSeconds;

  // Media library
  List<Map<String, dynamic>> audioFiles = []; // {id, name, path, createdAt}
  List<Map<String, dynamic>> images = []; // {id, name, path, createdAt}

  // === helpers ===
  static String _yyyyMMdd(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  static bool _isSameDayIso(String iso, DateTime day) {
    final d = DateTime.parse(iso);
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }

  int _hashId(String seed) => seed.hashCode & 0x7fffffff;

  Future<void> load() async {
    todos = (await KV.getList('todos')).cast<Map<String, dynamic>>();
    homeworks = (await KV.getList('homeworks')).cast<Map<String, dynamic>>();
    announcements = (await KV.getList(
      'announcements',
    )).cast<Map<String, dynamic>>();
    timerDaily = (await KV.getList('timerDaily')).cast<Map<String, dynamic>>();
    final cfg = await KV.getMap('cfg');
    todayGoalSeconds = cfg['todayGoalSeconds'];
    lastTimerMode = cfg['lastTimerMode'];
    lastCountdownSeconds = cfg['lastCountdownSeconds'];
    audioFiles = (await KV.getList('audioFiles')).cast<Map<String, dynamic>>();
    images = (await KV.getList('images')).cast<Map<String, dynamic>>();

    // === 新增：初始化通知、安排每日 00:00、啟動時補跑一次、重排未來作業提醒 ===
    await NotificationService().init();
    await scheduleDailyMidnightCheck();
    await checkDueAndNotify();
    await _rescheduleAllHomeworkReminders();

    notifyListeners();
  }

  Future<void> _save() async {
    await KV.setJson('todos', todos);
    await KV.setJson('homeworks', homeworks);
    await KV.setJson('announcements', announcements);
    await KV.setJson('timerDaily', timerDaily);
    await KV.setJson('audioFiles', audioFiles);
    await KV.setJson('images', images);
    await KV.setJson('cfg', {
      'todayGoalSeconds': todayGoalSeconds,
      'lastTimerMode': lastTimerMode,
      'lastCountdownSeconds': lastCountdownSeconds,
    });
  }

  // --- ToDo ---
  void addTodo(String title, String desc, DateTime due) {
    todos.add({
      'id': newId(),
      'title': title,
      'desc': desc,
      'due': due.toIso8601String(),
    });
    _sortTodos();
    _save();
    notifyListeners();
  }

  void updateTodo(String id, String title, String desc, DateTime due) {
    final i = todos.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      todos[i]['title'] = title;
      todos[i]['desc'] = desc;
      todos[i]['due'] = due.toIso8601String();
      _sortTodos();
      _save();
      notifyListeners();
    }
  }

  void completeTodo(String id) {
    final i = todos.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      todos[i]['doneAt'] = DateTime.now().toIso8601String();
      _save();
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    final i = todos.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      todos.removeAt(i); // ✅ 直接刪掉，不保留
      _save();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> visibleTodos() =>
      todos.where((e) => e['doneAt'] == null).toList();

  void _sortTodos() {
    todos.sort(
      (a, b) => DateTime.parse(a['due']).compareTo(DateTime.parse(b['due'])),
    );
  }

  // --- Homework ---
  void addHomework(Map<String, dynamic> hw) {
    homeworks.add(hw..['id'] = newId());
    _sortHw();
    _save();
    notifyListeners();

    // ✅ 若有提醒時間就排程
    _scheduleHomeworkReminderIfAny(hw);
  }

  void updateHomework(Map<String, dynamic> hw) {
    final i = homeworks.indexWhere((e) => e['id'] == hw['id']);
    if (i >= 0) {
      homeworks[i] = hw;
      _sortHw();
      _save();
      notifyListeners();

      // ✅ 若提醒時間變動，同步更新排程
      _scheduleHomeworkReminderIfAny(hw);
    }
  }

  void completeHomework(String id) {
    final i = homeworks.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      homeworks[i]['doneAt'] = DateTime.now().toIso8601String();
      _save();
      notifyListeners();
    }
  }

  void removeHomework(String id) {
    final i = homeworks.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      homeworks.removeAt(i); // ✅ 直接刪掉，不保留
      _save();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> visibleHomeworks() =>
      homeworks.where((e) => e['doneAt'] == null).toList();

  void _sortHw() {
    homeworks.sort(
      (a, b) => DateTime.parse(a['due']).compareTo(DateTime.parse(b['due'])),
    );
  }

  // --- Announcements ---
  void pushAnnouncement(String title, String body) {
    announcements.insert(0, {
      'id': newId(),
      'title': title,
      'body': body,
      'at': DateTime.now().toIso8601String(),
    });
    _save();
    notifyListeners();
  }

  // --- Timer logic ---
  int todaySeconds(DateTime date) {
    final key = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
    final i = timerDaily.indexWhere((e) => e['date'] == key);
    return i >= 0 ? timerDaily[i]['seconds'] as int : 0;
  }

  void addTodaySeconds(int secs) {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final i = timerDaily.indexWhere((e) => e['date'] == todayKey);
    if (i < 0) {
      timerDaily.add({'date': todayKey, 'seconds': secs});
    } else {
      timerDaily[i]['seconds'] = (timerDaily[i]['seconds'] as int) + secs;
    }
    _save();
    notifyListeners();
  }

  void setGoalSeconds(int? secs) {
    todayGoalSeconds = secs;
    _save();
    notifyListeners();
  }

  // --- Media libraries ---
  void addAudio({required String name, required String path}) {
    audioFiles.add({
      'id': newId(),
      'name': name,
      'path': path,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _save();
    notifyListeners();
  }

  void renameAudio(String id, String name) {
    final i = audioFiles.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      audioFiles[i]['name'] = name;
      _save();
      notifyListeners();
    }
  }

  void removeAudio(String id) {
    final i = audioFiles.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      audioFiles.removeAt(i);
      _save();
      notifyListeners();
    }
  }

  void addImage({required String name, required String path}) {
    images.add({
      'id': newId(),
      'name': name,
      'path': path,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _save();
    notifyListeners();
  }

  void removeImage(String id) {
    final i = images.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      images.removeAt(i);
      _save();
      notifyListeners();
    }
  }

  // --- Metrics for Daily Task progress ---
  (int done, int total) todayProgress() {
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    // 分母：今天到期的全部（含已完成 + 未完成）
    final todosToday = todos
        .where((e) => isToday(DateTime.parse(e['due'])))
        .toList();
    final hwsToday = homeworks
        .where((e) => isToday(DateTime.parse(e['due'])))
        .toList();
    final total = todosToday.length + hwsToday.length;

    // 分子：今天到期且已完成
    final done =
        todosToday.where((e) => e['doneAt'] != null).length +
        hwsToday.where((e) => e['doneAt'] != null).length;

    return (done, total);
  }

  // ================== 新增：每日 00:00 檢測與作業提醒 ==================

  /// 檢測「今天到期且未完成」的 To-Do / Homework：寫入公告並發通知
  Future<void> checkDueAndNotify() async {
    await NotificationService().init();

    final now = DateTime.now();

    final dueTodos = todos.where((e) {
      if (e['doneAt'] != null) return false;
      return _isSameDayIso(e['due'], now);
    }).toList();

    final dueHomeworks = homeworks.where((e) {
      if (e['doneAt'] != null) return false;
      return _isSameDayIso(e['due'], now);
    }).toList();

    if (dueTodos.isNotEmpty) {
      final body = dueTodos.map((e) => '• ${e['title']}').join('\n');
      pushAnnouncement('To-Do due today', body);
      await NotificationService().showNow(
        id: _hashId('todo-${now.toIso8601String()}'),
        title: 'To-Do due today',
        body: 'You have ${dueTodos.length} task(s) due today.',
      );
    }

    if (dueHomeworks.isNotEmpty) {
      final body = dueHomeworks.map((e) => '• ${e['title']}').join('\n');
      pushAnnouncement('Homework due today', body);
      await NotificationService().showNow(
        id: _hashId('hw-${now.toIso8601String()}'),
        title: 'Homework due today',
        body: 'You have ${dueHomeworks.length} item(s) due today.',
      );
    }
  }

  /// 安排每日 00:00 的排程通知（搭配上面的檢測：App 回到前景或啟動時會補跑）
  Future<void> scheduleDailyMidnightCheck() async {
    await NotificationService().scheduleDailyMidnight(
      id: _hashId('daily-00'),
      title: 'Daily check',
      body: 'We checked today’s To-Do & Homework deadlines.',
    );
  }

  /// 若 hw 含 `reminderAt`（DateTime 或 ISO 字串），則排程一次提醒並寫入公告
  Future<void> _scheduleHomeworkReminderIfAny(Map<String, dynamic> hw) async {
    if (!hw.containsKey('reminderAt') || hw['reminderAt'] == null) return;

    late DateTime when;
    final v = hw['reminderAt'];
    if (v is DateTime) {
      when = v;
    } else if (v is String) {
      when = DateTime.parse(v);
    } else {
      return;
    }

    if (when.isBefore(DateTime.now())) return;

    pushAnnouncement(
      'Homework reminder scheduled',
      'Will remind at $when — ${hw['title']}',
    );

    await NotificationService().scheduleAt(
      id: _hashId('hwr-${hw['id']}-${when.millisecondsSinceEpoch}'),
      title: 'Homework reminder',
      body: '${hw['title']}',
      when: when,
    );
  }

  /// App 啟動時把未來的作業提醒重新排一次（避免因系統重啟遺失）
  Future<void> _rescheduleAllHomeworkReminders() async {
    for (final hw in homeworks) {
      if (hw['doneAt'] != null) continue;
      await _scheduleHomeworkReminderIfAny(hw);
    }
  }

  // 模型不重複跑
  bool isImageProcessed = false;

  void markProcessed(bool v) {
    isImageProcessed = v;
    notifyListeners();
  }

  // =========== Study Session Tracking ===========
  String? _currentSessionStart;

  // 呼叫：開始一段讀書 session
  void startStudySession() {
    final now = DateTime.now();
    _currentSessionStart =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  // 呼叫：結束一段讀書 session
  void endStudySession() {
    if (_currentSessionStart == null) return;

    final now = DateTime.now();
    final end =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    int idx = timerDaily.indexWhere((e) => e["date"] == todayStr);

    if (idx == -1) {
      timerDaily.add({
        "date": todayStr,
        "seconds": 0, // 保留原本秒數邏輯
        "sessions": [
          {"start": _currentSessionStart!, "end": end},
        ],
      });
    } else {
      timerDaily[idx]["sessions"] ??= [];
      (timerDaily[idx]["sessions"] as List).add({
        "start": _currentSessionStart!,
        "end": end,
      });
    }

    _currentSessionStart = null;
    _save();
    notifyListeners();
  }
}
