import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfService {
  Interpreter? _interpreter;
  List<String>? _labels;
  String? _loadedModelName;

  static const int inputSize = 224; // MobileNet standard input size

  Future<void> loadModel() async {
    final candidates = [
      'assets/models/mobilenet.tflite',
      'assets/models/mobilenet_v2.tflite',
      'assets/models/MobileNet-v2_w8a8.tflite',
      'mobilenet.tflite',
    ];
    try {
      // Try candidates until one loads
      for (final name in candidates) {
        try {
          _interpreter = await Interpreter.fromAsset(name);
          _loadedModelName = name;
          debugPrint('TfService: loaded model $name');
          break;
        } catch (_) {
          // continue
        }
      }
      if (_interpreter == null) throw Exception('No tflite model found in assets');

      // 2. Load the labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      debugPrint('TfService: loaded ${_labels?.length ?? 0} labels');
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }
  /// Classify image bytes (useful when capturing from camera).
  Future<List<dynamic>> classifyBytes(Uint8List imageData) async {
    if (_interpreter == null) return [];

    // Decode and resize
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: inputSize,
      height: inputSize,
    );

    // Build input tensor as nested Lists [1][H][W][3] with normalized floats
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(
          inputSize,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    // Use raw pixel data array (avoids analyzer issues with getPixel/getBytes)
    final dynamic pixels = resizedImage.data;
    if (pixels == null) return [];
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final int pIdx = y * inputSize + x;
        final int pixel = pixels[pIdx];
        final int r = (pixel >> 16) & 0xFF;
        final int g = (pixel >> 8) & 0xFF;
        final int b = pixel & 0xFF;
        input[0][y][x][0] = (r - 127.5) / 127.5;
        input[0][y][x][1] = (g - 127.5) / 127.5;
        input[0][y][x][2] = (b - 127.5) / 127.5;
      }
    }

    final labelsLen = _labels?.length ?? 1001;
    final output = List.generate(1, (_) => List.filled(labelsLen, 0.0));

    _interpreter!.run(input, output);

    final results = (output[0] as List).map((e) => (e as num).toDouble()).toList();
    double maxScore = -double.infinity;
    int maxIndex = -1;
    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxScore) {
        maxScore = results[i];
        maxIndex = i;
      }
    }

    // Normalize confidence: if model outputs >1 (e.g., 0-255 quantized), scale to 0..1
    double normalized = 0.0;
    if (maxScore.isFinite) {
      if (maxScore > 1.01) {
        normalized = (maxScore / 255.0).clamp(0.0, 1.0);
      } else {
        normalized = maxScore.clamp(0.0, 1.0);
      }
    }

    if (maxIndex != -1 && _labels != null && maxIndex < _labels!.length) {
      return [
        {"label": _labels![maxIndex], "confidence": normalized, "raw_score": maxScore},
      ];
    }

    return [{"label": "Unknown", "confidence": 0.0, "raw_score": maxScore}];
  }

  Future<List<dynamic>> classifyImage(String imagePath) async {
    final bytes = File(imagePath).readAsBytesSync();
    return classifyBytes(Uint8List.fromList(bytes));
  }

  List<String>? getLabels() => _labels;
  bool get isLoaded => _interpreter != null;

  String? get loadedModelName => _loadedModelName;

  void close() {
    _interpreter?.close();
  }
}
