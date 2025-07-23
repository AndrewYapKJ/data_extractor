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

class FileController extends ChangeNotifier {
  List<FileItem> _files = [];
  bool _isLoading = false;

  List<FileItem> get files => _files;
  bool get isLoading => _isLoading;

  final ImagePicker _imagePicker = ImagePicker();

  FileController() {
    _loadSavedFiles();
  }

  Future<void> _loadSavedFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList('saved_files') ?? [];
      
      _files = filesJson
          .map((jsonStr) => FileItem.fromJson(json.decode(jsonStr)))
          .where((file) => File(file.path).existsSync()) // Only include existing files
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
      final filesJson = _files.map((file) => json.encode(file.toJson())).toList();
      await prefs.setStringList('saved_files', filesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving files: $e');
      }
    }
  }

  Future<String> _getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(directory.path, 'pdf_extractor_cache'));
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
      file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
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
        await _saveFiles();
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

  Future<void> clearAllFiles() async {
    try {
      // Delete all physical files
      for (final file in _files) {
        if (await File(file.path).exists()) {
          await File(file.path).delete();
        }
      }
      
      _files.clear();
      await _saveFiles();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing files: $e');
      }
    }
  }
}
