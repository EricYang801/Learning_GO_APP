// 讓使用者瀏覽過往錄好的音檔（或手動添加的）並播放
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/audio_file.dart';
import '../../home/state/media_state.dart';

class AudioLibraryPage extends StatelessWidget {
  const AudioLibraryPage({super.key});

  // 取得排序時間
  DateTime _sortTimestamp(AudioFile a) {
    final byMeta = a.recordedAt ?? a.createdAt;
    if (byMeta != null) return byMeta;

    try {
      return File(a.path).lastModifiedSync();
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = context.watch<MediaState>();

    // 依「錄製時間」由新到舊排序
    final List<AudioFile> audios = List<AudioFile>.from(mediaState.audioFiles);
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
                    Navigator.pop<File>(context, File(a.path));
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
                            a.name,
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
                          icon: const Icon(Icons.edit, color: AppColors.accent),
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
                                  text: a.name,
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
                                    decoration: inputDecoration(
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
                                        foregroundColor: AppColors.accent,
                                      ),
                                      onPressed: () {
                                        final newName = ctrl.text.trim();
                                        if (newName.isNotEmpty) {
                                          mediaState.renameAudio(a.id, newName);
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

                        // 刪除
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
                              mediaState.removeAudio(a.id);
                              final file = File(a.path);
                              if (await file.exists()) {
                                await file.delete();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delete failed'),
                                  ),
                                );
                              }
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
