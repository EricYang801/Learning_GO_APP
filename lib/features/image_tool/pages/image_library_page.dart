// lib/pages/image_library_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/state/media_state.dart';
import '../../../core/services/media_service.dart';

class ImageLibraryPage extends StatefulWidget {
  const ImageLibraryPage({super.key});

  @override
  State<ImageLibraryPage> createState() => _ImageLibraryPageState();
}

class _ImageLibraryPageState extends State<ImageLibraryPage>
    with SingleTickerProviderStateMixin {
  final media = MediaService();
  late TabController _tab;
  List<File> originals = [];
  List<File> processed = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final o = await media.listOriginalImages();
    final p = await media.listProcessedImages();
    setState(() {
      originals = o;
      processed = p;
      loading = false;
    });
  }

  Future<void> _deleteOriginal(File f) async {
    await media.deleteOriginal(f);
    await _load();
  }

  Future<void> _deleteProcessed(File f) async {
    await media.deleteProcessed(f);
    await _load();
  }

  Future<void> _downloadProcessed(File f) async {
    final ok = await media.saveProcessedToDevice(f, album: 'LearningGO');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Saved to Photos' : 'Save failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MediaState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Library'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.accent,
          indicatorColor: AppColors.accent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Original'),
            Tab(text: 'Processed'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildGrid(
                  files: originals,
                  canTapToReturn: true,
                  onDelete: _deleteOriginal,
                  showDownload: false,
                ),
                _buildGrid(
                  files: processed,
                  canTapToReturn: false,
                  onDelete: _deleteProcessed,
                  showDownload: true,
                ),
              ],
            ),
    );
  }

  /// 共用：圓形小按鈕（半透明黑底、白 icon）
  Widget _circleIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final btn = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28, // ⬅️ 縮小
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.black45, // 半透明黑底
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: Colors.white), // ⬅️ 白 icon
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Widget _buildGrid({
    required List<File> files,
    required bool canTapToReturn,
    required Future<void> Function(File) onDelete,
    required bool showDownload,
  }) {
    if (files.isEmpty) {
      return const Center(child: Text('No images yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (_, i) {
        final f = files[i];
        return GestureDetector(
          onTap: canTapToReturn ? () => Navigator.pop<File?>(context, f) : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(f, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDownload) ...[
                      _circleIcon(
                        icon: Icons.download_rounded,
                        onTap: () => _downloadProcessed(f),
                        tooltip: 'Download',
                      ),
                      const SizedBox(width: 6),
                    ],
                    _circleIcon(
                      icon: Icons.delete,
                      onTap: () => onDelete(f),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
