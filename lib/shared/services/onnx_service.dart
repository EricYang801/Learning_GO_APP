import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

class OnnxService {
  static final OnnxService _instance = OnnxService._internal();
  factory OnnxService() => _instance;
  OnnxService._internal();

  late OrtSession _session;
  bool _initialized = false;
  String _currentModel = ""; // ⭐ 新增：記錄目前使用的模型

  /// 初始化 ONNX（加入模型名稱）
  Future<void> _init(String modelName) async {
    // ⭐ 如果模型沒變，不重複載入
    if (_initialized && _currentModel == modelName) return;

    final raw = await rootBundle.load('assets/models/$modelName');
    final bytes = raw.buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);

    _initialized = true;
    _currentModel = modelName;

    debugPrint("🔵 Loaded model: $modelName");
  }

  /// 前處理：回傳模型需要的 224×224 & 原始尺寸
  Map<String, dynamic> _preprocess(Uint8List imageBytes) {
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

    return {"input": input, "width": originalWidth, "height": originalHeight};
  }

  /// ⭐ 新版：run 傳入 modelName
  Future<Uint8List> run(Uint8List imageBytes, String modelName) async {
    await _init(modelName);

    final prep = _preprocess(imageBytes);
    final inputFloats = prep["input"] as Float32List;
    final originalW = prep["width"] as int;
    final originalH = prep["height"] as int;

    final inputTensor = OrtValueTensor.createTensorWithDataList(inputFloats, [
      1,
      3,
      224,
      224,
    ]);

    final options = OrtRunOptions();
    final inputName = _session.inputNames[0];

    final outputs = _session.run(options, {inputName: inputTensor});
    final raw = outputs[0]!.value;

    inputTensor.release();
    options.release();

    // raw = [1][3][224][224]
    final batch = raw as List;
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

    // ⭐ 保留你原本的回原始圖片尺寸
    final img.Image restored = img.copyResize(
      out,
      width: originalW,
      height: originalH,
      interpolation: img.Interpolation.cubic,
    );

    return Uint8List.fromList(img.encodePng(restored));
  }
}
