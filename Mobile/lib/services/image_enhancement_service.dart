import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for enhancing document images using advanced image processing
class ImageEnhancementService {
  /// Enhance image quality for better OCR results using advanced algorithms
  static Future<File?> enhanceImage(File originalImage) async {
    try {
      // Read the original image
      final imageBytes = await originalImage.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        if (kDebugMode) {
          print('Failed to decode image');
        }
        return originalImage;
      }

      // Apply comprehensive image enhancements
      img.Image enhancedImage = image;

      // 1. Resize to optimal dimensions first (before processing for efficiency)
      enhancedImage = _resizeForOCR(enhancedImage);

      // 2. Apply denoising
      enhancedImage = _advancedDenoising(enhancedImage);

      // 3. Improve contrast and brightness with histogram equalization
      enhancedImage = _improveContrastWithHistogramEqualization(enhancedImage);

      // 4. Apply unsharp masking for better text clarity
      enhancedImage = _applyUnsharpMask(enhancedImage);

      // 5. Final fine-tuning
      enhancedImage = _finalTuning(enhancedImage);

      // Save the enhanced image
      final enhancedFile = await _saveEnhancedImage(
        enhancedImage,
        originalImage.path,
      );

      if (kDebugMode) {
        print('Image enhanced successfully');
      }

      return enhancedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error enhancing image: $e');
      }
      return originalImage; // Return original on error
    }
  }

  /// Apply automatic document enhancement for scanned documents using OpenCV
  static Future<File?> enhanceDocumentImage(File documentImage) async {
    try {
      if (kDebugMode) {
        print('Starting document image enhancement...');
      }

      // Try OpenCV enhancement first (more powerful)
      final openCVResult = await _enhanceWithOpenCV(documentImage);
      if (openCVResult != null) {
        if (kDebugMode) {
          print('Document enhanced successfully with OpenCV');
        }
        return openCVResult;
      }

      if (kDebugMode) {
        print('OpenCV enhancement failed, falling back to standard enhancement');
      }

      // Fallback to standard enhancement
      return await _enhanceDocumentImageStandard(documentImage);
    } catch (e) {
      if (kDebugMode) {
        print('Error in document enhancement: $e');
      }
      return documentImage; // Return original on error
    }
  }

  /// Enhanced document processing using OpenCV
  static Future<File?> _enhanceWithOpenCV(File documentImage) async {
    try {
      final imageBytes = await documentImage.readAsBytes();
      
      // Convert to OpenCV Mat
      final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) {
        if (kDebugMode) {
          print('Failed to decode image with OpenCV');
        }
        return null;
      }

      // 1. Convert to grayscale for document processing
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // 2. Apply bilateral filter for noise reduction while preserving edges
      final denoised = cv.bilateralFilter(gray, 9, 75, 75);

      // 3. Apply adaptive thresholding for better text contrast
      final thresh = cv.adaptiveThreshold(
        denoised,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY,
        11,
        2,
      );

      // 4. Apply morphological operations to improve text quality
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final morphed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);

      // 5. Convert back to 3-channel for saving
      final result = cv.cvtColor(morphed, cv.COLOR_GRAY2BGR);

      // Encode back to bytes
      final (success, resultBytes) = cv.imencode('.jpg', result);
      
      if (!success) {
        if (kDebugMode) {
          print('Failed to encode OpenCV result');
        }
        return null;
      }

      // Save the enhanced image
      final enhancedFile = await _saveEnhancedImageFromBytes(
        resultBytes,
        documentImage.path,
      );

      // Clean up OpenCV mats
      mat.dispose();
      gray.dispose();
      denoised.dispose();
      thresh.dispose();
      morphed.dispose();
      result.dispose();
      kernel.dispose();

      return enhancedFile;
    } catch (e) {
      if (kDebugMode) {
        print('OpenCV enhancement error: $e');
      }
      return null;
    }
  }

  /// Standard document enhancement using the image package
  static Future<File?> _enhanceDocumentImageStandard(File documentImage) async {
    try {
      final imageBytes = await documentImage.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        if (kDebugMode) {
          print('Failed to decode document image');
        }
        return documentImage;
      }

      img.Image enhancedImage = image;

      // Document-specific enhancements

      // 1. Resize for optimal processing
      enhancedImage = _resizeForOCR(enhancedImage);

      // 2. Convert to grayscale for better document processing
      enhancedImage = img.grayscale(enhancedImage);

      // 3. Apply histogram equalization for better contrast
      enhancedImage = _applyHistogramEqualization(enhancedImage);

      // 4. Apply adaptive contrast enhancement
      enhancedImage = _applyAdaptiveContrast(enhancedImage);

      // 5. Apply sharpening for better text clarity
      enhancedImage = _applyAdvancedSharpening(enhancedImage);

      // Save the enhanced document image
      final enhancedFile = await _saveEnhancedImage(
        enhancedImage,
        documentImage.path,
      );

      if (kDebugMode) {
        print('Document image enhanced successfully with standard methods');
      }

      return enhancedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error enhancing document image: $e');
      }
      return documentImage; // Return original on error
    }
  }

  /// Advanced denoising using multiple passes
  static img.Image _advancedDenoising(img.Image image) {
    // Apply multiple denoising passes
    img.Image denoised = image;

    // 1. Slight gaussian blur to reduce high-frequency noise
    denoised = img.gaussianBlur(denoised, radius: 1);

    // 2. Median filter effect using resize and blur combination
    final smaller = img.copyResize(denoised, 
        width: (denoised.width * 0.98).round(),
        height: (denoised.height * 0.98).round());
    denoised = img.copyResize(smaller, 
        width: denoised.width, 
        height: denoised.height);

    return denoised;
  }

  /// Improve contrast using histogram equalization
  static img.Image _improveContrastWithHistogramEqualization(img.Image image) {
    // Apply histogram equalization for better contrast distribution
    return img.normalize(image, min: 0, max: 255);
  }

  /// Apply histogram equalization
  static img.Image _applyHistogramEqualization(img.Image image) {
    // Convert to grayscale if not already
    final grayImage = img.grayscale(image);
    
    // Apply histogram stretching
    return img.contrast(grayImage, contrast: 1.3);
  }

  /// Apply adaptive contrast enhancement
  static img.Image _applyAdaptiveContrast(img.Image image) {
    // Apply local contrast enhancement
    return img.adjustColor(image, 
        contrast: 1.4, 
        brightness: 1.1,
        gamma: 0.9);
  }

  /// Apply unsharp masking for better text clarity
  static img.Image _applyUnsharpMask(img.Image image) {
    // Apply sharpening by increasing contrast (simulated unsharp masking)
    img.Image result = img.copyResize(image, width: image.width, height: image.height);
    
    // Apply sharpening by increasing contrast
    result = img.adjustColor(result, contrast: 1.2);
    
    return result;
  }

  /// Apply advanced sharpening
  static img.Image _applyAdvancedSharpening(img.Image image) {
    // Multiple-pass sharpening
    img.Image sharpened = image;
    
    // First pass: light sharpening
    sharpened = img.adjustColor(sharpened, contrast: 1.15);
    
    // Second pass: edge enhancement
    sharpened = img.adjustColor(sharpened, contrast: 1.1, saturation: 0.8);
    
    return sharpened;
  }

  /// Final tuning adjustments
  static img.Image _finalTuning(img.Image image) {
    // Final adjustments for optimal OCR
    return img.adjustColor(image, 
        contrast: 1.05, 
        brightness: 1.02,
        saturation: 0.95);
  }

  /// Resize image to optimal size for OCR with better scaling
  static img.Image _resizeForOCR(img.Image image) {
    const int targetWidth = 1600;  // Increased for better OCR
    const int targetHeight = 1200;
    const int minWidth = 1000;     // Increased minimum
    const int minHeight = 750;

    int width = image.width;
    int height = image.height;

    // Calculate the aspect ratio
    final aspectRatio = width / height;

    // If image is too small, upscale it
    if (width < minWidth || height < minHeight) {
      if (aspectRatio > 1) {
        // Landscape
        width = math.max(minWidth, (minHeight * aspectRatio).round());
        height = math.max(minHeight, (width / aspectRatio).round());
      } else {
        // Portrait
        height = math.max(minHeight, (minWidth / aspectRatio).round());
        width = math.max(minWidth, (height * aspectRatio).round());
      }
    }

    // If image is too large, downscale it proportionally
    if (width > targetWidth || height > targetHeight) {
      final scaleX = targetWidth / width;
      final scaleY = targetHeight / height;
      final scale = math.min(scaleX, scaleY);
      width = (width * scale).round();
      height = (height * scale).round();
    }

    if (width != image.width || height != image.height) {
      return img.copyResize(image, 
          width: width, 
          height: height,
          interpolation: img.Interpolation.cubic);
    }

    return image;
  }

  /// Save enhanced image from bytes (for OpenCV results)
  static Future<File> _saveEnhancedImageFromBytes(
    Uint8List imageBytes,
    String originalPath,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(
      path.join(directory.path, 'pdf_extractor_cache'),
    );

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final originalName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final enhancedFileName = '${originalName}_enhanced_opencv_$timestamp.jpg';
    final enhancedPath = path.join(cacheDir.path, enhancedFileName);

    final enhancedFile = File(enhancedPath);
    await enhancedFile.writeAsBytes(imageBytes);

    return enhancedFile;
  }

  /// Save the enhanced image to a temporary file
  static Future<File> _saveEnhancedImage(
    img.Image enhancedImage,
    String originalPath,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(
      path.join(directory.path, 'pdf_extractor_cache'),
    );

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final originalName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final enhancedFileName = '${originalName}_enhanced_$timestamp.jpg';
    final enhancedPath = path.join(cacheDir.path, enhancedFileName);

    // Encode the enhanced image as JPEG with high quality
    final enhancedBytes = img.encodeJpg(enhancedImage, quality: 95);

    final enhancedFile = File(enhancedPath);
    await enhancedFile.writeAsBytes(enhancedBytes);

    return enhancedFile;
  }

  /// Clean up temporary enhanced images
  static Future<void> cleanupEnhancedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(
        path.join(directory.path, 'pdf_extractor_cache'),
      );

      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.contains('_enhanced_')) {
            try {
              await file.delete();
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting enhanced image: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up enhanced images: $e');
      }
    }
  }
}
