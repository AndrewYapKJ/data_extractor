import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class PDFGenerationService {
  /// Generate PDF from extracted text
  static Future<File> generatePDFFromText({
    required String text,
    required String fileName,
    String? title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            if (title != null) ...[
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Paragraph(
              text: text,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
            ),
          ];
        },
      ),
    );

    return _savePDF(pdf, fileName);
  }

  /// Generate PDF from multiple images
  static Future<File> generatePDFFromImages({
    required List<File> imageFiles,
    required String fileName,
    String? title,
  }) async {
    final pdf = pw.Document();

    for (int i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      
      try {
        final imageBytes = await imageFile.readAsBytes();
        final image = img.decodeImage(imageBytes);
        
        if (image != null) {
          // Resize image if too large
          final resizedImage = _resizeImage(image, 800, 1000);
          final resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (title != null && i == 0) ...[
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                    ],
                    pw.Text(
                      'Page ${i + 1} of ${imageFiles.length}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(resizedBytes),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing image ${i + 1}: $e');
        }
      }
    }

    return _savePDF(pdf, fileName);
  }

  /// Generate PDF combining images and extracted text
  static Future<File> generateCombinedPDF({
    required List<File> imageFiles,
    required String extractedText,
    required String fileName,
    String? title,
  }) async {
    final pdf = pw.Document();

    // Add title page with extracted text
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            if (title != null) ...[
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Text(
              'Extracted Text',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Paragraph(
              text: extractedText.isNotEmpty ? extractedText : 'No text extracted',
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Source Images',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ];
        },
      ),
    );

    // Add images
    for (int i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      
      try {
        final imageBytes = await imageFile.readAsBytes();
        final image = img.decodeImage(imageBytes);
        
        if (image != null) {
          final resizedImage = _resizeImage(image, 800, 1000);
          final resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Image ${i + 1} of ${imageFiles.length}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(resizedBytes),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing image ${i + 1}: $e');
        }
      }
    }

    return _savePDF(pdf, fileName);
  }

  /// Save PDF to file
  static Future<File> _savePDF(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'generated_pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final finalFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    final filePath = path.join(pdfDir.path, '${timestamp}_$finalFileName');
    
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Resize image to fit within max dimensions while maintaining aspect ratio
  static img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
    int width = image.width;
    int height = image.height;
    
    if (width <= maxWidth && height <= maxHeight) {
      return image;
    }
    
    double widthRatio = maxWidth / width;
    double heightRatio = maxHeight / height;
    double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
    
    int newWidth = (width * ratio).round();
    int newHeight = (height * ratio).round();
    
    return img.copyResize(image, width: newWidth, height: newHeight);
  }
}
