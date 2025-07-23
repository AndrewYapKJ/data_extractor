import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/file_controller.dart';
import '../models/file_item_model.dart';

class FilesView extends StatelessWidget {
  const FilesView({super.key});

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
                final fileController = Provider.of<FileController>(context, listen: false);
                final success = await fileController.deleteFile(file.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'File deleted successfully!' : 'Failed to delete file'),
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
          content: const Text('Are you sure you want to delete all files? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final fileController = Provider.of<FileController>(context, listen: false);
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen(file: file),
      ),
    );
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (fileController.files.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No files yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Take a photo or upload files to get started',
                    style: TextStyle(
                      fontSize: 14,
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
              padding: const EdgeInsets.all(16),
              itemCount: fileController.files.length,
              itemBuilder: (context, index) {
                final file = fileController.files[index];
                return _FileCard(
                  file: file,
                  onTap: () => _showFilePreview(context, file),
                  onDelete: () => _showDeleteDialog(context, file),
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

  const _FileCard({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: file.type == FileType.image 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  file.type == FileType.image 
                      ? Icons.image
                      : Icons.picture_as_pdf,
                  color: file.type == FileType.image 
                      ? Colors.blue
                      : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.formattedSize} • ${_formatDate(file.uploadDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: onDelete,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: file.type == FileType.image
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
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'PDF Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'PDF preview not available.\nFile is stored in cache.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}
