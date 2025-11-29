// lib/pages/voice_page.dart
// All UI strings/identifiers in English; comments in 中文。

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/stt_service.dart';
import '../services/app_state.dart';
import '../services/media_service.dart'; // 錄音交給 MediaService
import 'audio_library_page.dart';

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});
  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final STTService stt = STTService();
  final MediaService media = MediaService();

  bool sttReady = false; // Whisper/模型是否已就緒（僅做初始化檢查）

  @override
  void initState() {
    super.initState();
    // 僅為「檔案轉寫時」預先準備模型；Start/Stop 錄音不會使用 STT
    stt.init().then((ok) {
      if (mounted) setState(() => sttReady = ok);
    });
  }

  /// 將 STT 回傳結果（String / Iterable / Map）統一轉成純文字
  String _normalizeSTTResult(dynamic raw) {
    if (raw == null) return '';

    // 1) 直接是字串
    if (raw is String) return raw.trim();

    // 2) 是 Iterable（List、Iterable）
    if (raw is Iterable) {
      final buf = StringBuffer();
      for (final item in raw) {
        if (item == null) continue;

        if (item is String) {
          buf.write(item);
          buf.write(' ');
        } else if (item is Map) {
          // 常見鍵位：text / segment / caption
          final t = item['text'] ?? item['segment'] ?? item['caption'];
          if (t != null) {
            buf.write(t.toString());
            buf.write(' ');
          }
        } else {
          buf.write(item.toString());
          buf.write(' ');
        }
      }
      return buf.toString().trim();
    }

    // 3) 是 Map（e.g. { text: '...', segments: [...] })
    if (raw is Map) {
      final t = raw['text'];
      if (t is String && t.trim().isNotEmpty) return t.trim();

      final seg = raw['segments'];
      if (seg is Iterable) return _normalizeSTTResult(seg);

      // 其他未知結構
      return raw.toString().trim();
    }

    // 4) 其他型別：轉字串保底
    return raw.toString().trim();
  }

  /// 以檔案進行轉寫（走 ggml/Whisper/ONNX 等）
  /// * 改為只寫入 AppState，不用本地 setState 持有文字或轉寫中狀態。
  Future<void> _transcribePickedFile(File file) async {
    final app = context.read<AppState>();

    // 先在全域狀態標記「清空文字、進入轉寫中」
    app.setVoiceText('');
    app.setVoiceTranscribing(true);

    try {
      if (!sttReady) {
        final ok = await stt.init();
        if (!ok) throw Exception('Model not ready');
        if (mounted) setState(() => sttReady = true);
      }

      print('[STT] start file transcribe: ${file.path}');
      final Object raw = await stt.transcribeFile(file.path, lang: 'auto');
      final normalized = _normalizeSTTResult(raw);
      print(
        '[STT] got result type=${raw.runtimeType} len=${(raw.toString() ?? '').length}',
      );

      // 寫回全域狀態（即使頁面已離開，Future 仍可完成並更新狀態）
      app.setVoiceText(
        normalized.isEmpty ? '[No speech detected]' : normalized,
      );
    } catch (e) {
      app.setVoiceText('Transcription failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transcription failed: $e')));
    } finally {
      app.setVoiceTranscribing(false);
    }
  }

  /// 開始錄音（僅錄音，不跑任何 STT）
  Future<void> _startAll() async {
    try {
      final ok = await media.canRecord();
      if (!ok) throw Exception('Microphone permission not granted');

      final path = await media.startRecord(); // 可能回傳 null（例如 iOS session 被占用）
      if (!mounted) return;

      if (path == null) {
        context.read<AppState>().setRecording(value: false, path: null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start recording')),
        );
        setState(() {}); // 刷新按鈕外觀
        return;
      }

      context.read<AppState>().setRecording(value: true, path: path);
      setState(() {}); // 刷新按鈕外觀
    } catch (e) {
      if (!mounted) return;
      context.read<AppState>().setRecording(value: false, path: null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
      setState(() {});
    }
  }

  /// 停止錄音（不做轉寫；保留檔案路徑供使用者 Save 或到 Library 跑 STT）
  Future<void> _stopAll() async {
    try {
      final path = await media.stopRecord(); // 可能為 null
      if (!mounted) return;

      final prev = context.read<AppState>().recordingPath;
      context.read<AppState>().setRecording(value: false, path: path ?? prev);

      setState(() {}); // 刷新按鈕/Save 狀態
    } catch (e) {
      if (!mounted) return;
      context.read<AppState>().setRecording(value: false, path: null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      setState(() {});
    }
  }

  /// 將目前錄音檔存進 AppState（不彈提示）
  Future<void> _saveRecording() async {
    final app = context.read<AppState>();
    final path = app.recordingPath;
    if (path == null) return;

    final name =
        'Audio ${DateTime.now().toLocal().toString().substring(0, 16)}';
    app.addAudio(name: name, path: path);
    app.setRecording(value: false, path: null); // 存完清空暫存
    setState(() {}); // 刷新 Save 按鈕狀態
  }

  /// 上傳本地音檔：清空後直接轉寫（仍保留加入音訊庫的行為）
  Future<void> _uploadAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav'],
    );
    if (result == null || result.files.single.path == null) return;

    final externalPath = result.files.single.path!;
    await _transcribePickedFile(File(externalPath));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 用 AppState 取得可持久化的狀態
    final app = context.watch<AppState>();
    final recording = app.recording;
    final recordingPath = app.recordingPath;

    final transcribing = app.voiceTranscribing; // 轉寫中（跨頁保留）
    final displayText = app.voiceText; // 轉寫結果（跨頁保留）

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice to Text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            onPressed: () async {
              // 從音訊庫挑選：會傳回 File
              final file = await Navigator.push<File?>(
                context,
                MaterialPageRoute(builder: (_) => const AudioLibraryPage()),
              );
              if (file != null) {
                await _transcribePickedFile(file); // 新一輪：清空再轉（狀態在 AppState）
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          children: [
            // 標題 + 複製鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transcribed Text',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayText));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                  icon: const Icon(Icons.copy_all),
                ),
              ],
            ),

            // 文字顯示框
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    displayText.trim().isEmpty
                        ? (transcribing ? 'Transcribing audio file...' : '—')
                        : displayText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 上傳檔案
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Audio File'),
                onPressed: _uploadAudioFile,
              ),
            ),
            const SizedBox(height: 12),

            // Start/Stop + Save 錄音
            Row(
              children: [
                // Start / Stop
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: recording ? Colors.red : Colors.green,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(recording ? Icons.stop : Icons.mic),
                      label: Text(recording ? 'Stop' : 'Start'),
                      onPressed: () async {
                        if (recording) {
                          await _stopAll();
                        } else {
                          await _startAll();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Save Recording
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD6E6FF),
                        foregroundColor: const Color(0xFF007AFF),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: (!recording && recordingPath != null)
                          ? _saveRecording
                          : null,
                      child: const Text('Save Recording'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
