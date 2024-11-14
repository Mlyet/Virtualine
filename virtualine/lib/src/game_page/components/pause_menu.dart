import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PauseMenuComponent extends PositionComponent with HasGameRef {
  bool isVisible = false;
  late TextComponent titleText;
  late RectangleComponent resumeButton;
  late TextComponent resumeText;
  late RectangleComponent quitButton;
  late TextComponent quitText;

  PauseMenuComponent() : super(priority: 10);

  @override
  Future<void> onLoad() async {
    final buttonStyle = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    titleText = TextComponent(
      text: 'PAUSE',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    resumeButton = RectangleComponent(
      paint: Paint()..color = Colors.blue,
    );
    resumeText = TextComponent(
      text: 'Resume',
      textRenderer: buttonStyle,
    );

    quitButton = RectangleComponent(
      paint: Paint()..color = Colors.red,
    );
    quitText = TextComponent(
      text: 'Quit',
      textRenderer: buttonStyle,
    );

    _hideMenu();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    width = size.x;
    height = size.y;

    final centerX = width / 2;
    final buttonWidth = width * 0.3;
    const buttonHeight = 50.0;

    titleText.position = Vector2(centerX, height * 0.3);
    titleText.anchor = Anchor.center;

    resumeButton.size = Vector2(buttonWidth, buttonHeight);
    resumeButton.position = Vector2(centerX, height * 0.5);
    resumeButton.anchor = Anchor.center;

    resumeText.position = resumeButton.position;
    resumeText.anchor = Anchor.center;

    quitButton.size = Vector2(buttonWidth, buttonHeight);
    quitButton.position = Vector2(centerX, height * 0.6);
    quitButton.anchor = Anchor.center;

    quitText.position = quitButton.position;
    quitText.anchor = Anchor.center;
  }

  void toggleVisibility() {
    isVisible = !isVisible;
    debugPrint('isVisible: $isVisible');
    if (isVisible) {
      gameRef.pauseEngine();
      _showMenu();
    } else {
      gameRef.resumeEngine();
      _hideMenu();
    }
  }

  void _showMenu() {
    if (!children.contains(titleText)) {
      addAll([titleText, resumeButton, resumeText, quitButton, quitText]);
    } else {
      debugPrint('Components already added');
    }
  }

  void _hideMenu() {
    if (children.contains(titleText)) {
      removeAll([titleText, resumeButton, resumeText, quitButton, quitText]);
    } else {
      debugPrint('Components not present');
    }
  }

  bool onTapDown(TapDownInfo info) {
    if (!isVisible) return false;

    final touchPoint = info.eventPosition.global;

    if (resumeButton.containsPoint(touchPoint)) {
      toggleVisibility();
      return true;
    } else if (quitButton.containsPoint(touchPoint)) {
      gameRef.resumeEngine();
      toggleVisibility();
      
      if (gameRef.buildContext != null) {
        Navigator.of(gameRef.buildContext!).pop();
      } else {
        debugPrint('No context found to quit the game.');
      }

      return true;
    }
    return false;
  }
}
