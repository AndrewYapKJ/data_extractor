import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/file_controller.dart';
import '../models/file_item_model.dart';
import '../widgets/pdf_viewer_screen.dart';
import 'files_view.dart';
import 'text_extraction_view.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const FilesView(),
    const TextExtractionView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Text'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                final authController = Provider.of<AuthController>(
                  context,
                  listen: false,
                );
                await authController.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final success = await fileController.takePhoto();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Photo captured successfully!'
                : 'Failed to capture photo',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhotoWithEdgeDetection(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final result = await fileController.takePhotoWithEdgeDetection();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? 'Smart document captured successfully!'
                : 'Failed to capture document',
          ),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _takeMultiplePhotosWithEdgeDetection(
    BuildContext context,
  ) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final result = await fileController.takeMultiplePhotosWithEdgeDetection(
      maxPages: 5,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? 'Multi-page document scanned and PDF created successfully!'
                : 'Failed to scan multi-page document',
          ),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _takeEnhancedDocumentPhoto(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final result = await fileController.takeEnhancedDocumentPhoto(
      extractText: true,
      createPDF: true,
      enhanceImage: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? 'Enhanced document captured with OCR and PDF created!'
                : 'Failed to capture enhanced document',
          ),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _takeEnhancedMultiplePhotos(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final result = await fileController.takeEnhancedMultiplePhotos(
      maxPages: 5,
      extractText: true,
      enhanceImages: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? 'Enhanced multi-page document captured with OCR and PDF created!'
                : 'Failed to capture enhanced multi-page document',
          ),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPhoto(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final success = await fileController.uploadPhoto();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Photo uploaded successfully!' : 'Failed to upload photo',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPDF(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    final success = await fileController.uploadPDF();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'PDF uploaded successfully!' : 'Failed to upload PDF',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _navigateToTextExtraction(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TextExtractionView()));
  }

  void _openPDFViewer(BuildContext context) {
    final fileController = Provider.of<FileController>(context, listen: false);
    final pdfFiles =
        fileController.files
            .where((file) => file.type == FileType.pdf)
            .toList();

    if (pdfFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF files found. Create or upload a PDF first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (pdfFiles.length == 1) {
      // Directly open the only PDF
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => PDFViewerScreen(
                pdfPath: pdfFiles.first.path,
                title: pdfFiles.first.name,
              ),
        ),
      );
    } else {
      // Show dialog to select which PDF to open
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Select PDF to View'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = pdfFiles[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      title: Text(file.name),
                      subtitle: Text(file.formattedSize),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => PDFViewerScreen(
                                  pdfPath: file.path,
                                  title: file.name,
                                ),
                          ),
                        );
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
            ),
      );
    }
  }

  Future<void> _showEnhancementDebugDialog(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    
    if (fileController.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No files available for testing. Capture an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to select file for enhancement testing
    final imageFiles = fileController.files.where((f) => f.type == FileType.image).toList();
    
    if (imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image files available for testing. Capture an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Image Enhancement'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const Text('Select an image to test enhancement:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    final file = imageFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.image, color: Colors.blue),
                      title: Text(file.name),
                      subtitle: Text(file.formattedSize),
                      onTap: () async {
                        Navigator.of(context).pop();
                        
                        // Show options for enhancement
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Enhancement Options'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('OpenCV Enhancement'),
                                  subtitle: const Text('Advanced document processing'),
                                  leading: const Icon(Icons.auto_fix_high, color: Colors.green),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _testImageEnhancement(context, file.id, true);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Standard Enhancement'),
                                  subtitle: const Text('Basic image processing'),
                                  leading: const Icon(Icons.tune, color: Colors.blue),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _testImageEnhancement(context, file.id, false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

  Future<void> _testImageEnhancement(BuildContext context, String fileId, bool useOpenCV) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing ${useOpenCV ? 'OpenCV' : 'standard'} enhancement...'),
        backgroundColor: Colors.blue,
      ),
    );

    final result = await fileController.testImageEnhancement(
      fileId,
      useOpenCV: useOpenCV,
      saveResult: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? 'Enhancement successful! Enhanced image saved to files.'
                : 'Enhancement failed. Check debug console for details.',
          ),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showOCRComparisonDialog(BuildContext context) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    
    if (fileController.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No files available for comparison. Capture an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to select file for OCR comparison
    final imageFiles = fileController.files.where((f) => f.type == FileType.image).toList();
    
    if (imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image files available for comparison. Capture an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compare OCR Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const Text('Select an image to compare OCR before/after enhancement:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    final file = imageFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.image, color: Colors.blue),
                      title: Text(file.name),
                      subtitle: Text(file.formattedSize),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _performOCRComparison(context, file.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

  Future<void> _performOCRComparison(BuildContext context, String fileId) async {
    final fileController = Provider.of<FileController>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comparing OCR results... This may take a moment.'),
        backgroundColor: Colors.blue,
      ),
    );

    final comparison = await fileController.compareOCRResults(fileId);

    if (context.mounted) {
      if (comparison != null) {
        _showOCRComparisonResults(context, comparison);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR comparison failed. Check debug console for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOCRComparisonResults(BuildContext context, Map<String, dynamic> comparison) {
    final improvement = comparison['improvement'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Comparison Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Original words: ${comparison['originalWordCount']}'),
                        Text('Enhanced words: ${comparison['enhancedWordCount']}'),
                        Text('Word count improvement: ${improvement['wordCountImprovement']}'),
                        const SizedBox(height: 8),
                        Text('Original text length: ${comparison['originalLength']}'),
                        Text('Enhanced text length: ${comparison['enhancedLength']}'),
                        Text('Length improvement: ${improvement['lengthImprovement']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Text',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              comparison['originalText'] as String? ?? 'No text found',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enhanced Text',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              comparison['enhancedText'] as String? ?? 'No text found',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Extractor Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthController>(
            builder: (context, authController, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'user',
                        enabled: false,
                        child: Text(
                          'Welcome, ${authController.currentUser?.username ?? 'User'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ActionCard(
                    icon: Icons.auto_awesome,
                    title: 'Smart Scan + OCR',
                    subtitle: 'Edge detection, OCR & PDF',
                    color: Colors.indigo,
                    onTap: () => _takeEnhancedDocumentPhoto(context),
                  ),
                  _ActionCard(
                    icon: Icons.library_books,
                    title: 'Multi-Page OCR',
                    subtitle: 'Multiple pages with OCR',
                    color: Colors.deepPurple,
                    onTap: () => _takeEnhancedMultiplePhotos(context),
                  ),
                  _ActionCard(
                    icon: Icons.document_scanner,
                    title: 'Smart Capture',
                    subtitle: 'Auto edge detection',
                    color: Colors.teal,
                    onTap: () => _takePhotoWithEdgeDetection(context),
                  ),
                  _ActionCard(
                    icon: Icons.scanner,
                    title: 'Multi-Page Scan',
                    subtitle: 'Create PDF from multiple pages',
                    color: Colors.deepOrange,
                    onTap: () => _takeMultiplePhotosWithEdgeDetection(context),
                  ),
                  _ActionCard(
                    icon: Icons.camera_alt,
                    title: 'Take Photo',
                    subtitle: 'Capture with camera',
                    color: Colors.green,
                    onTap: () => _takePhoto(context),
                  ),
                  _ActionCard(
                    icon: Icons.photo_library,
                    title: 'Upload Photo',
                    subtitle: 'Select from gallery',
                    color: Colors.blue,
                    onTap: () => _uploadPhoto(context),
                  ),
                  _ActionCard(
                    icon: Icons.picture_as_pdf,
                    title: 'Upload PDF',
                    subtitle: 'Select PDF file',
                    color: Colors.red,
                    onTap: () => _uploadPDF(context),
                  ),
                  _ActionCard(
                    icon: Icons.preview,
                    title: 'View PDFs',
                    subtitle: 'Preview PDF files',
                    color: Colors.indigo,
                    onTap: () => _openPDFViewer(context),
                  ),
                  _ActionCard(
                    icon: Icons.text_fields,
                    title: 'Extract Text',
                    subtitle: 'OCR from images',
                    color: Colors.purple,
                    onTap: () => _navigateToTextExtraction(context),
                  ),
                  Consumer<FileController>(
                    builder: (context, fileController, child) {
                      return _ActionCard(
                        icon: Icons.folder,
                        title: 'View Files',
                        subtitle: '${fileController.files.length} files',
                        color: Colors.orange,
                        onTap: () {
                          // Navigate to files page
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FilesView(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Consumer<FileController>(
                    builder: (context, fileController, child) {
                      return _ActionCard(
                        icon: Icons.insights,
                        title: 'Extracted Text',
                        subtitle:
                            '${fileController.extractedTexts.length} items',
                        color: Colors.teal,
                        onTap: () => _navigateToTextExtraction(context),
                      );
                    },
                  ),
                  // Debug and Testing Cards
                  if (kDebugMode) ...[
                    _ActionCard(
                      icon: Icons.auto_fix_high,
                      title: 'Test Enhancement',
                      subtitle: 'Test image enhancement',
                      color: Colors.amber,
                      onTap: () => _showEnhancementDebugDialog(context),
                    ),
                    _ActionCard(
                      icon: Icons.compare,
                      title: 'Compare OCR',
                      subtitle: 'Before/after enhancement',
                      color: Colors.cyan,
                      onTap: () => _showOCRComparisonDialog(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
