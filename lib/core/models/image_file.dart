/// 圖片檔案資料模型
class ImageFile {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;

  const ImageFile({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
  });

  /// 從 JSON Map 建立
  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 轉換成 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 複製並修改部分欄位
  ImageFile copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
  }) {
    return ImageFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          path == other.path &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ path.hashCode ^ createdAt.hashCode;

  @override
  String toString() {
    return 'ImageFile(id: $id, name: $name, path: $path)';
  }
}
