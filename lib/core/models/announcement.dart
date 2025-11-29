/// 公告資料模型
class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime at;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
  });

  /// 從 JSON Map 建立
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      at: DateTime.parse(json['at'] as String),
    );
  }

  /// 轉換成 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'at': at.toIso8601String(),
    };
  }

  /// 複製並修改部分欄位
  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? at,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      at: at ?? this.at,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          at == other.at;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ body.hashCode ^ at.hashCode;

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, at: $at)';
  }
}
