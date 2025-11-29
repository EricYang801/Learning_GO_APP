/// To-Do 資料模型
class Todo {
  final String id;
  final String title;
  final String desc;
  final DateTime due;
  final DateTime? doneAt;

  const Todo({
    required this.id,
    required this.title,
    required this.desc,
    required this.due,
    this.doneAt,
  });

  /// 是否已完成
  bool get isDone => doneAt != null;

  /// 從 JSON Map 建立
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      desc: json['desc'] as String? ?? '',
      due: DateTime.parse(json['due'] as String),
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
      'desc': desc,
      'due': due.toIso8601String(),
      if (doneAt != null) 'doneAt': doneAt!.toIso8601String(),
    };
  }

  /// 複製並修改部分欄位
  Todo copyWith({
    String? id,
    String? title,
    String? desc,
    DateTime? due,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      due: due ?? this.due,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          desc == other.desc &&
          due == other.due &&
          doneAt == other.doneAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      desc.hashCode ^
      due.hashCode ^
      doneAt.hashCode;

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, due: $due, isDone: $isDone)';
  }
}
