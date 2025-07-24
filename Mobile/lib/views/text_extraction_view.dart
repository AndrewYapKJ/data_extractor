import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/file_controller.dart';
import '../models/extracted_text_model.dart';
import '../models/file_item_model.dart';

class TextExtractionView extends StatefulWidget {
  const TextExtractionView({super.key});

  @override
  State<TextExtractionView> createState() => _TextExtractionViewState();
}

class _TextExtractionViewState extends State<TextExtractionView> {
  String _searchQuery = '';

  List<ExtractedText> _getFilteredTexts(List<ExtractedText> texts) {
    if (_searchQuery.isEmpty) return texts;

    return texts
        .where(
          (text) =>
              text.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              text.metadata?['sourceFileName']?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ==
                  true,
        )
        .toList();
  }

  Future<void> _extractTextFromFile(BuildContext context, String fileId) async {
    try {
      final fileController = Provider.of<FileController>(
        context,
        listen: false,
      );
      final extractedText = await fileController.extractTextFromFile(fileId);

      if (context.mounted) {
        if (extractedText != null && extractedText.hasText) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Text extracted successfully! Found ${extractedText.wordCount}',
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => _showTextDetails(context, extractedText),
              ),
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

  Future<void> _showImageSelectionDialog(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final imageFiles =
        fileController.files.where((f) => f.type == FileType.image).toList();

    if (imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images available for text extraction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image for Text Extraction'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                final file = imageFiles[index];
                return ListTile(
                  leading: const Icon(Icons.image, color: Colors.blue),
                  title: Text(file.name),
                  subtitle: Text(
                    '${file.formattedSize} • ${_formatDate(file.uploadDate)}',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _extractTextFromFile(context, file.id);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showTextDetails(BuildContext context, ExtractedText extractedText) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextDetailsScreen(extractedText: extractedText),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ExtractedText text,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Extracted Text'),
          content: const Text(
            'Are you sure you want to delete this extracted text?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final fileController = Provider.of<FileController>(
                  context,
                  listen: false,
                );
                final success = await fileController.deleteExtractedText(
                  text.id,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Text deleted successfully!'
                            : 'Failed to delete text',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Extraction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<FileController>(
            builder: (context, fileController, child) {
              if (fileController.extractedTexts.isEmpty)
                return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: TextSearchDelegate(fileController.extractedTexts),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<FileController>(
        builder: (context, fileController, child) {
          if (fileController.isExtracting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting text from image...'),
                ],
              ),
            );
          }

          final filteredTexts = _getFilteredTexts(
            fileController.extractedTexts,
          );

          if (filteredTexts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.text_fields, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No extracted text yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Extract text from your images to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showImageSelectionDialog(context),
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Extract Text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTexts.length,
              itemBuilder: (context, index) {
                final extractedText = filteredTexts[index];
                return _ExtractedTextCard(
                  extractedText: extractedText,
                  onTap: () => _showTextDetails(context, extractedText),
                  onDelete: () => _showDeleteDialog(context, extractedText),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImageSelectionDialog(context),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.text_fields),
      ),
    );
  }
}

class _ExtractedTextCard extends StatelessWidget {
  final ExtractedText extractedText;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExtractedTextCard({
    required this.extractedText,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extractedText.metadata?['sourceFileName'] ??
                              'Unknown source',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${extractedText.wordCount} • ${extractedText.formattedDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  extractedText.text.length > 150
                      ? '${extractedText.text.substring(0, 150)}...'
                      : extractedText.text,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextDetailsScreen extends StatelessWidget {
  final ExtractedText extractedText;

  const TextDetailsScreen({super.key, required this.extractedText});

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: extractedText.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareText() async {
    await Share.share(
      extractedText.text,
      subject:
          'Extracted Text from ${extractedText.metadata?['sourceFileName'] ?? 'Image'}',
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    try {
      final fileController = Provider.of<FileController>(
        context,
        listen: false,
      );
      final fileName =
          extractedText.metadata?['sourceFileName']?.replaceAll(
            RegExp(r'\.[^.]*$'),
            '',
          ) ??
          'extracted_text';

      await fileController.generatePDFFromText(
        extractedText.id,
        title: 'Extracted Text - $fileName',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
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
        title: const Text('Extracted Text'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copy to clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareText,
            tooltip: 'Share text',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') {
                _generatePDF(context);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf),
                        SizedBox(width: 8),
                        Text('Generate PDF'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      'Source',
                      extractedText.metadata?['sourceFileName'] ?? 'Unknown',
                    ),
                    _InfoRow('Extracted', extractedText.formattedDate),
                    _InfoRow('Word Count', extractedText.wordCount),
                    _InfoRow('Character Count', extractedText.characterCount),
                    if (extractedText.confidence > 0)
                      _InfoRow(
                        'Confidence',
                        '${(extractedText.confidence * 100).toStringAsFixed(1)}%',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text content card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        extractedText.text.isNotEmpty
                            ? extractedText.text
                            : 'No text extracted',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class TextSearchDelegate extends SearchDelegate<String> {
  final List<ExtractedText> extractedTexts;

  TextSearchDelegate(this.extractedTexts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredTexts =
        extractedTexts
            .where(
              (text) =>
                  text.text.toLowerCase().contains(query.toLowerCase()) ||
                  text.metadata?['sourceFileName']?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ==
                      true,
            )
            .toList();

    if (filteredTexts.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      itemCount: filteredTexts.length,
      itemBuilder: (context, index) {
        final text = filteredTexts[index];
        return ListTile(
          title: Text(
            text.metadata?['sourceFileName'] ?? 'Unknown source',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            text.text.length > 100
                ? '${text.text.substring(0, 100)}...'
                : text.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, text.id);
          },
        );
      },
    );
  }
}
