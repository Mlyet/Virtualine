import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';

class LeftConstructor extends StatefulWidget {
  final List<ImageWidgetInfo> imageWidgetsInfo;
  final Function(int index)? onDelete;

  const LeftConstructor({
    super.key,
    required this.imageWidgetsInfo,
    this.onDelete,
  });

  @override
  // ignore: library_private_types_in_public_api
  _LeftConstructorState createState() => _LeftConstructorState();
}

class _LeftConstructorState extends State<LeftConstructor> {
  final Map<int, bool> _expandedItems = {};
  final Map<int, TextEditingController> xControllers = {};
  final Map<int, TextEditingController> yControllers = {};
  final Map<int, TextEditingController> nameControllers = {};

  @override
  void dispose() {
    xControllers.forEach((_, controller) => controller.dispose());
    yControllers.forEach((_, controller) => controller.dispose());
    nameControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  bool isExpanded(int index) => _expandedItems[index] ?? false;

  TextEditingController _getController(
    Map<int, TextEditingController> controllers,
    int index,
    String initialValue,
  ) {
    return controllers.putIfAbsent(
      index,
      () => TextEditingController(text: initialValue),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildItemCard(ImageWidgetInfo info, int index) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        initiallyExpanded: isExpanded(index),
        onExpansionChanged: (expanded) {
          setState(() => _expandedItems[index] = expanded);
        },
       
        title: Text(
          info.name,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => widget.onDelete?.call(index),
            ),
            Icon(
              isExpanded(index) ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Nom',
                  controller: _getController(
                    nameControllers,
                    index,
                    info.name,
                  ),
                  onChanged: (value) => setState(() => info.name = value),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  label: 'Position X',
                  controller: _getController(
                    xControllers,
                    index,
                    info.x.toStringAsFixed(2),
                  ),
                  onChanged: (value) => setState(() {
                    info.x = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
                  }),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  label: 'Position Y',
                  controller: _getController(
                    yControllers,
                    index,
                    info.y.toStringAsFixed(2),
                  ),
                  onChanged: (value) => setState(() {
                    info.y = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
                  }),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: info.colision,
                        onChanged: (value) {
                          setState(() => info.colision = value);
                        },
                        activeColor: Colors.purple,
                      ),
                    ),
                    const Text(
                      'Collision',
                      style: TextStyle(color: Colors.white70),
                    ),

                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: info.finished,
                        onChanged: (value) {
                          setState(() => info.finished = value);
                        },
                        activeColor: Colors.purple,
                      ),
                    ),
                    const Text(
                      'Finished',
                      style: TextStyle(color: Colors.white70),
                    ),
                
                  ],
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
      decoration: BoxDecoration(
        color: Colors.grey[850],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
            ),
            child: const Row(
              children: [
                Icon(Icons.list, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Liste des objets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.imageWidgetsInfo.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) => _buildItemCard(
                widget.imageWidgetsInfo[index],
                index,
              ),
            ),
          ),
        ],
      ),
    );
  }
}