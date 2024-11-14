import 'package:flutter/material.dart';
import 'package:virtualine/search_directory.dart';

class RightAnimation extends StatefulWidget {
  const RightAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightAnimationState createState() => _RightAnimationState();
}

class _RightAnimationState extends State<RightAnimation> {
  // Controllers
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _animationNameController = TextEditingController();
  final TextEditingController _frameDelayController = TextEditingController();

  // État
  late Future<List<List<dynamic>>?> _directoryList;
  final List<String> _directoryStack = [];
  bool _isFileExplorerExpanded = true;
  bool _isAnimationSettingsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    const initialPath = '/assets/dessin';
    _customPathController.text = initialPath;
    _directoryStack.add(initialPath);
    _directoryList = _loadDirectory();
    
    // Initialize animation controllers with default values
    _frameDelayController.text = "100"; // Default frame delay in milliseconds
  }

  Future<List<List<dynamic>>?> _loadDirectory() {
    return loadPathDirectory(_customPathController, _listDirectories);
  }

  Future<Node> _listDirectories(String pathString) async {
    return listDirectoriesRecursive(pathString);
  }

  void _navigateBack() {
    if (_directoryStack.length > 1) {
      setState(() {
        _directoryStack.removeLast();
        _customPathController.text = _directoryStack.last;
        _directoryList = _loadDirectory();
      });
    }
  }

  Widget _buildFileExplorer() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isFileExplorerExpanded,
        onExpansionChanged: (value) => setState(() => _isFileExplorerExpanded = value),
        leading: const Icon(Icons.folder, color: Colors.purple),
        title: const Text(
          'Explorateur de fichiers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          SizedBox(
            height: 250,
            child: FutureBuilder<List<List<dynamic>>?>(
              future: _directoryList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purple));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('Aucun fichier trouvé',
                        style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildNavigationTile();
                    }
                    return _buildDirectoryItem(snapshot.data![index - 1]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile() {
    return ListTile(
      leading: const Icon(Icons.arrow_upward, color: Colors.purple),
      title: const Text('...', style: TextStyle(color: Colors.white70)),
      onTap: _navigateBack,
      enabled: _directoryStack.length > 1,
    );
  }

  Widget _buildDirectoryItem(List<dynamic> item) {
    final isDirectory = item[1] == 2;
    final icon = isDirectory ? Icons.folder : _getFileIcon(item[0].toString());
    
    return isDirectory
        ? _buildDirectoryTile(item, icon)
        : _buildFileTile(item, icon);
  }

  Widget _buildDirectoryTile(List<dynamic> item, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple.shade300),
      title: Text(
        item[0].toString(),
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        setState(() {
          _customPathController.text += '/${item[0]}';
          _directoryStack.add(_customPathController.text);
          _directoryList = _loadDirectory();
        });
      },
    );
  }

  Widget _buildFileTile(List<dynamic> item, IconData icon) {
    return Draggable(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Icon(icon, color: Colors.purple, size: 40),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple.shade300),
        title: Text(
          item[0].toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.png') || fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildAnimationSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isAnimationSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isAnimationSettingsExpanded = value),
        leading: const Icon(Icons.settings, color: Colors.purple),
        title: const Text(
          'Paramètres de l\'animation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(
                  controller: _animationNameController,
                  label: 'Nom de l\'animation',
                  icon: Icons.label,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _frameDelayController,
                  label: 'Délai entre les images (ms)',
                  isNumeric: true,
                  icon: Icons.timer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumeric = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.purple) : null,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.purple),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildFileExplorer(),
            _buildAnimationSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customPathController.dispose();
    _animationNameController.dispose();
    _frameDelayController.dispose();
    super.dispose();
  }
}