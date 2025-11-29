import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/models/audio_file.dart';
import '../../../core/models/image_file.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/id.dart';

/// 媒體庫狀態管理（音檔、圖片）
class MediaState extends ChangeNotifier {
  static const _audioKey = 'audioFiles';
  static const _imageKey = 'images';

  List<AudioFile> _audioFiles = [];
  List<ImageFile> _images = [];

  // 當前處理中的圖片
  File? _currentImage;
  bool _isImageProcessed = false;

  /// 所有音檔
  List<AudioFile> get audioFiles => List.unmodifiable(_audioFiles);

  /// 所有圖片
  List<ImageFile> get images => List.unmodifiable(_images);

  /// 當前選擇的圖片
  File? get currentImage => _currentImage;

  /// 圖片是否已處理
  bool get isImageProcessed => _isImageProcessed;

  /// 載入資料
  Future<void> load() async {
    final audioList = await StorageService.instance.getList(_audioKey);
    _audioFiles = audioList
        .map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
        .toList();

    final imageList = await StorageService.instance.getList(_imageKey);
    _images = imageList
        .map((e) => ImageFile.fromJson(e as Map<String, dynamic>))
        .toList();

    notifyListeners();
  }

  Future<void> _saveAudio() async {
    await StorageService.instance.setJson(
      _audioKey,
      _audioFiles.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _saveImages() async {
    await StorageService.instance.setJson(
      _imageKey,
      _images.map((i) => i.toJson()).toList(),
    );
  }

  // ========== 音檔操作 ==========

  /// 新增音檔
  Future<void> addAudio({required String name, required String path}) async {
    final audio = AudioFile(
      id: IdUtils.generate(),
      name: name,
      path: path,
      createdAt: DateTime.now(),
    );
    _audioFiles.add(audio);
    await _saveAudio();
    notifyListeners();
  }

  /// 重新命名音檔
  Future<void> renameAudio(String id, String name) async {
    final index = _audioFiles.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _audioFiles[index] = _audioFiles[index].copyWith(name: name);
      await _saveAudio();
      notifyListeners();
    }
  }

  /// 刪除音檔
  Future<void> removeAudio(String id) async {
    _audioFiles.removeWhere((a) => a.id == id);
    await _saveAudio();
    notifyListeners();
  }

  /// 根據 ID 取得音檔
  AudioFile? getAudioById(String id) {
    try {
      return _audioFiles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ========== 圖片操作 ==========

  /// 新增圖片
  Future<void> addImage({required String name, required String path}) async {
    final image = ImageFile(
      id: IdUtils.generate(),
      name: name,
      path: path,
      createdAt: DateTime.now(),
    );
    _images.add(image);
    await _saveImages();
    notifyListeners();
  }

  /// 刪除圖片
  Future<void> removeImage(String id) async {
    _images.removeWhere((i) => i.id == id);
    await _saveImages();
    notifyListeners();
  }

  /// 根據 ID 取得圖片
  ImageFile? getImageById(String id) {
    try {
      return _images.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  // ========== 當前圖片狀態 ==========

  /// 設定當前圖片
  void setCurrentImage(File? file) {
    _currentImage = file;
    _isImageProcessed = false;
    notifyListeners();
  }

  /// 標記圖片已處理
  void markProcessed(bool value) {
    _isImageProcessed = value;
    notifyListeners();
  }

  /// 清除當前圖片
  void clearCurrentImage() {
    _currentImage = null;
    _isImageProcessed = false;
    notifyListeners();
  }
}
