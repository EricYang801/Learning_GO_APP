// lib/pages/voice_page.dart
// NOTE: All strings/identifiers in English; comments in Chinese.

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/stt_service.dart';
import '../../../core/services/media_service.dart';
import '../../home/state/media_state.dart';
import '../state/voice_state.dart';
import 'audio_library_page.dart';

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});
  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final STTService stt = STTService();
  final MediaService media = MediaService();

  // null = 尚未初始化, true = 成功, false = 失敗
  bool? sttReady;

  // 是否正在載入模型
  bool _loadingModel = false;

  /// 延遲初始化 STT 模型（只在需要轉寫時才載入）
  Future<bool> _ensureSTTReady() async {
    // 已經初始化過，直接回傳結果
    if (sttReady != null) return sttReady!;

    // 正在載入中，等待完成
    if (_loadingModel) {
      // 等待載入完成（簡單的輪詢）
      while (_loadingModel) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return sttReady ?? false;
    }

    // 開始載入模型
    _loadingModel = true;
    try {
      final ok = await stt.init();
      if (mounted) {
        setState(() {
          sttReady = ok;
          _loadingModel = false;
        });
      }
      return ok;
    } catch (e) {
      if (mounted) {
        setState(() {
          sttReady = false;
          _loadingModel = false;
        });
      }
      return false;
    }
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
  Future<void> _transcribePickedFile(File file) async {
    final voice = context.read<VoiceState>();

    voice.setVoiceText('');
    voice.setVoiceTranscribing(true);

    try {
      // 使用延遲載入，只在需要時才初始化模型
      if (_loadingModel) {
        voice.setVoiceText('Loading model...');
      }

      final ready = await _ensureSTTReady();
      if (!ready) throw Exception('Model not ready');

      debugPrint('[STT] start file transcribe: ${file.path}');
      final Object raw = await stt.transcribeFile(file.path, lang: 'auto');
      final normalized = _normalizeSTTResult(raw);
      debugPrint(
        '[STT] got result type=${raw.runtimeType} len=${raw.toString().length}',
      );

      voice.setVoiceText(
        normalized.isEmpty ? '[No speech detected]' : normalized,
      );
    } catch (e) {
      voice.setVoiceText('Transcription failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Transcription failed: $e')));
      }
    } finally {
      voice.setVoiceTranscribing(false);
    }
  }

  /// 開始錄音（僅錄音，不跑任何 STT）
  Future<void> _startAll() async {
    try {
      final ok = await media.canRecord();
      if (!ok) throw Exception('Microphone permission not granted');

      final path = await media.startRecord();
      if (!mounted) return;

      if (path == null) {
        context.read<VoiceState>().setRecording(value: false, path: null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start recording')),
        );
        setState(() {});
        return;
      }

      context.read<VoiceState>().setRecording(value: true, path: path);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      context.read<VoiceState>().setRecording(value: false, path: null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
      setState(() {});
    }
  }

  /// 停止錄音
  Future<void> _stopAll() async {
    try {
      final path = await media.stopRecord();
      if (!mounted) return;

      final prev = context.read<VoiceState>().recordingPath;
      context.read<VoiceState>().setRecording(value: false, path: path ?? prev);

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      context.read<VoiceState>().setRecording(value: false, path: null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      setState(() {});
    }
  }

  /// 將目前錄音檔存進 MediaState
  Future<void> _saveRecording() async {
    final voice = context.read<VoiceState>();
    final mediaState = context.read<MediaState>();
    final path = voice.recordingPath;
    if (path == null) return;

    final name =
        'Audio ${DateTime.now().toLocal().toString().substring(0, 16)}';
    await mediaState.addAudio(name: name, path: path);
    voice.setRecording(value: false, path: null);
    setState(() {});
  }

  /// 上傳本地音檔
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
    final voice = context.watch<VoiceState>();
    final recording = voice.recording;
    final recordingPath = voice.recordingPath;

    final transcribing = voice.voiceTranscribing;
    final displayText = voice.voiceText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice to Text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_outlined),
            onPressed: () async {
              final file = await Navigator.push<File?>(
                context,
                MaterialPageRoute(builder: (_) => const AudioLibraryPage()),
              );
              if (file != null) {
                await _transcribePickedFile(file);
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
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
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
                        foregroundColor: AppColors.accent,
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
