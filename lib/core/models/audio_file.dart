/// 音檔資料模型
class AudioFile {
  final String id;
  final String name;
  final String path;
  final DateTime? createdAt;
  final DateTime? recordedAt;

  const AudioFile({
    required this.id,
    required this.name,
    required this.path,
    this.createdAt,
    this.recordedAt,
  });

  /// 從 JSON Map 建立
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
    );
  }

  /// 轉換成 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt?.toIso8601String(),
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }

  /// 複製並修改部分欄位
  AudioFile copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    DateTime? recordedAt,
  }) {
    return AudioFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          path == other.path &&
          createdAt == other.createdAt &&
          recordedAt == other.recordedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      path.hashCode ^
      createdAt.hashCode ^
      recordedAt.hashCode;

  @override
  String toString() {
    return 'AudioFile(id: $id, name: $name, path: $path)';
  }
}
