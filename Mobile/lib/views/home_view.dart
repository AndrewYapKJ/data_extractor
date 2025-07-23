import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/file_controller.dart';
import 'files_view.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Files',
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
                final authController = Provider.of<AuthController>(context, listen: false);
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
          content: Text(success ? 'Photo captured successfully!' : 'Failed to capture photo'),
          backgroundColor: success ? Colors.green : Colors.red,
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
          content: Text(success ? 'Photo uploaded successfully!' : 'Failed to upload photo'),
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
          content: Text(success ? 'PDF uploaded successfully!' : 'Failed to upload PDF'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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
                itemBuilder: (BuildContext context) => [
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
