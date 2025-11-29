/// Homework 資料模型
class Homework {
  final String id;
  final String title;
  final String content;
  final DateTime due;
  final String? reminderType; // 'none', 'custom', etc.
  final DateTime? reminderAt;
  final String? color; // 顏色 hex 或名稱
  final DateTime? doneAt;

  const Homework({
    required this.id,
    required this.title,
    required this.content,
    required this.due,
    this.reminderType,
    this.reminderAt,
    this.color,
    this.doneAt,
  });

  /// 是否已完成
  bool get isDone => doneAt != null;

  /// 從 JSON Map 建立
  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      due: DateTime.parse(json['due'] as String),
      reminderType: json['reminderType'] as String?,
      reminderAt: json['reminderAt'] != null
          ? DateTime.parse(json['reminderAt'] as String)
          : null,
      color: json['color'] as String?,
      doneAt: json['doneAt'] != null
          ? DateTime.parse(json['doneAt'] as String)
          : null,
    );
  }

  /// 轉換成 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'due': due.toIso8601String(),
      if (reminderType != null) 'reminderType': reminderType,
      if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
      if (color != null) 'color': color,
      if (doneAt != null) 'doneAt': doneAt!.toIso8601String(),
    };
  }

  /// 複製並修改部分欄位
  Homework copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? due,
    String? reminderType,
    DateTime? reminderAt,
    String? color,
    DateTime? doneAt,
    bool clearDoneAt = false,
    bool clearReminderAt = false,
  }) {
    return Homework(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      due: due ?? this.due,
      reminderType: reminderType ?? this.reminderType,
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      color: color ?? this.color,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Homework &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          due == other.due &&
          reminderType == other.reminderType &&
          reminderAt == other.reminderAt &&
          color == other.color &&
          doneAt == other.doneAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      due.hashCode ^
      reminderType.hashCode ^
      reminderAt.hashCode ^
      color.hashCode ^
      doneAt.hashCode;

  @override
  String toString() {
    return 'Homework(id: $id, title: $title, due: $due, isDone: $isDone)';
  }
}
