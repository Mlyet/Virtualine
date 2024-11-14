import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:virtualine/search_directory.dart';
import 'package:file_picker/file_picker.dart';
import 'package:virtualine/set_stats.dart';

class RightSound extends StatefulWidget {
  const RightSound({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightSoundState createState() => _RightSoundState();
}

class _RightSoundState extends State<RightSound> {
  // Controllers
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();

  // État
  late Future<List<List<dynamic>>?> _directoryList;
  final List<String> _directoryStack = [];
  bool _isFileExplorerExpanded = true;
  bool _isSoundSettingsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    const initialPath = '/assets/sons';
    _customPathController.text = initialPath;
    _directoryStack.add(initialPath);
    _directoryList = _loadDirectory();
    loadProjectName(_projectNameController);
    loadPathProject(_pathController, __listDirectories);
  }

  void __listDirectories(String pathString) {}

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

  Future<void> _pickAndImportMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String dir = '${_pathController.text}/${_projectNameController.text}/assets/sons';
      final String filePath = result.files.single.path!;
      final File originalFile = File(filePath);
      final String fileName = basename(filePath);
      final String newPath = '$dir/$fileName';
      await originalFile.copy(newPath);

      setState(() {
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
        leading: const Icon(Icons.library_music, color: Colors.purple),
        title: const Text(
          'Explorateur de sons',
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
    final icon = isDirectory ? Icons.folder : Icons.audiotrack;
    
    return isDirectory
        ? _buildDirectoryTile(item, icon)
        : _buildSoundTile(item, icon);
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

  Widget _buildSoundTile(List<dynamic> item, IconData icon) {
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
        onTap: () => selectedSound(item[0]),
      ),
    );
  }

  void selectedSound(String sound) {
    projectPathSound.value = sound;
  }

  Widget _buildSoundSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isSoundSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isSoundSettingsExpanded = value),
        leading: const Icon(Icons.settings, color: Colors.purple),
        title: const Text(
          'Paramètres audio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndImportMusic,
                  icon: const Icon(Icons.add, color: Colors.purple),
                  label: const Text('Importer une musique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            _buildSoundSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customPathController.dispose();
    _pathController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }
}