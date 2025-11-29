// lib/pages/audio_library_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

const double _kFieldRadius = 12;

// 共用輸入框樣式（淺灰底、深灰框、同圓角）
InputDecoration _decoration({
  String? hint,
  EdgeInsetsGeometry? contentPadding,
}) {
  final base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[400]!),
  );
  final focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: BorderSide(color: Colors.grey[500]!, width: 1.2),
  );
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[100],
    isDense: true,
    contentPadding:
        contentPadding ??
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    enabledBorder: base,
    focusedBorder: focused,
    border: base,
  );
}

class AudioLibraryPage extends StatelessWidget {
  const AudioLibraryPage({super.key});

  // 解析時間欄位：支援 int(毫秒) / String(ISO) / DateTime
  DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  // 取得排序時間：recordedAt/createdAt > 檔案最後修改時間
  DateTime _sortTimestamp(Map a) {
    final byMeta = _parseTime(a['recordedAt']) ?? _parseTime(a['createdAt']);
    if (byMeta != null) return byMeta;

    final path = a['path'] as String?;
    if (path != null) {
      try {
        return File(path).lastModifiedSync();
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // 依「錄製時間」由新到舊排序
    final List<Map> audios = List<Map>.from(app.audioFiles);
    audios.sort((a, b) => _sortTimestamp(b).compareTo(_sortTimestamp(a)));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audio Library',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: audios.isEmpty
          ? const Center(child: Text('No audio files yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: audios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = audios[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // 點擊即回傳此檔
                    Navigator.pop<File>(context, File(a['path']));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 重新命名
                        IconButton(
                          tooltip: 'Rename',
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF007AFF),
                          ),
                          iconSize: 25,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final ctrl = TextEditingController(
                                  text: a['name'],
                                );
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.white,
                                  titlePadding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    6,
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    0,
                                  ),
                                  actionsPadding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    'Rename Audio',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: TextField(
                                    controller: ctrl,
                                    decoration: _decoration(
                                      hint: 'Enter new name',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Color(0xFF007AFF),
                                      ),
                                      onPressed: () {
                                        final newName = ctrl.text.trim();
                                        if (newName.isNotEmpty) {
                                          app.renameAudio(a['id'], newName);
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(width: 6),

                        // 刪除（成功靜默、失敗才提示）
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          iconSize: 25,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          onPressed: () async {
                            try {
                              app.removeAudio(a['id']);
                              final file = File(a['path']);
                              if (await file.exists()) {
                                await file.delete();
                              }
                              // 成功：不顯示任何提示
                            } catch (e) {
                              // 只有失敗才提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delete failed')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
