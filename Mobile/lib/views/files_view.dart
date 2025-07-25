import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/file_controller.dart';
import '../models/file_item_model.dart';
import '../utils/screen_utils.dart';
import '../widgets/pdf_viewer_screen.dart';

class FilesView extends StatelessWidget {
  const FilesView({super.key});
  static Future<void> convertToPDF(BuildContext context, FileItem file) async {
    try {
      final fileController = Provider.of<FileController>(
        context,
        listen: false,
      );
      final success = await fileController.convertImageToPDF(file.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Image converted to PDF successfully!'
                  : 'Failed to convert image to PDF',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting to PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, FileItem file) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: Text('Are you sure you want to delete "${file.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final fileController = Provider.of<FileController>(
                  context,
                  listen: false,
                );
                final success = await fileController.deleteFile(file.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'File deleted successfully!'
                            : 'Failed to delete file',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Files'),
          content: const Text(
            'Are you sure you want to delete all files? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final fileController = Provider.of<FileController>(
                  context,
                  listen: false,
                );
                await fileController.clearAllFiles();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All files cleared successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilePreview(BuildContext context, FileItem file) {
    if (file.type == FileType.pdf) {
      // Navigate to PDF viewer screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) =>
                  PDFViewerScreen(pdfPath: file.path, title: file.name),
        ),
      );
    } else {
      // Navigate to regular file preview screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => FilePreviewScreen(file: file)),
      );
    }
  }

  Future<void> _shareFile(BuildContext context, FileItem file) async {
    try {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Shared from PDF Extractor Scanner');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extractTextFromFile(BuildContext context, FileItem file) async {
    if (file.type != FileType.image) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text extraction is only available for images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final fileController = Provider.of<FileController>(
        context,
        listen: false,
      );
      final extractedText = await fileController.extractTextFromFile(file.id);

      if (context.mounted) {
        if (extractedText != null && extractedText.hasText) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Text extracted successfully! Found ${extractedText.wordCount}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text found in the image'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<FileController>(
            builder: (context, fileController, child) {
              if (fileController.files.isEmpty) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearAllDialog(context),
                tooltip: 'Clear all files',
              );
            },
          ),
        ],
      ),
      body: Consumer<FileController>(
        builder: (context, fileController, child) {
          if (fileController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (fileController.files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: AppSizes.extraLargeIcon * 1.67,
                    color: Colors.grey,
                  ),
                  SizedBox(height: AppSizes.md),
                  Text(
                    'No files yet',
                    style: TextStyle(
                      fontSize: AppSizes.subtitle,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    'Take a photo or upload files to get started',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled automatically by the provider
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: EdgeInsets.all(AppSizes.md),
              itemCount: fileController.files.length,
              itemBuilder: (context, index) {
                final file = fileController.files[index];
                return _FileCard(
                  file: file,
                  onTap: () => _showFilePreview(context, file),
                  onDelete: () => _showDeleteDialog(context, file),
                  onShare: () => _shareFile(context, file),
                  onExtractText: () => _extractTextFromFile(context, file),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onExtractText;

  const _FileCard({
    required this.file,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
    required this.onExtractText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.xs * 3),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.largeRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.largeRadius),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // File icon
              Container(
                padding: EdgeInsets.all(AppSizes.xs * 3),
                decoration: BoxDecoration(
                  color:
                      file.type == FileType.image
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Icon(
                  file.type == FileType.image
                      ? Icons.image
                      : Icons.picture_as_pdf,
                  color: file.type == FileType.image ? Colors.blue : Colors.red,
                  size: AppSizes.icon,
                ),
              ),
              SizedBox(width: AppSizes.md),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        fontSize: AppSizes.bodyText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      '${file.formattedSize} • ${_formatDate(file.uploadDate)}',
                      style: TextStyle(
                        fontSize: AppSizes.captionText,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (file.type == FileType.image)
                    IconButton(
                      icon: const Icon(Icons.text_fields),
                      color: Colors.purple,
                      onPressed: onExtractText,
                      tooltip: 'Extract text',
                    ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    color: Colors.blue,
                    onPressed: onShare,
                    tooltip: 'Share file',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: onDelete,
                    tooltip: 'Delete file',
                  ),
                  if (file.type == FileType.image)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      color: Colors.green,
                      onPressed: () => FilesView.convertToPDF(context, file),
                      tooltip: 'Convert to PDF',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class FilePreviewScreen extends StatelessWidget {
  final FileItem file;

  const FilePreviewScreen({super.key, required this.file});

  Future<void> _shareFile() async {
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Shared from PDF Extractor Scanner');
  }

  Future<void> _extractText(BuildContext context) async {
    if (file.type != FileType.image) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text extraction is only available for images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final fileController = Provider.of<FileController>(
        context,
        listen: false,
      );
      final extractedText = await fileController.extractTextFromFile(file.id);

      if (context.mounted) {
        if (extractedText != null && extractedText.hasText) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Text extracted successfully! Found ${extractedText.wordCount}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text found in the image'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
            tooltip: 'Share file',
          ),
          if (file.type == FileType.image)
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => _extractText(context),
              tooltip: 'Extract text',
            ),
          if (file.type == FileType.image)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => FilesView.convertToPDF(context, file),
              tooltip: 'Convert to PDF',
            ),
        ],
      ),
      body: Center(
        child:
            file.type == FileType.image
                ? InteractiveViewer(
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text('Error loading image'),
                        ],
                      );
                    },
                  ),
                )
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'File Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Preview not available for this file type.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
      ),
    );
  }
}
