import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/src/game_page/components/collision.dart';
import 'package:virtualine/src/game_page/components/pause_menu.dart';
import 'package:virtualine/src/game_page/components/player.dart';
import 'package:virtualine/base_page.dart';

class GamePage extends BasePage {
  const GamePage({
    super.key,
    required super.imageWidgetsInfo,
    super.disableZoom = true,
  }) : super(isGameMode: true);

  @override
  Widget buildContent(BuildContext context) {
    return GameWidget<MyGame>(
      game: MyGame(imageWidgetsInfo: imageWidgetsInfo),
    );
  }

  @override
  Game createGame() {
    return MyGame(imageWidgetsInfo: imageWidgetsInfo);
  }
}

class MyGame extends FlameGame with KeyboardEvents, HasCollisionDetection, TapDetector {
  final List<ImageWidgetInfo> imageWidgetsInfo;
  late Player player;
  late CameraComponent cameraComponent;
  late PauseMenuComponent pauseMenu;

  MyGame({required this.imageWidgetsInfo});

  final Set<LogicalKeyboardKey> _movementKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyZ,
    LogicalKeyboardKey.keyQ,
  };

  @override
  Future<void> onLoad() async {
    player = Player()..position = Vector2(100, 100);

    final world = World();
    world.add(player);

    for (var info in imageWidgetsInfo) {
      final gameObject = await createGameObject(
        position: Vector2(info.x, info.y),
        size: Vector2(100, 100),
        imagePath: info.path,
        hasCollision: info.colision,
        finished: info.finished,
      );
      world.add(gameObject);
    }

    cameraComponent = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.center;

    cameraComponent.follow(player);
    addAll([world, cameraComponent]);

    pauseMenu = PauseMenuComponent(); 
    add(pauseMenu);

    

    debugMode = true;
  }

  void handlePlayerMovement(Set<LogicalKeyboardKey> keysPressed) {
    bool up = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.keyZ);
    bool down = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS);
    bool left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.keyQ);
    bool right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);

    if (up && left) {
      player.moveUpLeft();
    } else if (up && right) {
      player.moveUpRight();
    } else if (down && left) {
      player.moveDownLeft();
    } else if (down && right) {
      player.moveDownRight();
    } else {
      if (up) {
        player.moveUp();
      } else if (down) {
        player.moveDown();
      }
      if (left) {
        player.moveLeft();
      } else if (right) {
        player.moveRight();
      }
    }
  }

  void handleKeyDown(Set<LogicalKeyboardKey> keysPressed) {
    handlePlayerMovement(keysPressed);
  }

  void handleKeyUp(Set<LogicalKeyboardKey> keysPressed) {
    if (_movementKeys.intersection(keysPressed).isEmpty) {
      player.stop();
    } else {
      handlePlayerMovement(keysPressed);
    }
  }
  

bool _isEscapeHandled = false; 

@override
KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
    if (!_isEscapeHandled) {
      _isEscapeHandled = true;  
      pauseMenu.toggleVisibility();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.escape) {
    _isEscapeHandled = false;
    return KeyEventResult.handled;
  }

  if (!pauseMenu.isVisible) {
    if (event is KeyDownEvent) {
      handleKeyDown(keysPressed);
    } else if (event is KeyUpEvent) {
      handleKeyUp(keysPressed);
    }
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
}


  @override
  bool onTapDown(TapDownInfo info) {
    if (pauseMenu.isVisible) {
      return pauseMenu.onTapDown(info);
    }
    return false;
  }
}