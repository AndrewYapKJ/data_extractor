import 'dart:io';
import 'package:flutter/foundation.dart';
import 'edge_detection_service.dart';
import 'text_extraction_service.dart';
import 'pdf_generation_service.dart';
import 'image_enhancement_service.dart';

/// Enhanced document processing service that combines edge detection,
/// text extraction, and PDF generation in a single workflow
class DocumentProcessingService {
  /// Capture document with edge detection and optionally extract text and create PDF
  static Future<DocumentProcessingResult?> captureAndProcessDocument({
    bool extractText = true,
    bool createPDF = true,
    bool enhanceImage = true,
  }) async {
    try {
      // Step 1: Capture image with edge detection
      final scannedImagePath =
          await EdgeDetectionService.captureWithEdgeDetection();

      if (scannedImagePath == null) {
        return null;
      }

      final scannedImage = File(scannedImagePath);

      // Step 2: Enhance image quality if requested
      File? enhancedImage;
      if (enhanceImage) {
        enhancedImage = await _enhanceImageQuality(scannedImage);
      }

      final finalImage = enhancedImage ?? scannedImage;

      // Step 3: Extract text if requested
      String? extractedText;
      if (extractText) {
        try {
          extractedText = await TextExtractionService.extractTextFromImage(
            finalImage,
          );
          if (kDebugMode) {
            print('Extracted text length: ${extractedText.length} characters');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error extracting text: $e');
          }
          // Continue without text extraction
        }
      }

      // Step 4: Create PDF if requested
      String? pdfPath;
      if (createPDF) {
        try {
          if (extractedText != null && extractedText.isNotEmpty) {
            // Create PDF with both image and extracted text
            pdfPath = await _createEnhancedPDF(
              image: finalImage,
              extractedText: extractedText,
            );
          } else {
            // Create PDF with just the image
            pdfPath = await PDFGenerationService.createPDFFromImage(
              finalImage.path,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error creating PDF: $e');
          }
          // Continue without PDF creation
        }
      }

      return DocumentProcessingResult(
        imagePath: finalImage.path,
        extractedText: extractedText,
        pdfPath: pdfPath,
        hasText: extractedText != null && extractedText.isNotEmpty,
        wordCount:
            extractedText
                ?.split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length ??
            0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in document processing: $e');
      }
      return null;
    }
  }

  /// Process multiple pages into a single comprehensive PDF
  static Future<DocumentProcessingResult?> captureAndProcessMultiplePages({
    int maxPages = 5,
    bool extractText = true,
    bool enhanceImages = true,
  }) async {
    try {
      // Step 1: Capture multiple pages with edge detection
      final scannedImagePaths = await EdgeDetectionService.captureMultiplePages(
        maxPages: maxPages,
      );

      if (scannedImagePaths == null || scannedImagePaths.isEmpty) {
        return null;
      }

      final scannedImages =
          scannedImagePaths.map((path) => File(path)).toList();

      // Step 2: Enhance image quality if requested
      List<File> finalImages = [];
      if (enhanceImages) {
        for (final image in scannedImages) {
          final enhanced = await _enhanceImageQuality(image);
          finalImages.add(enhanced ?? image);
        }
      } else {
        finalImages = scannedImages;
      }

      // Step 3: Extract text from all pages if requested
      String? combinedText;
      if (extractText) {
        try {
          combinedText =
              await TextExtractionService.extractTextFromMultipleImages(
                finalImages,
              );
          if (kDebugMode) {
            print('Combined text length: ${combinedText.length} characters');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error extracting text from multiple images: $e');
          }
          // Continue without text extraction
        }
      }

      // Step 4: Create comprehensive PDF
      String? pdfPath;
      try {
        if (combinedText != null && combinedText.isNotEmpty) {
          // Create PDF with both images and extracted text
          pdfPath = await _createMultiPageEnhancedPDF(
            images: finalImages,
            extractedText: combinedText,
          );
        } else {
          // Create PDF with just the images
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'multi_page_scan_$timestamp.pdf';

          final pdfFile = await PDFGenerationService.generatePDFFromImages(
            imageFiles: finalImages,
            fileName: fileName,
            title: 'Scanned Document',
          );
          pdfPath = pdfFile.path;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating multi-page PDF: $e');
        }
        return null;
      }

      // Clean up temporary image files
      for (final imagePath in scannedImagePaths) {
        try {
          await File(imagePath).delete();
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting temporary file $imagePath: $e');
          }
        }
      }

      return DocumentProcessingResult(
        imagePath: finalImages.first.path, // Return path of first image
        extractedText: combinedText,
        pdfPath: pdfPath,
        hasText: combinedText != null && combinedText.isNotEmpty,
        wordCount:
            combinedText
                ?.split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length ??
            0,
        pageCount: finalImages.length,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in multi-page document processing: $e');
      }
      return null;
    }
  }

  /// Enhance image quality (now using actual image enhancement algorithms)
  static Future<File?> _enhanceImageQuality(File originalImage) async {
    try {
      // Use the ImageEnhancementService for better document processing
      final enhancedImage = await ImageEnhancementService.enhanceDocumentImage(
        originalImage,
      );

      if (kDebugMode) {
        print('Image enhancement completed');
      }

      return enhancedImage;
    } catch (e) {
      if (kDebugMode) {
        print('Error enhancing image quality: $e');
      }
      return originalImage;
    }
  }

  /// Create PDF with image and extracted text
  static Future<String?> _createEnhancedPDF({
    required File image,
    required String extractedText,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'enhanced_document_$timestamp.pdf';

      final pdfFile = await PDFGenerationService.generateCombinedPDF(
        imageFiles: [image],
        extractedText: extractedText,
        fileName: fileName,
        title: 'Scanned Document with OCR',
      );

      return pdfFile.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating enhanced PDF: $e');
      }
      return null;
    }
  }

  /// Create multi-page PDF with images and extracted text
  static Future<String?> _createMultiPageEnhancedPDF({
    required List<File> images,
    required String extractedText,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'multi_page_enhanced_document_$timestamp.pdf';

      final pdfFile = await PDFGenerationService.generateCombinedPDF(
        imageFiles: images,
        extractedText: extractedText,
        fileName: fileName,
        title: 'Multi-Page Scanned Document with OCR',
      );

      return pdfFile.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating multi-page enhanced PDF: $e');
      }
      return null;
    }
  }
}

/// Result class for document processing operations
class DocumentProcessingResult {
  final String imagePath;
  final String? extractedText;
  final String? pdfPath;
  final bool hasText;
  final int wordCount;
  final int pageCount;

  DocumentProcessingResult({
    required this.imagePath,
    this.extractedText,
    this.pdfPath,
    required this.hasText,
    required this.wordCount,
    this.pageCount = 1,
  });

  @override
  String toString() {
    return 'DocumentProcessingResult('
        'imagePath: $imagePath, '
        'hasText: $hasText, '
        'wordCount: $wordCount, '
        'pageCount: $pageCount, '
        'hasPDF: ${pdfPath != null}'
        ')';
  }
}
