import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:virtualine/set_object.dart';
import 'package:virtualine/src/game_page/components/collision.dart';

class Player extends SpriteAnimationComponent with CollisionCallbacks {
  Offset velocity = Offset.zero;
  double speed = playerState.value.speed * 100;
  double gravity = playerState.value.gravity;
  bool isOnGround = false;

  late Sprite sprite;
  late Size screenSize =
      ui.PlatformDispatcher.instance.views.first.physicalSize /
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  late RectangleHitbox hitbox;

  Player() : super(size: Vector2(120, 120));

  static final Map<String, ui.Image> _cache = {};

  @override
  Future<void> onLoad() async {
    hitbox = RectangleHitbox();
    final path = playerState.value.path;
    if (!_cache.containsKey(path)) {
      if (!File(path).existsSync()) {
        return;
      }

      final file = File(path);
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      _cache[path] = frame.image;
    }
    final image = _cache[path]!;

    if (isSpriteSheet(path)) {
      final spriteSheet = SpriteSheet(
        image: image,
        srcSize: Vector2(64, 64),
      );
      animation = spriteSheet.createAnimation(
        row: 0,
        stepTime: 0.5,
        from: 0,
      );
    } else {
      sprite = Sprite(image);
    }
    add(hitbox);
  }

  bool isSpriteSheet(String path) {
    return path.endsWith('_sheet.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isOnGround) {
      velocity = velocity + Offset(0, gravity * dt);
    }

    double newX = x + velocity.dx * speed * dt;
    double newY = y + velocity.dy * speed * dt;

    final playerRect = hitbox.toAbsoluteRect();
    final newRect = playerRect.translate(
        velocity.dx * speed * dt, velocity.dy * speed * dt);
    bool collision = false;

    parent?.children.whereType<GameObject>().forEach((component) {
      final objectRect = component.hitbox.toAbsoluteRect();
      if (newRect.overlaps(objectRect)) {
        collision = true;

        if (velocity.dy > 0) { 
          isOnGround = true;
          velocity = Offset(velocity.dx, 0);
        }
      }
    });

    if (!collision) {
      isOnGround = false; 

      x = newX;
      y = newY;
    }
  }

  void setDirection(Offset direction) {
    velocity = direction;

    if (direction.dy < 0) {
      isOnGround = false;
    }
  }

  void moveUp() => setDirection(const Offset(0, -1));
  void moveDown() => setDirection(const Offset(0, 1));
  void moveLeft() => setDirection(const Offset(-1, 0));
  void moveRight() => setDirection(const Offset(1, 0));
  void moveUpLeft() => setDirection(const Offset(-1, -1));
  void moveUpRight() => setDirection(const Offset(1, -1));
  void moveDownLeft() => setDirection(const Offset(-1, 1));
  void moveDownRight() => setDirection(const Offset(1, 1));
  void stop() => setDirection(Offset.zero);

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is GameObject) {
      debugPrint('Player collided with GameObject');
      stop();
    }
    super.onCollision(intersectionPoints, other);
  }
}
