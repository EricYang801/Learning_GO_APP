/// 學習時間段記錄
class StudySession {
  final String start; // "HH:mm" 格式
  final String end; // "HH:mm" 格式

  const StudySession({
    required this.start,
    required this.end,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySession &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// 每日計時記錄
class TimerRecord {
  final String date; // "yyyy-MM-dd" 格式
  final int seconds;
  final List<StudySession> sessions;

  const TimerRecord({
    required this.date,
    required this.seconds,
    this.sessions = const [],
  });

  /// 從 JSON Map 建立
  factory TimerRecord.fromJson(Map<String, dynamic> json) {
    final sessionsList = json['sessions'] as List<dynamic>?;
    return TimerRecord(
      date: json['date'] as String,
      seconds: json['seconds'] as int? ?? 0,
      sessions: sessionsList
              ?.map((s) => StudySession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 轉換成 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'seconds': seconds,
      if (sessions.isNotEmpty)
        'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  /// 複製並修改部分欄位
  TimerRecord copyWith({
    String? date,
    int? seconds,
    List<StudySession>? sessions,
  }) {
    return TimerRecord(
      date: date ?? this.date,
      seconds: seconds ?? this.seconds,
      sessions: sessions ?? this.sessions,
    );
  }

  /// 新增一個學習時段
  TimerRecord addSession(StudySession session) {
    return copyWith(sessions: [...sessions, session]);
  }

  /// 增加秒數
  TimerRecord addSeconds(int secs) {
    return copyWith(seconds: seconds + secs);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          seconds == other.seconds;

  @override
  int get hashCode => date.hashCode ^ seconds.hashCode;

  @override
  String toString() {
    return 'TimerRecord(date: $date, seconds: $seconds, sessions: ${sessions.length})';
  }
}
