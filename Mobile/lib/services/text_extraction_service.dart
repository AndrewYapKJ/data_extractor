import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextExtractionService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image file using Google ML Kit
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      StringBuffer extractedText = StringBuffer();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
      }

      return extractedText.toString().trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting text from image: $e');
      }
      rethrow;
    }
  }

  /// Extract text from multiple images and combine them
  static Future<String> extractTextFromMultipleImages(
    List<File> imageFiles,
  ) async {
    StringBuffer combinedText = StringBuffer();

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final text = await extractTextFromImage(imageFiles[i]);
        if (text.isNotEmpty) {
          combinedText.writeln('--- Image ${i + 1} ---');
          combinedText.writeln(text);
          combinedText.writeln();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing image ${i + 1}: $e');
        }
      }
    }

    return combinedText.toString().trim();
  }

  /// Get text recognition confidence for an image
  static Future<Map<String, dynamic>> getTextRecognitionDetails(
    File imageFile,
  ) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      List<Map<String, dynamic>> blocks = [];
      double totalConfidence = 0;
      int elementCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        List<Map<String, dynamic>> lines = [];

        for (TextLine line in block.lines) {
          List<Map<String, dynamic>> elements = [];

          for (TextElement element in line.elements) {
            elements.add({
              'text': element.text,
              'confidence': element.confidence,
              'boundingBox': {
                'left': element.boundingBox.left,
                'top': element.boundingBox.top,
                'right': element.boundingBox.right,
                'bottom': element.boundingBox.bottom,
              },
            });
            totalConfidence += element.confidence ?? 0;
            elementCount++;
          }

          lines.add({'text': line.text, 'elements': elements});
        }

        blocks.add({'text': block.text, 'lines': lines});
      }

      return {
        'fullText': recognizedText.text,
        'averageConfidence':
            elementCount > 0 ? totalConfidence / elementCount : 0,
        'blocks': blocks,
        'totalBlocks': blocks.length,
        'totalElements': elementCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting text recognition details: $e');
      }
      rethrow;
    }
  }

  /// Dispose of resources
  static void dispose() {
    _textRecognizer.close();
  }
}
