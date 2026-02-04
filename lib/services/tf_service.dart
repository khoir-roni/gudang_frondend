import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TfService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int inputSize = 224; // MobileNet standard input size

  Future<void> loadModel() async {
    try {
      // 1. Load the model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet.tflite',
      );

      // 2. Load the labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n');

      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<List<dynamic>> classifyImage(String imagePath) async {
    if (_interpreter == null) return [];

    // 1. Read image from disk
    final imageData = File(imagePath).readAsBytesSync();

    // 2. Decode and Resize
    // We use the 'image' package to resize to 224x224
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    img.Image resizedImage = img.copyResize(
      originalImage,
      width: inputSize,
      height: inputSize,
    );

    // 3. Convert image to Matrix (Input Tensor)
    // [1, 224, 224, 3] -> 1 image, 224x224 pixels, 3 channels (RGB)
    var input = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          // For Quantized model (uint8), we use 0-255 directly.
          // If using Float model, you must normalize ((val - 127.5) / 127.5)
          return [pixel.r, pixel.g, pixel.b];
        }),
      ),
    );

    // 4. Output Tensor container
    // MobileNet usually outputs 1001 probabilities
    var output = List.filled(1 * 1001, 0).reshape([1, 1001]);

    // 5. Run Inference
    _interpreter!.run(input, output);

    // 6. Parse Results
    // Find the index with the highest probability
    var outputList = output[0] as List;
    var maxScore = 0.0;
    var maxIndex = 0;

    for (int i = 0; i < outputList.length; i++) {
      if (outputList[i] > maxScore) {
        maxScore = outputList[i] + 0.0; // Ensure double
        maxIndex = i;
      }
    }

    // Return the top result
    // if (_labels != null && maxIndex < _labels!.length) {
    //   return [
    //     {
    //       "label": _labels![maxIndex],
    //       "confidence": (maxScore / 255.0) * 100, // Convert uint8 score to %
    //     },
    //   ];
    // }
    // Return the top result
    if (_labels != null && maxIndex < _labels!.length) {
      return [
        {
          "label": _labels![maxIndex],
          // Pastikan dikonversi ke double 0-100
          "confidence": (maxScore / 255.0) * 100,
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
}
