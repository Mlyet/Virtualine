import 'dart:io';
import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/search_directory.dart';
import 'package:flame/game.dart';
import 'package:virtualine/src/game_page/game_page.dart';

const double _kMinScale = 0.1;
const double _kMaxScale = 10.0;
const double _kScaleIncrement = 1.2;
const double _kDefaultObjectSize = 100.0;
const double _kPlayerWidth = 128.0;
const double _kPlayerHeight = 100.0;
const EdgeInsets _kBoundaryMargin = EdgeInsets.all(20000);

// Custom types
typedef DirectoryListCallback = void Function(String path);

class ViewportState {
  final bool isDragging;
  final Offset lastFocalPoint;
  final double currentScale;
  final Size viewportSize;
  
  const ViewportState({
    this.isDragging = false,
    this.lastFocalPoint = Offset.zero,
    this.currentScale = 1.0,
    this.viewportSize = Size.zero,
  });

  ViewportState copyWith({
    bool? isDragging,
    Offset? lastFocalPoint,
    double? currentScale,
    Size? viewportSize,
  }) {
    return ViewportState(
      isDragging: isDragging ?? this.isDragging,
      lastFocalPoint: lastFocalPoint ?? this.lastFocalPoint,
      currentScale: currentScale ?? this.currentScale,
      viewportSize: viewportSize ?? this.viewportSize,
    );
  }
}

abstract class BasePage extends StatefulWidget {
  final List<ImageWidgetInfo> imageWidgetsInfo;
  final bool disableZoom;
  final bool isGameMode;

  const BasePage({
    super.key,
    required this.imageWidgetsInfo,
    this.disableZoom = false,
    this.isGameMode = false,
  });

  @override
  BasePageState createState() => BasePageState();

  Widget buildContent(BuildContext context);
  Game? createGame() => null;
}

class BasePageState extends State<BasePage> {
  // Controllers
  late final TransformationController _transformationController;
  late final TextEditingController _customPathController;
  late final TextEditingController _projectNameController;
  final GlobalKey _containerKey = GlobalKey();

  // State
  late ViewportState _viewportState;
  ImageWidgetInfo? _selectedObject;
  List<String> _directoryList = [];
  
  
  // Player state
  String? _playerPath;
  double _playerX = 0.0;
  double _playerY = 0.0;

  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeViewportState();
    _setupListeners();
    _loadInitialData();
  }

  void _initializeControllers() {
    _transformationController = TransformationController();
    _customPathController = TextEditingController();
    _projectNameController = TextEditingController();
  }

  void _initializeViewportState() {
    _viewportState = const ViewportState();
  }

  void _setupListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateViewportSize());
    playerState.addListener(_handlePlayerStateChange);
  }

  void _loadInitialData() {
    void updateDirectoryList(String path) {
      setState(() => _directoryList = listDirectories(path));
    }
    
    loadPathProject(_customPathController, updateDirectoryList);
    loadProjectName(_projectNameController);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _customPathController.dispose();
    _projectNameController.dispose();
    playerState.removeListener(_handlePlayerStateChange);
    super.dispose();
  }

  void _handlePlayerStateChange() {
    if (!mounted) return;
    
    setState(() {
      _playerPath = playerState.value.path;
      _playerX = playerState.value.x;
      _playerY = playerState.value.y;
    });
  }

  void _updateViewportSize() {
    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _viewportState = _viewportState.copyWith(
          viewportSize: renderBox.size,
        );
      });
    }
  }


void _applyTransformation(Offset focalPoint, double scale) {
  final double visibleWidth = _viewportState.viewportSize.width / scale;
  final double visibleHeight = _viewportState.viewportSize.height / scale;

  final double newX = focalPoint.dx.clamp(
    0,
    20000 - visibleWidth,
  );
  final double newY = focalPoint.dy.clamp(
    0,
    20000 - visibleHeight,
  );

  _transformationController.value = Matrix4.identity()
    ..translate(newX, newY)
    ..scale(scale)
    ..translate(-focalPoint.dx, -focalPoint.dy);
}



  List<Widget> _buildImageWidgets() {
    return widget.imageWidgetsInfo.map((info) => _buildDraggableImage(info)).toList();
  }

  Widget _buildDraggableImage(ImageWidgetInfo info) {
    final isSelected = _selectedObject == info;
    
    return Positioned(
      left: info.x,
      top: info.y,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onPanStart: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final scenePoint = _transformationController.toScene(localPosition);
            
            setState(() {
              _dragOffset = Offset(
                info.x - scenePoint.dx,
                info.y - scenePoint.dy,
              );
              _selectedObject = info;
              _viewportState = _viewportState.copyWith(isDragging: true);
            });
          },
          onPanUpdate: (details) => _handleImageDragUpdate(details, info),
          onPanEnd: (_) => _handleImageDragEnd(),
          child: _buildImageContainer(info, isSelected),
        ),
      ),
    );
  }

  Widget _buildImageContainer(ImageWidgetInfo info, bool isSelected) {
    return Container(
      width: _kDefaultObjectSize,
      height: _kDefaultObjectSize,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(info.path)),
          fit: BoxFit.contain,
        ),
        border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
      ),
    );
  }

void _handleImageDragUpdate(DragUpdateDetails details, ImageWidgetInfo info) {
  if (!_viewportState.isDragging) return;

  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final localPosition = renderBox.globalToLocal(details.globalPosition);
  final scenePoint = _transformationController.toScene(localPosition);

  setState(() {
    info.x = (scenePoint.dx + _dragOffset.dx).clamp(0, 20000 - _kDefaultObjectSize);
    info.y = (scenePoint.dy + _dragOffset.dy).clamp(0, 20000 - _kDefaultObjectSize);
  });
}


  void _handleImageDragEnd() {
    setState(() {
      _selectedObject = null;
      _viewportState = _viewportState.copyWith(isDragging: false);
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: widget.isGameMode ? _buildGameArea() : _buildEditArea(),
    );
  }

Widget _buildEditArea() {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      DragTarget<List<dynamic>>(
        builder: (context, candidateData, rejectedData) {
          return SizedBox.expand(
            child: InteractiveViewer(
              key: _containerKey,
              transformationController: _transformationController,
              boundaryMargin: _kBoundaryMargin,
              minScale: _kMinScale,
              maxScale: _kMaxScale,
              panEnabled: !_viewportState.isDragging,
              scaleEnabled: !widget.disableZoom && !_viewportState.isDragging,
              constrained: false,
              child: Container(
                width: 20000,
                height: 20000,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple, width: 5.0), 
                ),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    _buildPlayer(),
                    widget.buildContent(context),
                    ..._buildImageWidgets(),
                  ],
                ),
              ),
            ),
          );
        },
        onAcceptWithDetails: _handleDragAccept,
      ),
      _buildZoomControls(),
    ],
  );
}

  Widget _buildGameArea() {
    final game = widget.createGame();
    return game != null
        ? GameWidget(game: game)
        : const Center(child: Text('Game not initialized'));
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        children: [
          _buildZoomButton('zoomIn', Icons.add, _handleZoomIn),
          const SizedBox(height: 8),
          _buildZoomButton('zoomOut', Icons.remove, _handleZoomOut),
          const SizedBox(height: 8),
          _buildZoomButton('reset', Icons.center_focus_strong, _handleResetView),
          const SizedBox(height: 8),
          _buildStartButton('start', Icons.play_arrow, _handleStart),
        ],
      ),
    );
  }


  Widget _buildStartButton(String tag, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: tag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildZoomButton(String tag, IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      heroTag: tag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  void _handleZoomIn() => _zoom(_kScaleIncrement);
  void _handleZoomOut() => _zoom(1 / _kScaleIncrement);
  void _handleResetView() => _transformationController.value = Matrix4.identity();
  void _handleStart() => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePage(imageWidgetsInfo: widget.imageWidgetsInfo)));

void _zoom(double factor) {
  final currentScale = _transformationController.value.getMaxScaleOnAxis();
  final newScale = (currentScale * factor).clamp(_kMinScale, _kMaxScale);
  
  if (newScale != currentScale) {
    final center = Offset(
      _viewportState.viewportSize.width / 2,
      _viewportState.viewportSize.height / 2,
    );
   final focalPointScene = _transformationController.toScene(_viewportState.lastFocalPoint);
_applyTransformation(focalPointScene, newScale);

  }
}


  Widget _buildPlayer() {
    return Positioned(
      left: _playerX,
      top: _playerY,
      child: Listener(
        onPointerDown: (_) => setState(() => _viewportState = _viewportState.copyWith(isDragging: true)),
        onPointerMove: _handlePlayerMove,
        onPointerUp: (_) => setState(() => _viewportState = _viewportState.copyWith(isDragging: false)),
        child: SizedBox(
          width: _kPlayerWidth,
          height: _kPlayerHeight,
          child: _playerPath != null && File(_playerPath!).existsSync()
              ? Image.file(File(_playerPath!))
              : Container(),
        ),
      ),
    );
  }

  void _handlePlayerMove(PointerMoveEvent event) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);
    final scenePoint = _transformationController.toScene(localPosition);

    setState(() {
      _playerX = scenePoint.dx - _kPlayerWidth / 2;
      _playerY = scenePoint.dy - _kPlayerHeight / 2;

      playerState.value.x = _playerX;
      playerState.value.y = _playerY;
    });
  }

  void _handleDragAccept(DragTargetDetails<List<dynamic>> details) async {
    final item = details.data;
    if (item.length != 2 || item[1] == 2) return;

    final imagePath = '${_customPathController.text}/${_projectNameController.text}/assets/dessin/${item[0]}';
    if (!File(imagePath).existsSync()) return;

    final RenderBox renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.offset);
    final scenePoint = _transformationController.toScene(localPosition);

    final newImageWidgetInfo = ImageWidgetInfo(
      path: imagePath,
      name: 'Object ${widget.imageWidgetsInfo.length + 1}',
      x: scenePoint.dx - _kDefaultObjectSize / 2,  
      y: scenePoint.dy - _kDefaultObjectSize / 2,
      colision: false,
    );

    setState(() {
      widget.imageWidgetsInfo.add(newImageWidgetInfo);
    });
  }
}