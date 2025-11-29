// lib/services/media_service.dart
// NOTE: All strings/identifiers in English; comments in Chinese。

import 'dart:io';
import 'package:flutter/services.dart'; // for PlatformException
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';

class MediaService {
  // ===== Singleton =====
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // ====== Directories (Originals / Processed / Audios) ======
  static const String _originalDirName = 'originals';
  static const String _processedDirName = 'processed';
  static const String _audiosDirName = 'audios'; // 新增：音檔長存資料夾

  Future<Directory> _getAppRootDir() async {
    // 全部存到 App 的 Documents（非暫存）
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  Future<Directory> _getOriginalsDir() async {
    final root = await _getAppRootDir();
    final d = Directory('${root.path}/$_originalDirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> _getProcessedDir() async {
    final root = await _getAppRootDir();
    final d = Directory('${root.path}/$_processedDirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> _getAudiosDir() async {
    final root = await _getAppRootDir();
    final d = Directory('${root.path}/$_audiosDirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  // ====== Images: list/save/delete (Original / Processed) ======
  Future<List<File>> listOriginalImages() async {
    final d = await _getOriginalsDir();
    final files = d
        .listSync()
        .whereType<File>()
        .where((f) => _isImagePath(f.path))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<List<File>> listProcessedImages() async {
    final d = await _getProcessedDir();
    final files = d
        .listSync()
        .whereType<File>()
        .where((f) => _isImagePath(f.path))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<File> saveAsOriginal(File source) async {
    final d = await _getOriginalsDir();
    final name = _uniqueFileName(source.path);
    final target = File('${d.path}/$name');
    return source.copy(target.path);
  }

  Future<File> saveAsProcessed(File source) async {
    final d = await _getProcessedDir();
    final name = _uniqueFileName(source.path);
    final target = File('${d.path}/$name');
    return source.copy(target.path);
  }

  Future<void> deleteOriginal(File file) async {
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteProcessed(File file) async {
    if (await file.exists()) await file.delete();
  }

  /// Export "processed" image to device-visible location.
  /// Android：Pictures → Downloads → External → fallback Documents/Exports
  /// iOS/macOS：Documents/Exports（若需存相簿，之後再加外部套件）
  // 只存「圖片」到系統相簿；不做任何檔案複製
  Future<bool> saveProcessedToDevice(
    File imageFile, {
    String album = 'LearningGO',
  }) async {
    // 非支援平台直接返回（避免 web/macos 以外平台報錯）
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return false;
    }

    // 防呆：確認是圖片副檔名
    if (!_isImagePath(imageFile.path)) return false;

    try {
      await Gal.putImage(imageFile.path, album: album); // 直接寫入相簿
      return true;
    } catch (_) {
      return false;
    }
  }

  // ====== Image picking / camera capture ======
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromGallery() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    return File(x.path);
  }

  Future<File?> captureFromCamera() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) return null;
    return File(x.path);
  }

  // ====== Save raw bytes into App storage (compat with old code) ======
  /// 預設寫入 originals，確保舊有呼叫可正常運作。
  Future<File> saveBytesToApp(Uint8List bytes, {required String name}) async {
    final dir = await _getOriginalsDir();
    final file = File('${dir.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }

  // ====== Audio Recording (compat layer for VoicePage) ======
  final AudioRecorder _recorder = AudioRecorder();
  String? _activeRecordingPath;

  Future<bool> canRecord() async {
    // 中文註解：僅檢查麥克風權限；真正開始時仍可能被其他 session 佔用
    return await _recorder.hasPermission();
  }

  /// 開始錄音；成功回傳檔案路徑，失敗（例如 iOS session 衝突）回傳 null。
  Future<String?> startRecord() async {
    if (!await _recorder.hasPermission()) return null;

    // Safety stop if already recording
    if (await _recorder.isRecording()) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }

    // 改為長存在 Documents/audios
    final dir = await _getAudiosDir();
    final String filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );

    try {
      await _recorder.start(config, path: filePath);
    } on PlatformException catch (_) {
      // iOS 上若同時有其他音訊 session 使用麥克風（例如 STT），這裡會丟 setActive 類錯誤
      return null;
    }

    _activeRecordingPath = filePath;
    return _activeRecordingPath;
  }

  /// 停止錄音，回傳檔案路徑（若沒有在錄則回 null）
  Future<String?> stopRecord() async {
    try {
      final path = await _recorder.stop();
      final result = _activeRecordingPath ?? path;
      _activeRecordingPath = null;
      if (result == null) return null;

      // 保險：若原生層回來的檔案不在 audios/ 內，複製回去再回傳
      final audios = await _getAudiosDir();
      if (!result.startsWith(audios.path)) {
        final fixed = File(
          '${audios.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        await File(result).copy(fixed.path);
        return fixed.path;
      }
      return result;
    } catch (_) {
      _activeRecordingPath = null;
      return null;
    }
  }

  /// 將外部音檔收進 App 的 Documents/audios（上傳/檔案挑選時使用）
  Future<File> ingestAudio(File source) async {
    final dir = await _getAudiosDir();
    final name =
        'rec_${DateTime.now().millisecondsSinceEpoch}${_extension(source.path)}';
    final target = File('${dir.path}/$name');
    return source.copy(target.path);
  }

  // ====== Helpers ======
  bool _isImagePath(String path) {
    final ext = _extension(path).toLowerCase();
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.bmp' ||
        ext == '.gif' ||
        ext == '.heic';
  }

  String _uniqueFileName(String sourcePath) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = _extension(sourcePath);
    return 'img_$ts$ext';
  }

  // ====== Minimal path helpers (avoid package:path) ======
  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot);
  }
}
