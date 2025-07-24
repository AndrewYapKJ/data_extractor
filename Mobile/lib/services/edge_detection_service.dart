import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class EdgeDetectionService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Check if ML Kit Document Scanner is available (Android only)
  static bool get isMLKitAvailable => Platform.isAndroid;

  /// Capture image with automatic edge detection using Google ML Kit Document Scanner
  static Future<String?> captureWithEdgeDetection() async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission not granted');
      }

      // Check if ML Kit Document Scanner is available (Android only)
      if (!isMLKitAvailable) {
        if (kDebugMode) {
          print(
            'ML Kit Document Scanner is only available on Android. Falling back to image picker.',
          );
        }
        return await _fallbackImageCapture();
      }

      // Create document scanner options
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: false,
      );

      // Initialize the document scanner
      final documentScanner = DocumentScanner(options: options);

      // Scan document
      final DocumentScanningResult result =
          await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        // Get the first scanned image path
        final imagePath = result.images.first;

        // Copy the scanned image to our app directory
        final savedPath = await _saveScannedImage(File(imagePath));

        // Clean up scanner resources
        documentScanner.close();

        return savedPath;
      }

      // Clean up scanner resources
      documentScanner.close();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in ML Kit document scanning: $e');
      }
      return null;
    }
  }

  /// Fallback method for iOS - uses image picker instead of ML Kit Document Scanner
  static Future<String?> _fallbackImageCapture() async {
    try {
      // Capture image with camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        // Save the image to app directory
        final savedPath = await _saveScannedImage(File(image.path));
        return savedPath;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in fallback image capture: $e');
      }
      return null;
    }
  }

  /// Capture multiple pages with automatic edge detection
  static Future<List<String>?> captureMultiplePages({int maxPages = 5}) async {
    try {
      // Request camera permission
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission not granted');
      }

      // Check if ML Kit Document Scanner is available (Android only)
      if (!isMLKitAvailable) {
        if (kDebugMode) {
          print(
            'ML Kit Document Scanner is only available on Android. Multi-page scanning not available on iOS.',
          );
        }
        // Return single image capture for iOS
        final singleImage = await _fallbackImageCapture();
        return singleImage != null ? [singleImage] : null;
      }

      // Create options for multi-page scanning
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: maxPages,
        isGalleryImport: false,
      );

      final documentScanner = DocumentScanner(options: options);

      // Scan document
      final DocumentScanningResult result =
          await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        List<String> savedPaths = [];

        for (int i = 0; i < result.images.length; i++) {
          final imagePath = result.images[i];
          final savedPath = await _saveScannedImage(
            File(imagePath),
            pageNumber: i + 1,
          );
          if (savedPath != null) {
            savedPaths.add(savedPath);
          }
        }

        // Clean up
        documentScanner.close();

        return savedPaths.isNotEmpty ? savedPaths : null;
      }

      // Clean up
      documentScanner.close();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in ML Kit multi-page document scanning: $e');
      }
      return null;
    }
  }

  /// Save the scanned image to application documents directory
  static Future<String?> _saveScannedImage(
    File scannedImage, {
    int? pageNumber,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(
        path.join(directory.path, 'pdf_extractor_cache'),
      );

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pagePrefix = pageNumber != null ? '_page_$pageNumber' : '';
      final fileName = 'scanned_document_$timestamp$pagePrefix.jpg';
      final newPath = path.join(cacheDir.path, fileName);

      await scannedImage.copy(newPath);

      if (kDebugMode) {
        print('Scanned image saved to: $newPath');
      }

      return newPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving scanned image: $e');
      }
      return null;
    }
  }

  /// Check if ML Kit Document Scanner is available on the device
  static Future<bool> isDocumentScannerAvailable() async {
    try {
      // Create minimal options to test availability
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 1,
      );

      // Try to create the scanner - if it fails, the feature is not available
      DocumentScanner(options: options);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Document scanner not available: $e');
      }
      return false;
    }
  }

  /// Get camera permission status
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
