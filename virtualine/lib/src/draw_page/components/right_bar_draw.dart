import 'package:flutter/material.dart';
import 'color_picker.dart';
import '../../../set_stats.dart';
import './layer.dart';

class RightDrawer extends StatefulWidget {
  const RightDrawer({super.key});

  @override
  _RightDrawerState createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  bool _isColorPickerExpanded = true;
  bool _isBrushSettingsExpanded = true;
  bool _isLayersExpanded = true;

  List<Layer> _layers = [
    Layer(name: "Calque 1", isActive: true),
    Layer(name: "Calque 2", isActive: true),
  ];

  Widget _buildColorPickerSection() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isColorPickerExpanded,
        onExpansionChanged: (value) => setState(() => _isColorPickerExpanded = value),
        leading: const Icon(Icons.palette, color: Colors.purple),
        title: const Text(
          'Sélecteur de couleur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ColorPicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSettings() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isBrushSettingsExpanded,
        onExpansionChanged: (value) => setState(() => _isBrushSettingsExpanded = value),
        leading: const Icon(Icons.brush, color: Colors.purple),
        title: const Text(
          'Paramètres du pinceau',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSliderSection(
                  label: 'Épaisseur',
                  value: widthState.value,
                  min: 1.0,
                  max: 200.0,
                  onChanged: (value) {
                    setState(() {
                      widthState.value = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSliderSection(
                  label: 'Opacité',
                  value: opacityState.value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      opacityState.value = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersSection() {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        initiallyExpanded: _isLayersExpanded,
        onExpansionChanged: (value) => setState(() => _isLayersExpanded = value),
        leading: const Icon(Icons.layers, color: Colors.purple),
        title: const Text(
          'Calques',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final layer = _layers.removeAt(oldIndex);
                _layers.insert(newIndex, layer);
              });
            },
            children: _layers.asMap().entries.map((entry) {
              int index = entry.key;
              Layer layer = entry.value;
              return _buildLayerTile(index, layer);
            }).toList(),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _layers.add(Layer(name: "Calque ${_layers.length + 1}", isActive: true));
              });
            },
            child: const Text(
              'Ajouter un calque',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildLayerTile(int index, Layer layer) {
  return ListTile(
    key: ValueKey(layer.name),
    visualDensity: VisualDensity.compact,
    leading: IconButton(
      icon: Icon(
        layer.isActive ? Icons.visibility : Icons.visibility_off,
        color: Colors.purple,
      ),
      onPressed: () => _toggleLayerVisibility(layer),
    ),
    title: GestureDetector(
      onDoubleTap: () => _editLayerName(layer),
      child: Text(
        layer.name,
        style: const TextStyle(color: Colors.white),
      ),
    ),
    trailing: IconButton(
      icon: const Icon(Icons.delete, color: Colors.red), // Icône poubelle
      onPressed: () {
        setState(() {
          _layers.removeAt(index); // Suppression du calque
        });
      },
    ),
  );
}






  void _editLayerName(Layer layer) {
    TextEditingController controller = TextEditingController(text: layer.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer le calque"),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (newName) {
            setState(() {
              layer.name = newName;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                layer.name = controller.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  void _toggleLayerVisibility(Layer layer) {
    setState(() {
      layer.isActive = !layer.isActive;
    });
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.purple,
            thumbColor: Colors.purple,
            overlayColor: Colors.purple.withOpacity(0.2),
            inactiveTrackColor: Colors.grey[700],
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
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
            _buildColorPickerSection(),
            _buildBrushSettings(),
            _buildLayersSection(),
          ],
        ),
      ),
    );
  }
}

