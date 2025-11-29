import 'package:flutter/foundation.dart';

/// 語音頁面狀態管理
class VoiceState extends ChangeNotifier {
  // 轉寫文字與狀態
  String _voiceText = '';
  bool _voiceTranscribing = false;

  // 錄音狀態
  bool _recording = false;
  String? _recordingPath;

  /// 轉寫後的文字
  String get voiceText => _voiceText;

  /// 是否正在轉寫中
  bool get voiceTranscribing => _voiceTranscribing;

  /// 是否正在錄音
  bool get recording => _recording;

  /// 當前錄音檔路徑
  String? get recordingPath => _recordingPath;

  /// 設定轉寫文字
  void setVoiceText(String value) {
    if (_voiceText == value) return;
    _voiceText = value;
    notifyListeners();
  }

  /// 設定轉寫狀態
  void setVoiceTranscribing(bool value) {
    if (_voiceTranscribing == value) return;
    _voiceTranscribing = value;
    notifyListeners();
  }

  /// 設定錄音狀態
  void setRecording({required bool value, String? path}) {
    _recording = value;
    _recordingPath = path;
    notifyListeners();
  }

  /// 清除狀態
  void clear() {
    _voiceText = '';
    _voiceTranscribing = false;
    _recording = false;
    _recordingPath = null;
    notifyListeners();
  }

  /// 清除錄音路徑
  void clearRecordingPath() {
    _recordingPath = null;
    notifyListeners();
  }
}
