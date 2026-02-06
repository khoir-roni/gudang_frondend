import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfService {
  Interpreter? _interpreter;
  List<String>? _labels;
  List<int>? _outputShape;

  static const int inputSize = 224; // MobileNet standard input size

  Future<void> loadModel() async {
    try {
      // 1. Load the model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet.tflite',
      );

      // 2. Get output shape from interpreter
      if (_interpreter != null) {
        final outputTensors = _interpreter!.getOutputTensors();
        if (outputTensors.isNotEmpty) {
          _outputShape = List<int>.from(outputTensors[0].shape);
          print("Output shape: $_outputShape");
        }
      }

      // 3. Load the labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print("Model loaded successfully with ${_labels?.length ?? 0} labels");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<List<dynamic>> classifyImage(String imagePath) async {
    final bytes = File(imagePath).readAsBytesSync();
    return classifyBytes(Uint8List.fromList(bytes));
  }

  Future<List<dynamic>> classifyBytes(Uint8List imageData) async {
    if (_interpreter == null || _outputShape == null) return [];

    // 1. Decode and Resize
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: inputSize,
      height: inputSize,
    );

    // 2. Convert image to Matrix (Input Tensor)
    // Teachable Machine expects RGB values 0-255 (not normalized)
    var input = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixelColor = resizedImage.getPixel(x, y);
          // Extract R, G, B values from pixel
          final r = pixelColor.r as int;
          final g = pixelColor.g as int;
          final b = pixelColor.b as int;
          return [r, g, b];
        }),
      ),
    );

    // 3. Calculate output size dynamically from actual model output shape
    int outputSize = 1;
    for (int dim in _outputShape!) {
      outputSize *= dim;
    }

    // 4. Output Tensor container with dynamic size
    var output = List.filled(outputSize, 0.0).reshape(_outputShape!);

    // 5. Run Inference
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      print("Inference error: $e");
      return [];
    }

    // 6. Parse Results
    var outputList = output[0] as List;
    var maxScore = 0.0;
    var maxIndex = 0;

    for (int i = 0; i < outputList.length; i++) {
      final score = (outputList[i] as num).toDouble();
      if (score > maxScore) {
        maxScore = score;
        maxIndex = i;
      }
    }

    // 7. Return the top result
    if (_labels != null && maxIndex < _labels!.length) {
      // Teachable Machine outputs normalized probabilities (0-1)
      double confidence = (maxScore.clamp(0.0, 1.0) * 100);

      return [
        {
          "label": _labels![maxIndex],
          "confidence": confidence,
        },
      ];
    }

    return [
      {"label": "Unknown", "confidence": 0.0},
    ];
  }

  void close() {
    _interpreter?.close();
  }

  bool get isLoaded => _interpreter != null;
  List<String>? getLabels() => _labels;
}
