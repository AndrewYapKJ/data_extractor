import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_preview_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String? title;

  const PDFViewerScreen({super.key, required this.pdfPath, this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFViewController? _pdfViewController;
  PDFInfo? _pdfInfo;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPDFInfo();
  }

  Future<void> _loadPDFInfo() async {
    try {
      final pdfInfo = await PDFPreviewService.getPDFInfo(widget.pdfPath);
      setState(() {
        _pdfInfo = pdfInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading PDF: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePDF() async {
    try {
      await Share.shareXFiles([
        XFile(widget.pdfPath),
      ], text: 'Shared PDF from PDF Extractor Scanner');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToPage(int page) {
    _pdfViewController?.setPage(page);
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Go to Page'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total pages: $_totalPages'),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Page number',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    final page = int.tryParse(value);
                    if (page != null && page >= 1 && page <= _totalPages) {
                      _goToPage(page - 1);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a page number between 1 and $_totalPages',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? _pdfInfo?.fileName ?? 'PDF Viewer'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_totalPages > 1)
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: _showPageNavigator,
              tooltip: 'Go to page',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPDFInfo(),
            tooltip: 'PDF Info',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _totalPages > 1 ? _buildPageNavigationBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return PDFView(
      filePath: widget.pdfPath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'PDF rendering error: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          _errorMessage = 'Page $page error: $error';
        });
      },
      onViewCreated: (PDFViewController pdfViewController) {
        _pdfViewController = pdfViewController;
      },
      onLinkHandler: (String? uri) {
        // Handle link clicks if needed
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
    );
  }

  Widget _buildPageNavigationBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
            tooltip: 'First page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            tooltip: 'Previous page',
          ),
          GestureDetector(
            onTap: _showPageNavigator,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentPage < _totalPages - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
            tooltip: 'Next page',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed:
                _currentPage < _totalPages - 1
                    ? () => _goToPage(_totalPages - 1)
                    : null,
            tooltip: 'Last page',
          ),
        ],
      ),
    );
  }

  void _showPDFInfo() {
    if (_pdfInfo == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('PDF Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('File Name', _pdfInfo!.fileName),
                _buildInfoRow('File Size', _pdfInfo!.fileSize),
                _buildInfoRow('Pages', '${_pdfInfo!.pageCount}'),
                _buildInfoRow(
                  'Last Modified',
                  _formatDate(_pdfInfo!.lastModified),
                ),
                _buildInfoRow(
                  'Current Page',
                  '${_currentPage + 1} of $_totalPages',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
