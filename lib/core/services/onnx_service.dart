import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

/// 前處理參數（用於 Isolate 傳遞）
class _PreprocessResult {
  final Float32List input;
  final int originalWidth;
  final int originalHeight;

  _PreprocessResult({
    required this.input,
    required this.originalWidth,
    required this.originalHeight,
  });
}

/// 後處理參數（用於 Isolate 傳遞）
class _PostprocessParams {
  final List<dynamic> rawOutput;
  final int originalWidth;
  final int originalHeight;

  _PostprocessParams({
    required this.rawOutput,
    required this.originalWidth,
    required this.originalHeight,
  });
}

/// 在 Isolate 中執行前處理（CPU 密集）
_PreprocessResult _preprocessInIsolate(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes)!;

  final originalWidth = image.width;
  final originalHeight = image.height;

  final resized = img.copyResize(
    image,
    width: 224,
    height: 224,
    interpolation: img.Interpolation.linear,
  );

  final Float32List input = Float32List(1 * 3 * 224 * 224);
  int idx = 0;

  for (int c = 0; c < 3; c++) {
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);

        double v;
        if (c == 0) {
          v = pixel.r / 255.0;
        } else if (c == 1) {
          v = pixel.g / 255.0;
        } else {
          v = pixel.b / 255.0;
        }

        input[idx++] = v;
      }
    }
  }

  return _PreprocessResult(
    input: input,
    originalWidth: originalWidth,
    originalHeight: originalHeight,
  );
}

/// 在 Isolate 中執行後處理（CPU 密集）
Uint8List _postprocessInIsolate(_PostprocessParams params) {
  final raw = params.rawOutput;
  final originalW = params.originalWidth;
  final originalH = params.originalHeight;

  // raw = [1][3][224][224]
  final batch = raw;
  final channels = batch[0] as List;
  final outR = channels[0] as List;
  final outG = channels[1] as List;
  final outB = channels[2] as List;

  final img.Image out = img.Image(width: 224, height: 224);

  for (int y = 0; y < 224; y++) {
    final rowR = outR[y] as List;
    final rowG = outG[y] as List;
    final rowB = outB[y] as List;

    for (int x = 0; x < 224; x++) {
      final r = (rowR[x] * 255).clamp(0, 255).toInt();
      final g = (rowG[x] * 255).clamp(0, 255).toInt();
      final b = (rowB[x] * 255).clamp(0, 255).toInt();

      out.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }

  // 回原始圖片尺寸
  final img.Image restored = img.copyResize(
    out,
    width: originalW,
    height: originalH,
    interpolation: img.Interpolation.cubic,
  );

  return Uint8List.fromList(img.encodePng(restored));
}

class OnnxService {
  static final OnnxService _instance = OnnxService._internal();
  factory OnnxService() => _instance;
  OnnxService._internal();

  late OrtSession _session;
  bool _initialized = false;
  String _currentModel = "";

  /// 初始化 ONNX（加入模型名稱）
  Future<void> _init(String modelName) async {
    // 如果模型沒變，不重複載入
    if (_initialized && _currentModel == modelName) return;

    final raw = await rootBundle.load('assets/models/$modelName');
    final bytes = raw.buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);

    _initialized = true;
    _currentModel = modelName;

    debugPrint("🔵 Loaded model: $modelName");
  }

  /// 執行圖片增強
  /// 前處理和後處理在背景 Isolate 執行，避免阻塞 UI
  Future<Uint8List> run(Uint8List imageBytes, String modelName) async {
    await _init(modelName);

    // ✅ 前處理在 Isolate 執行（圖片解碼 + resize + 轉 tensor）
    final prep = await compute(_preprocessInIsolate, imageBytes);

    // ONNX 推論必須在主執行緒（Session 不能跨 Isolate）
    final inputTensor = OrtValueTensor.createTensorWithDataList(prep.input, [
      1,
      3,
      224,
      224,
    ]);

    final options = OrtRunOptions();
    final inputName = _session.inputNames[0];

    final outputs = _session.run(options, {inputName: inputTensor});
    final rawOutput = outputs[0]!.value;

    inputTensor.release();
    options.release();

    // ✅ 後處理在 Isolate 執行（tensor 轉圖片 + resize + encode PNG）
    final result = await compute(
      _postprocessInIsolate,
      _PostprocessParams(
        rawOutput: rawOutput as List<dynamic>,
        originalWidth: prep.originalWidth,
        originalHeight: prep.originalHeight,
      ),
    );

    return result;
  }
}
