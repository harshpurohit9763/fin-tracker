import 'dart:developer';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteHelper {
  Interpreter? _interpreter;
  static const int inputWidth = 100;
  static const int inputHeight = 32;
  static const String characters =
      '''0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ ''';

  TFLiteHelper() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/rosetta.tflite');
      log("model loded succesfully");
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<String> predict(Uint8List imageBytes) async {
    if (_interpreter == null) {
      await _loadModel();
    }
    final preprocessedImage = _preprocessImage(imageBytes);
    if (preprocessedImage == null) {
      return "Error: Could not decode image";
    }
    var input = preprocessedImage.reshape([1, inputHeight, inputWidth, 1]);
    var output = List.filled(1 * 26 * 96, 0.0).reshape([1, 26, 96]);

    _interpreter!.run(input, output);
    return _decodeOutput(output);
  }

  Float32List? _preprocessImage(Uint8List imageBytes) {
    img.Image? image;
    try {
      // First, try to decode as JPG
      image = img.decodeJpg(imageBytes);
    } catch (e) {
      // If it fails, it's not a JPG or it's corrupted.
      // Let's try to decode as PNG.
      try {
        image = img.decodePng(imageBytes);
      } catch (e2) {
        // If that also fails, it might be another format or corrupted.
        // Let's try the generic decoder as a last resort.
        image = img.decodeImage(imageBytes);
      }
    }

    if (image == null) {
      // If after all attempts, image is still null, then we can't process it.
      return null;
    }

    img.Image resizedImage =
        img.copyResize(image, width: inputWidth, height: inputHeight);
    img.Image grayscaleImage = img.grayscale(resizedImage);

    // Normalize the image
    Float32List normalizedPixels = Float32List(inputWidth * inputHeight);
    int i = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        normalizedPixels[i++] = (pixel.r / 255.0);
      }
    }
    return normalizedPixels;
  }

  String _decodeOutput(List<dynamic> output) {
    // Basic CTC decode (greedy search)
    String result = '';
    List<int> sequence = [];
    for (var step in output[0]) {
      var maxIndex = 0;
      var maxProb = 0.0;
      for (var i = 0; i < step.length; i++) {
        if (step[i] > maxProb) {
          maxProb = step[i];
          maxIndex = i;
        }
      }
      sequence.add(maxIndex);
    }

    // Remove duplicates and blank characters
    List<int> decoded = [];
    for (var i = 0; i < sequence.length; i++) {
      if (sequence[i] != 0 && (i == 0 || sequence[i] != sequence[i - 1])) {
        decoded.add(sequence[i]);
      }
    }

    for (var index in decoded) {
      if (index > 0 && index <= characters.length) {
        result += characters[index - 1];
      }
    }
    return result;
  }

  void close() {
    if (_interpreter != null) {
      _interpreter!.close();
    }
  }
}
