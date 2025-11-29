// lib/pages/image_tool_page.dart
// NOTE: All strings/identifiers in English; comments in Chinese.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/media_service.dart';
import '../../home/state/media_state.dart';
import 'image_library_page.dart';
import '../../../core/services/onnx_service.dart';
import 'dart:async';

Widget _denseDropdownWrapper({required Widget child}) {
  return SizedBox(height: 40, child: child);
}

class ImageToolPage extends StatefulWidget {
  const ImageToolPage({super.key});
  @override
  State<ImageToolPage> createState() => _ImageToolPageState();
}

class _ImageToolPageState extends State<ImageToolPage> {
  final media = MediaService();

  String currentModel = 'assets/models/Medium.onnx';

  bool processing = false;

  Future<void> _openLibrary() async {
    final mediaState = context.read<MediaState>();
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const ImageLibraryPage()),
    );
    if (result != null) {
      mediaState.setCurrentImage(result);
      setState(() {
        mediaState.markProcessed(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = context.watch<MediaState>();
    final isProcessed = mediaState.isImageProcessed;
    final current = mediaState.currentImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Tool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: _openLibrary,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Model',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: inputDecoration(contentPadding: EdgeInsets.zero),
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: _denseDropdownWrapper(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      iconSize: 24,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Colors.white,
                      elevation: 3,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      value: currentModel,
                      items: const [
                        DropdownMenuItem(
                          value: 'assets/models/Medium.onnx',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: 'assets/models/Sub-Conservative.onnx',
                          child: Text('Sub-Conservative'),
                        ),
                        DropdownMenuItem(
                          value: 'assets/models/Conservative.onnx',
                          child: Text('Conservative'),
                        ),
                        DropdownMenuItem(
                          value: 'assets/models/Radical.onnx',
                          child: Text('Radical'),
                        ),
                      ],
                      onChanged: (v) => setState(() => currentModel = v!),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: (current == null)
                    ? const Text('No image')
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(current, fit: BoxFit.contain),
                            ),
                          ),
                          if (isProcessed)
                            Positioned(
                              top: 8,
                              right: 16,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SmallCircleButton(
                                    icon: Icons.download_outlined,
                                    backgroundColor: const Color(0xFFD9ECFF),
                                    iconColor: const Color(0xFF007AFF),
                                    onTap: _downloadProcessed,
                                  ),
                                  const SizedBox(width: 6),
                                  _SmallCircleButton(
                                    icon: Icons.close_rounded,
                                    backgroundColor: const Color(0xFFFFEBEE),
                                    iconColor: Colors.red,
                                    onTap: _clearCurrentFromView,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: processing
                            ? Colors.red
                            : (isProcessed ? Colors.grey : Colors.green),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: (current == null || processing || isProcessed)
                          ? null
                          : () async {
                              setState(() => processing = true);
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              try {
                                final ms = context.read<MediaState>();
                                final src = ms.currentImage;
                                if (src == null) return;

                                await media.saveAsOriginal(src);

                                final imageBytes = await src.readAsBytes();

                                final modelFileName = currentModel
                                    .split('/')
                                    .last;

                                final outBytes = await OnnxService()
                                    .run(imageBytes, modelFileName)
                                    .timeout(
                                      const Duration(seconds: 20),
                                      onTimeout: () {
                                        throw TimeoutException(
                                          'ONNX inference timed out',
                                        );
                                      },
                                    );

                                final tmpDir = await Directory.systemTemp
                                    .createTemp('onnx_');
                                final tmpPath =
                                    '${tmpDir.path}/enh_${DateTime.now().millisecondsSinceEpoch}.png';
                                final tmpFile = await File(
                                  tmpPath,
                                ).writeAsBytes(outBytes);

                                final processedFile = await media
                                    .saveAsProcessed(tmpFile);

                                if (!mounted) return;

                                ms.setCurrentImage(processedFile);
                                ms.markProcessed(true);

                                await ms.addImage(
                                  name: processedFile.uri.pathSegments.last,
                                  path: processedFile.path,
                                );
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Process failed: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => processing = false);
                              }
                            },
                      child: Text(
                        processing
                            ? 'Processing...'
                            : (isProcessed
                                  ? 'Already Enhanced'
                                  : 'Start Enhancement'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.accent,
                      ),
                    ),
                    onPressed: processing
                        ? null
                        : () async {
                            final ms = context.read<MediaState>();
                            final f = await media.captureFromCamera();
                            if (f != null) {
                              ms.setCurrentImage(f);
                              ms.markProcessed(false);
                            }
                          },

                    icon: const Icon(Icons.photo_camera_outlined),
                    iconSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.white),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                    onPressed: processing
                        ? null
                        : () async {
                            final ms = context.read<MediaState>();
                            final f = await media.pickFromGallery();
                            if (f != null) {
                              ms.setCurrentImage(f);
                              ms.markProcessed(false);
                            }
                          },
                    icon: const Icon(Icons.perm_media),
                    iconSize: 20,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearCurrentFromView() {
    context.read<MediaState>().setCurrentImage(null);
    context.read<MediaState>().markProcessed(false);
  }

  Future<void> _downloadProcessed() async {
    final ms = context.read<MediaState>();
    final img = ms.currentImage;
    if (!ms.isImageProcessed || img == null) return;

    final ok = await MediaService().saveProcessedToDevice(
      img,
      album: 'LearningGO',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Saved to Photos' : 'Save failed')),
      );
    }
  }
}

class _SmallCircleButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _SmallCircleButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
