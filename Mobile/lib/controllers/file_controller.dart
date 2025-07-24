import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item_model.dart';
import '../models/extracted_text_model.dart';
import '../services/text_extraction_service.dart';
import '../services/pdf_generation_service.dart';
import '../services/edge_detection_service.dart';
import '../services/document_processing_service.dart';
import '../services/image_enhancement_service.dart';

class FileController extends ChangeNotifier {
  List<FileItem> _files = [];
  List<ExtractedText> _extractedTexts = [];
  bool _isLoading = false;
  bool _isExtracting = false;

  List<FileItem> get files => _files;
  List<ExtractedText> get extractedTexts => _extractedTexts;
  bool get isLoading => _isLoading;
  bool get isExtracting => _isExtracting;

  final ImagePicker _imagePicker = ImagePicker();

  FileController() {
    _loadSavedFiles();
    _loadExtractedTexts();
  }

  Future<void> _loadSavedFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList('saved_files') ?? [];

      _files =
          filesJson
              .map((jsonStr) => FileItem.fromJson(json.decode(jsonStr)))
              .where(
                (file) => File(file.path).existsSync(),
              ) // Only include existing files
              .toList();

      // Sort by upload date, newest first
      _files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved files: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson =
          _files.map((file) => json.encode(file.toJson())).toList();
      await prefs.setStringList('saved_files', filesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving files: $e');
      }
    }
  }

  Future<String> _getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(
      path.join(directory.path, 'pdf_extractor_cache'),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  Future<bool> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveFile(File(image.path), FileType.image);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      return false;
    }
  }

  Future<bool> uploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveFile(File(image.path), FileType.image);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading photo: $e');
      }
      return false;
    }
  }

  Future<bool> uploadPDF() async {
    try {
      file_picker.FilePickerResult? result = await file_picker
          .FilePicker
          .platform
          .pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: ['pdf'],
          );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await _saveFile(file, FileType.pdf);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading PDF: $e');
      }
      return false;
    }
  }

  Future<bool> _saveFile(File originalFile, FileType type) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = path.basename(originalFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(cacheDir, newFileName);

      // Copy file to cache directory
      await originalFile.copy(newPath);

      final fileStats = await originalFile.stat();
      final fileItem = FileItem(
        id: timestamp.toString(),
        name: fileName,
        path: newPath,
        type: type,
        uploadDate: DateTime.now(),
        size: fileStats.size,
      );

      _files.insert(0, fileItem); // Add to beginning of list
      await _saveFiles();
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving file: $e');
      }
      return false;
    }
  }

  Future<void> _loadExtractedTexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textsJson = prefs.getStringList('extracted_texts') ?? [];

      _extractedTexts =
          textsJson
              .map((jsonStr) => ExtractedText.fromJson(json.decode(jsonStr)))
              .toList();

      // Sort by extraction date, newest first
      _extractedTexts.sort(
        (a, b) => b.extractedDate.compareTo(a.extractedDate),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading extracted texts: $e');
      }
    }
  }

  Future<void> _saveExtractedTexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textsJson =
          _extractedTexts.map((text) => json.encode(text.toJson())).toList();
      await prefs.setStringList('extracted_texts', textsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving extracted texts: $e');
      }
    }
  }

  /// Extract text from an image file
  Future<ExtractedText?> extractTextFromFile(String fileId) async {
    try {
      _isExtracting = true;
      notifyListeners();

      final file = _files.firstWhere((f) => f.id == fileId);
      if (file.type != FileType.image) {
        throw Exception('Text extraction is only supported for images');
      }

      final extractedText = await TextExtractionService.extractTextFromImage(
        File(file.path),
      );
      final textDetails = await TextExtractionService.getTextRecognitionDetails(
        File(file.path),
      );

      final extractedTextModel = ExtractedText(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceFileId: fileId,
        text: extractedText,
        extractedDate: DateTime.now(),
        confidence: textDetails['averageConfidence'] ?? 0.0,
        metadata: {
          'totalBlocks': textDetails['totalBlocks'],
          'totalElements': textDetails['totalElements'],
          'sourceFileName': file.name,
        },
      );

      _extractedTexts.insert(0, extractedTextModel);
      await _saveExtractedTexts();

      _isExtracting = false;
      notifyListeners();

      return extractedTextModel;
    } catch (e) {
      _isExtracting = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error extracting text: $e');
      }
      rethrow;
    }
  }

  /// Extract text from multiple image files
  Future<ExtractedText?> extractTextFromMultipleFiles(
    List<String> fileIds,
  ) async {
    try {
      _isExtracting = true;
      notifyListeners();

      final imageFiles =
          fileIds
              .map((id) => _files.firstWhere((f) => f.id == id))
              .where((file) => file.type == FileType.image)
              .map((file) => File(file.path))
              .toList();

      if (imageFiles.isEmpty) {
        throw Exception('No valid image files found');
      }

      final extractedText =
          await TextExtractionService.extractTextFromMultipleImages(imageFiles);

      final extractedTextModel = ExtractedText(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceFileId: fileIds.join(','),
        text: extractedText,
        extractedDate: DateTime.now(),
        metadata: {
          'sourceFileCount': imageFiles.length,
          'sourceFileIds': fileIds,
        },
      );

      _extractedTexts.insert(0, extractedTextModel);
      await _saveExtractedTexts();

      _isExtracting = false;
      notifyListeners();

      return extractedTextModel;
    } catch (e) {
      _isExtracting = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error extracting text from multiple files: $e');
      }
      rethrow;
    }
  }

  /// Generate PDF from extracted text
  Future<FileItem?> generatePDFFromText(
    String extractedTextId, {
    String? title,
  }) async {
    try {
      final extractedText = _extractedTexts.firstWhere(
        (t) => t.id == extractedTextId,
      );

      final fileName =
          title ?? 'extracted_text_${DateTime.now().millisecondsSinceEpoch}';
      final pdfFile = await PDFGenerationService.generatePDFFromText(
        text: extractedText.text,
        fileName: fileName,
        title: title,
      );

      return await _saveExistingFile(pdfFile, FileType.pdf);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating PDF from text: $e');
      }
      rethrow;
    }
  }

  /// Generate PDF from images with optional text
  Future<FileItem?> generatePDFFromImages(
    List<String> fileIds, {
    String? title,
    bool includeExtractedText = false,
  }) async {
    try {
      final imageFiles =
          fileIds
              .map((id) => _files.firstWhere((f) => f.id == id))
              .where((file) => file.type == FileType.image)
              .map((file) => File(file.path))
              .toList();

      if (imageFiles.isEmpty) {
        throw Exception('No valid image files found');
      }

      final fileName =
          title ?? 'images_pdf_${DateTime.now().millisecondsSinceEpoch}';
      File pdfFile;

      if (includeExtractedText) {
        // Extract text first
        final extractedText =
            await TextExtractionService.extractTextFromMultipleImages(
              imageFiles,
            );
        pdfFile = await PDFGenerationService.generateCombinedPDF(
          imageFiles: imageFiles,
          extractedText: extractedText,
          fileName: fileName,
          title: title,
        );
      } else {
        pdfFile = await PDFGenerationService.generatePDFFromImages(
          imageFiles: imageFiles,
          fileName: fileName,
          title: title,
        );
      }

      return await _saveExistingFile(pdfFile, FileType.pdf);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating PDF from images: $e');
      }
      rethrow;
    }
  }

  /// Delete extracted text
  Future<bool> deleteExtractedText(String textId) async {
    try {
      final textIndex = _extractedTexts.indexWhere((text) => text.id == textId);
      if (textIndex != -1) {
        _extractedTexts.removeAt(textIndex);
        await _saveExtractedTexts();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting extracted text: $e');
      }
      return false;
    }
  }

  /// Clear all extracted texts
  Future<void> clearAllExtractedTexts() async {
    try {
      _extractedTexts.clear();
      await _saveExtractedTexts();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing extracted texts: $e');
      }
    }
  }

  /// Save an existing file (like generated PDF) to the file list
  Future<FileItem?> _saveExistingFile(File file, FileType type) async {
    try {
      final fileStats = await file.stat();
      final fileName = path.basename(file.path);

      final fileItem = FileItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: file.path,
        type: type,
        uploadDate: DateTime.now(),
        size: fileStats.size,
      );

      _files.insert(0, fileItem);
      await _saveFiles();
      notifyListeners();
      return fileItem;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving existing file: $e');
      }
      return null;
    }
  }

  Future<void> clearAllFiles() async {
    try {
      // Delete all physical files
      for (final file in _files) {
        if (await File(file.path).exists()) {
          await File(file.path).delete();
        }
      }

      _files.clear();
      _extractedTexts.clear();
      await _saveFiles();
      await _saveExtractedTexts();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing files: $e');
      }
    }
  }

  Future<bool> deleteFile(String fileId) async {
    try {
      final fileIndex = _files.indexWhere((file) => file.id == fileId);
      if (fileIndex != -1) {
        final file = _files[fileIndex];

        // Delete physical file
        if (await File(file.path).exists()) {
          await File(file.path).delete();
        }

        // Remove from list
        _files.removeAt(fileIndex);

        // Also remove any related extracted texts
        _extractedTexts.removeWhere((text) => text.sourceFileId == fileId);

        await _saveFiles();
        await _saveExtractedTexts();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      return false;
    }
  }

  Future<FileItem?> takePhotoWithEdgeDetection() async {
    try {
      setLoading(true);

      // Use edge detection service to capture and process image
      final processedImagePath =
          await EdgeDetectionService.captureWithEdgeDetection();

      if (processedImagePath != null) {
        // Create FileItem and add to list
        final fileItem = await _createFileItemFromPath(processedImagePath);
        _files.add(fileItem);
        notifyListeners();
        await _saveFiles();
        return fileItem;
      }
      return null;
    } catch (e) {
      print('Error taking photo with edge detection: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Enhanced document capture with edge detection, text extraction, and PDF creation
  Future<FileItem?> takeEnhancedDocumentPhoto({
    bool extractText = true,
    bool createPDF = true,
    bool enhanceImage = true,
  }) async {
    try {
      setLoading(true);

      // Use enhanced document processing service
      final result = await DocumentProcessingService.captureAndProcessDocument(
        extractText: extractText,
        createPDF: createPDF,
        enhanceImage: enhanceImage,
      );

      if (result != null) {
        FileItem? fileItem;

        // If PDF was created, add the PDF to files
        if (result.pdfPath != null) {
          fileItem = await _createFileItemFromPath(result.pdfPath!);
          _files.add(fileItem);

          // If text was extracted, save it as well
          if (result.hasText && result.extractedText != null) {
            final extractedText = ExtractedText(
              id: '${fileItem.id}_text',
              sourceFileId: fileItem.id,
              text: result.extractedText!,
              extractedDate: DateTime.now(),
              confidence: 0.9, // High confidence from ML Kit
              metadata: {
                'wordCount': result.wordCount,
                'characterCount': result.extractedText!.length,
                'processingMethod': 'ML Kit + Edge Detection',
              },
            );
            _extractedTexts.add(extractedText);
            await _saveExtractedTexts();
          }
        } else {
          // If no PDF, add the image
          fileItem = await _createFileItemFromPath(result.imagePath);
          _files.add(fileItem);
        }

        notifyListeners();
        await _saveFiles();
        return fileItem;
      }
      return null;
    } catch (e) {
      print('Error taking enhanced document photo: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Enhanced multi-page document capture with edge detection, text extraction, and PDF creation
  Future<FileItem?> takeEnhancedMultiplePhotos({
    int maxPages = 5,
    bool extractText = true,
    bool enhanceImages = true,
  }) async {
    try {
      setLoading(true);

      // Use enhanced document processing service for multiple pages
      final result =
          await DocumentProcessingService.captureAndProcessMultiplePages(
            maxPages: maxPages,
            extractText: extractText,
            enhanceImages: enhanceImages,
          );

      if (result != null && result.pdfPath != null) {
        // Create FileItem for the PDF
        final fileItem = await _createFileItemFromPath(result.pdfPath!);
        _files.add(fileItem);

        // If text was extracted, save it as well
        if (result.hasText && result.extractedText != null) {
          final extractedText = ExtractedText(
            id: '${fileItem.id}_text',
            sourceFileId: fileItem.id,
            text: result.extractedText!,
            extractedDate: DateTime.now(),
            confidence: 0.9, // High confidence from ML Kit
            metadata: {
              'wordCount': result.wordCount,
              'characterCount': result.extractedText!.length,
              'pageCount': result.pageCount,
              'processingMethod': 'ML Kit + Multi-Page Edge Detection',
            },
          );
          _extractedTexts.add(extractedText);
          await _saveExtractedTexts();
        }

        notifyListeners();
        await _saveFiles();
        return fileItem;
      }
      return null;
    } catch (e) {
      print('Error taking enhanced multiple photos: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Capture multiple pages with edge detection and create a single PDF
  Future<FileItem?> takeMultiplePhotosWithEdgeDetection({
    int maxPages = 5,
  }) async {
    try {
      setLoading(true);

      // Use edge detection service to capture multiple pages
      final scannedPagePaths = await EdgeDetectionService.captureMultiplePages(
        maxPages: maxPages,
      );

      if (scannedPagePaths != null && scannedPagePaths.isNotEmpty) {
        // Create a PDF from all scanned pages
        final imageFiles = scannedPagePaths.map((path) => File(path)).toList();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'multi_page_scan_$timestamp.pdf';

        final pdfFile = await PDFGenerationService.generatePDFFromImages(
          imageFiles: imageFiles,
          fileName: fileName,
          title: 'Scanned Document',
        );

        if (pdfFile.existsSync()) {
          // Create FileItem for the PDF and add to list
          final fileItem = await _createFileItemFromPath(pdfFile.path);
          _files.add(fileItem);
          notifyListeners();
          await _saveFiles();

          // Clean up temporary image files
          for (final imagePath in scannedPagePaths) {
            try {
              await File(imagePath).delete();
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting temporary file $imagePath: $e');
              }
            }
          }

          return fileItem;
        }
      }
      return null;
    } catch (e) {
      print('Error taking multiple photos with edge detection: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<FileItem> _createFileItemFromPath(String filePath) async {
    final file = File(filePath);
    final fileStats = await file.stat();
    final fileName = path.basename(file.path);

    // Determine file type based on extension
    final extension = path.extension(fileName).toLowerCase();
    final FileType fileType;
    if (extension == '.pdf') {
      fileType = FileType.pdf;
    } else {
      fileType = FileType.image;
    }

    return FileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: fileName,
      path: file.path,
      type: fileType,
      uploadDate: DateTime.now(),
      size: fileStats.size,
    );
  }

  Future<bool> convertImageToPDF(String fileId) async {
    try {
      final fileIndex = _files.indexWhere((f) => f.id == fileId);
      if (fileIndex == -1) return false;

      final imageFile = _files[fileIndex];
      if (imageFile.type != FileType.image) return false;

      // Convert image to PDF
      final pdfPath = await PDFGenerationService.createPDFFromImage(
        imageFile.path,
      );

      if (pdfPath != null) {
        // Create new PDF FileItem
        final pdfFile = await _createFileItemFromPath(pdfPath);
        _files.add(pdfFile);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error converting image to PDF: $e');
      return false;
    }
  }

  /// Test image enhancement on an existing image file
  Future<FileItem?> testImageEnhancement(String fileId, {
    bool useOpenCV = true,
    bool saveResult = true,
  }) async {
    try {
      setLoading(true);

      // Find the file
      final file = _files.firstWhere((f) => f.id == fileId);
      final originalFile = File(file.path);

      if (!originalFile.existsSync()) {
        if (kDebugMode) {
          print('Original file not found: ${file.path}');
        }
        return null;
      }

      // Test enhancement
      File? enhancedFile;
      if (useOpenCV) {
        enhancedFile = await ImageEnhancementService.enhanceDocumentImage(originalFile);
      } else {
        enhancedFile = await ImageEnhancementService.enhanceImage(originalFile);
      }

      if (enhancedFile != null && saveResult) {
        // Create new file item for the enhanced image
        final fileStats = await enhancedFile.stat();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final enhancedFileItem = FileItem(
          id: '${timestamp}_enhanced',
          name: 'enhanced_${file.name}',
          path: enhancedFile.path,
          type: FileType.image,
          uploadDate: DateTime.now(),
          size: fileStats.size,
        );

        _files.insert(0, enhancedFileItem);
        await _saveFiles();
        notifyListeners();

        if (kDebugMode) {
          print('Enhanced image saved: ${enhancedFile.path}');
        }

        return enhancedFileItem;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing image enhancement: $e');
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Compare OCR results before and after enhancement
  Future<Map<String, dynamic>?> compareOCRResults(String fileId) async {
    try {
      setLoading(true);

      // Find the file
      final file = _files.firstWhere((f) => f.id == fileId);
      final originalFile = File(file.path);

      if (!originalFile.existsSync()) {
        if (kDebugMode) {
          print('Original file not found: ${file.path}');
        }
        return null;
      }

      // Extract text from original image
      final originalText = await TextExtractionService.extractTextFromImage(originalFile);

      // Enhance the image
      final enhancedFile = await ImageEnhancementService.enhanceDocumentImage(originalFile);
      
      if (enhancedFile == null) {
        if (kDebugMode) {
          print('Image enhancement failed');
        }
        return null;
      }

      // Extract text from enhanced image
      final enhancedText = await TextExtractionService.extractTextFromImage(enhancedFile);

      // Compare results
      final originalWordCount = originalText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final enhancedWordCount = enhancedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      final comparison = {
        'originalText': originalText,
        'enhancedText': enhancedText,
        'originalWordCount': originalWordCount,
        'enhancedWordCount': enhancedWordCount,
        'originalLength': originalText.length,
        'enhancedLength': enhancedText.length,
        'improvement': {
          'wordCountDiff': enhancedWordCount - originalWordCount,
          'lengthDiff': enhancedText.length - originalText.length,
          'wordCountImprovement': originalWordCount > 0 ? 
              ((enhancedWordCount - originalWordCount) / originalWordCount * 100).toStringAsFixed(1) + '%' : 
              'N/A',
          'lengthImprovement': originalText.length > 0 ? 
              ((enhancedText.length - originalText.length) / originalText.length * 100).toStringAsFixed(1) + '%' : 
              'N/A',
        },
        'enhancedFilePath': enhancedFile.path,
      };

      if (kDebugMode) {
        print('OCR Comparison Results:');
        print('Original words: $originalWordCount, Enhanced words: $enhancedWordCount');
        print('Original length: ${originalText.length}, Enhanced length: ${enhancedText.length}');
        final improvement = comparison['improvement'] as Map<String, dynamic>?;
        print('Word count improvement: ${improvement?['wordCountImprovement']}');
        print('Text length improvement: ${improvement?['lengthImprovement']}');
      }

      return comparison;
    } catch (e) {
      if (kDebugMode) {
        print('Error comparing OCR results: $e');
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Enhanced document capture with configurable enhancement options
  Future<FileItem?> takeEnhancedDocumentPhotoWithOptions({
    bool extractText = true,
    bool createPDF = true,
    bool enhanceImage = true,
    bool useOpenCVEnhancement = true,
    bool saveIntermediateSteps = false,
  }) async {
    try {
      setLoading(true);

      // Capture with edge detection first
      final scannedImagePath = await EdgeDetectionService.captureWithEdgeDetection();
      
      if (scannedImagePath == null) {
        return null;
      }

      final scannedFile = File(scannedImagePath);
      FileItem? finalFileItem;

      // Save intermediate step if requested
      if (saveIntermediateSteps) {
        final scannedFileItem = await _createFileItemFromPath(scannedImagePath);
        scannedFileItem.name = 'scanned_${scannedFileItem.name}';
        _files.add(scannedFileItem);
      }

      // Enhance image if requested
      File processedFile = scannedFile;
      if (enhanceImage) {
        File? enhanced;
        if (useOpenCVEnhancement) {
          enhanced = await ImageEnhancementService.enhanceDocumentImage(scannedFile);
        } else {
          enhanced = await ImageEnhancementService.enhanceImage(scannedFile);
        }
        
        if (enhanced != null) {
          processedFile = enhanced;
          
          // Save intermediate step if requested
          if (saveIntermediateSteps) {
            final enhancedFileItem = await _createFileItemFromPath(enhanced.path);
            enhancedFileItem.name = 'enhanced_${enhancedFileItem.name}';
            _files.add(enhancedFileItem);
          }
        }
      }

      // Extract text if requested
      String? extractedText;
      if (extractText) {
        try {
          extractedText = await TextExtractionService.extractTextFromImage(processedFile);
          if (kDebugMode) {
            print('Extracted text length: ${extractedText.length} characters');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error extracting text: $e');
          }
        }
      }

      // Create PDF if requested
      if (createPDF) {
        try {
          String? pdfPath;
          if (extractedText != null && extractedText.isNotEmpty) {
            // Create PDF with both image and text
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'enhanced_document_$timestamp.pdf';
            
            final pdfFile = await PDFGenerationService.generateCombinedPDF(
              imageFiles: [processedFile],
              extractedText: extractedText,
              fileName: fileName,
              title: 'Enhanced Scanned Document',
            );
            pdfPath = pdfFile.path;
          } else {
            // Create PDF with just the image
            pdfPath = await PDFGenerationService.createPDFFromImage(processedFile.path);
          }

          if (pdfPath != null) {
            finalFileItem = await _createFileItemFromPath(pdfPath);
            _files.add(finalFileItem);

            // Save extracted text if available
            if (extractedText != null && extractedText.isNotEmpty) {
              final extractedTextObj = ExtractedText(
                id: '${finalFileItem.id}_text',
                sourceFileId: finalFileItem.id,
                text: extractedText,
                extractedDate: DateTime.now(),
                confidence: 0.9,
                metadata: {
                  'wordCount': extractedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
                  'characterCount': extractedText.length,
                  'processingMethod': useOpenCVEnhancement ? 'OpenCV + ML Kit' : 'Standard + ML Kit',
                  'enhancementUsed': enhanceImage,
                },
              );
              _extractedTexts.add(extractedTextObj);
              await _saveExtractedTexts();
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error creating PDF: $e');
          }
          // Fall back to saving just the processed image
          finalFileItem = await _createFileItemFromPath(processedFile.path);
          _files.add(finalFileItem);
        }
      } else {
        // Just save the processed image
        finalFileItem = await _createFileItemFromPath(processedFile.path);
        _files.add(finalFileItem);
      }

      await _saveFiles();
      notifyListeners();
      return finalFileItem;
    } catch (e) {
      if (kDebugMode) {
        print('Error in enhanced document capture with options: $e');
      }
      return null;
    } finally {
      setLoading(false);
    }
  }
}
