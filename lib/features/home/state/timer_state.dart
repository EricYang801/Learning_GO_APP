import 'package:flutter/foundation.dart';
import '../../../core/models/timer_record.dart';
import '../../../core/services/storage_service.dart';

/// 計時器狀態管理
class TimerState extends ChangeNotifier {
  static const _timerDailyKey = 'timerDaily';
  static const _cfgKey = 'cfg';

  List<TimerRecord> _timerDaily = [];
  int? _todayGoalSeconds;
  String? _lastTimerMode; // 'stopwatch' | 'countdown'
  int? _lastCountdownSeconds;
  String? _currentSessionStart;

  /// 今日目標秒數
  int? get todayGoalSeconds => _todayGoalSeconds;

  /// 上次使用的計時模式
  String? get lastTimerMode => _lastTimerMode;

  /// 上次倒數的秒數
  int? get lastCountdownSeconds => _lastCountdownSeconds;

  /// 是否正在學習中
  bool get isStudying => _currentSessionStart != null;

  /// 取得指定日期的學習秒數
  int secondsForDate(DateTime date) {
    final key = _dateKey(date);
    final record = _timerDaily.where((r) => r.date == key).firstOrNull;
    return record?.seconds ?? 0;
  }

  /// 今天的學習秒數
  int get todaySeconds => secondsForDate(DateTime.now());

  /// 今天的學習進度比例 (0.0 ~ 1.0)
  double get todayProgress {
    if (_todayGoalSeconds == null || _todayGoalSeconds == 0) return 0.0;
    return (todaySeconds / _todayGoalSeconds!).clamp(0.0, 1.0);
  }

  /// 是否達成今日目標
  bool get goalReached =>
      _todayGoalSeconds != null && todaySeconds >= _todayGoalSeconds!;

  /// 取得指定日期的學習時段
  List<StudySession> sessionsForDate(DateTime date) {
    final key = _dateKey(date);
    final record = _timerDaily.where((r) => r.date == key).firstOrNull;
    return record?.sessions ?? [];
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _timeKey(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// 載入資料
  Future<void> load() async {
    final list = await StorageService.instance.getList(_timerDailyKey);
    _timerDaily = list
        .map((e) => TimerRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    final cfg = await StorageService.instance.getMap(_cfgKey);
    _todayGoalSeconds = cfg['todayGoalSeconds'] as int?;
    _lastTimerMode = cfg['lastTimerMode'] as String?;
    _lastCountdownSeconds = cfg['lastCountdownSeconds'] as int?;

    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.setJson(
      _timerDailyKey,
      _timerDaily.map((r) => r.toJson()).toList(),
    );
    await StorageService.instance.setJson(_cfgKey, {
      'todayGoalSeconds': _todayGoalSeconds,
      'lastTimerMode': _lastTimerMode,
      'lastCountdownSeconds': _lastCountdownSeconds,
    });
  }

  /// 增加今天的學習秒數
  Future<void> addTodaySeconds(int secs) async {
    final todayKey = _dateKey(DateTime.now());
    final index = _timerDaily.indexWhere((r) => r.date == todayKey);

    if (index < 0) {
      _timerDaily.add(TimerRecord(date: todayKey, seconds: secs));
    } else {
      _timerDaily[index] = _timerDaily[index].addSeconds(secs);
    }

    await _save();
    notifyListeners();
  }

  /// 設定今日目標
  Future<void> setGoalSeconds(int? secs) async {
    _todayGoalSeconds = secs;
    await _save();
    notifyListeners();
  }

  /// 設定上次使用的計時模式
  Future<void> setLastTimerMode(String mode) async {
    _lastTimerMode = mode;
    await _save();
  }

  /// 設定上次倒數秒數
  Future<void> setLastCountdownSeconds(int secs) async {
    _lastCountdownSeconds = secs;
    await _save();
  }

  /// 開始學習時段
  void startStudySession() {
    _currentSessionStart = _timeKey(DateTime.now());
    notifyListeners();
  }

  /// 結束學習時段
  Future<void> endStudySession() async {
    if (_currentSessionStart == null) return;

    final now = DateTime.now();
    final end = _timeKey(now);
    final todayKey = _dateKey(now);

    final session = StudySession(start: _currentSessionStart!, end: end);
    final index = _timerDaily.indexWhere((r) => r.date == todayKey);

    if (index < 0) {
      _timerDaily.add(TimerRecord(
        date: todayKey,
        seconds: 0,
        sessions: [session],
      ));
    } else {
      _timerDaily[index] = _timerDaily[index].addSession(session);
    }

    _currentSessionStart = null;
    await _save();
    notifyListeners();
  }

  /// 取得所有記錄（用於圖表等）
  List<TimerRecord> get allRecords => List.unmodifiable(_timerDaily);
}
