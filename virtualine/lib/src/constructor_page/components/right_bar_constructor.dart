import 'package:flutter/material.dart';
import 'package:virtualine/search_directory.dart';
import 'package:file_picker/file_picker.dart';
import 'package:virtualine/set_object.dart';

class RightConstructor extends StatefulWidget {
  const RightConstructor({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RightConstructorState createState() => _RightConstructorState();
}

class _RightConstructorState extends State<RightConstructor> {
  // Controllers
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerXController = TextEditingController();
  final TextEditingController _playerYController = TextEditingController();
  final TextEditingController _playerSpeedController = TextEditingController();
  final TextEditingController _playerGravityController =
      TextEditingController();

  // État
  late Future<List<List<dynamic>>?> _directoryList;
  final List<String> _directoryStack = [];
  bool _isFileExplorerExpanded = true;
  bool _isPlayerSettingsExpanded = true;

@override
void initState() {
  super.initState();
  _initializeControllers();
  
  playerState.addListener(() {
    if (mounted) {
      setState(() {
        _playerXController.text = playerState.value.x.toStringAsFixed(2);
        _playerYController.text = playerState.value.y.toStringAsFixed(2);
      });
    }
  });
}

  void _initializeControllers() {
    const initialPath = '/assets/dessin';
    _customPathController.text = initialPath;
    _directoryStack.add(initialPath);
    _directoryList = _loadDirectory();

    // Initialize player controllers with current values
    _updatePlayerControllers();
  }

  void _updatePlayerControllers() {
    _playerXController.text = playerState.value.x.toStringAsFixed(2);
    _playerYController.text = playerState.value.y.toStringAsFixed(2);
    _playerSpeedController.text = playerState.value.speed.toString();
    _playerGravityController.text = playerState.value.gravity.toString();
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

  Future<void> _selectPlayerImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        _playerNameController.text = file.name;
        playerState.value = PlayerObject(
          path: file.path!,
          x: playerState.value.x,
          y: playerState.value.y,
          speed: playerState.value.speed,
          gravity: playerState.value.gravity,
        );
        savePlayer(playerState.value);
      });
    }
  }

  Widget _buildFileExplorer() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isFileExplorerExpanded,
        onExpansionChanged: (value) =>
            setState(() => _isFileExplorerExpanded = value),
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
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.purple));
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
    if (fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildPlayerSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isPlayerSettingsExpanded,
        onExpansionChanged: (value) =>
            setState(() => _isPlayerSettingsExpanded = value),
        leading: const Icon(Icons.sports_esports, color: Colors.purple),
        title: const Text(
          'Paramètres du joueur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(
                  controller: _playerNameController,
                  label: 'Sprite du joueur',
                  onTap: _selectPlayerImage,
                  icon: Icons.image,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _playerXController,
                        label: 'Position X',
                        isNumeric: true,
                        onChanged: (value) {
                          _updatePlayerPosition('x', value);
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTextField(
                        controller: _playerYController,
                        label: 'Position Y',
                        isNumeric: true,
                        onChanged: (value) {
                          _updatePlayerPosition('y', value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _playerSpeedController,
                  label: 'Vitesse',
                  isNumeric: true,
                  onChanged: (value) {
                    playerState.value.speed =
                        value.isEmpty ? 0.0 : double.parse(value);
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _playerGravityController,
                  label: 'Gravité',
                  isNumeric: true,
                  onChanged: (value) {
                    playerState.value.gravity =
                        value.isEmpty ? 0.0 : double.parse(value);
                  },
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
    VoidCallback? onTap,
    void Function(String)? onChanged,
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
      onTap: onTap,
      onChanged: onChanged,
    );
  }

  void _updatePlayerPosition(String axis, String value) {
    if (value.isEmpty) return;

    try {
      final doubleValue = double.parse(value);

      setState(() {
        if (axis == 'x') {
          playerState.value.x = doubleValue;
        } else {
          playerState.value.y = doubleValue;
        }

        savePlayer(playerState.value);
      });
    } catch (e) {
      debugPrint('Erreur de conversion: $e');
    }
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
            _buildPlayerSettings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customPathController.dispose();
    _playerNameController.dispose();
    _playerXController.dispose();
    _playerYController.dispose();
    _playerSpeedController.dispose();
    _playerGravityController.dispose();
    super.dispose();
  }
}
