// lib/services/stt_service.dart
// 只做：Whisper 離線模型初始化 + 既有音檔轉文字（不含任何錄音邏輯）

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:whisper_ggml/whisper_ggml.dart';

class STTService {
  final WhisperController _whisper = WhisperController();
  final WhisperModel _model = WhisperModel.base; // ggml-base.bin
  bool _modelReady = false;
  bool get isReady => _modelReady;

  /// 初始化：把 assets/models/ggml-base.bin 寫入 plugin 預期路徑
  Future<bool> init() async {
    if (_modelReady) return true;
    try {
      // 1) 從 assets 讀模型
      final bytes = await rootBundle.load('assets/models/ggml-base.bin');

      // 2) 取得 whisper 要找模型的位置，並寫入
      final modelPath = await _whisper.getPath(_model);
      final outFile = File(modelPath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      _modelReady = true;
      return true;
    } catch (_) {
      // 若內嵌失敗，退到官方自動下載一次
      try {
        await _whisper.downloadModel(_model);
        _modelReady = true;
        return true;
      } catch (e) {
        _modelReady = false;
        rethrow;
      }
    }
  }

  /// 以既有音檔進行轉寫（上傳/圖庫/錄音結果）
  Future<String> transcribeFile(String filePath, {String lang = 'auto'}) async {
    if (!_modelReady) {
      final ok = await init();
      if (!ok) throw Exception('Whisper model not ready');
    }
    final result = await _whisper.transcribe(
      model: _model,
      audioPath: filePath,
      lang: lang, // 'auto' 支援中英混合
    );
    return result?.transcription.text ?? '';
  }
}
