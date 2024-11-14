import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerObject {
  final String path;
  double x;
  double y;
  double speed;
  double gravity;

  PlayerObject({
    required this.path,
    required this.x,
    required this.y,
    this.speed = 1,
    this.gravity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'x': x,
      'y': y,
      'speed': speed,
      'gravity': gravity,
    };
  }

  static PlayerObject fromMap(Map<String, dynamic> map) {
    return PlayerObject(
      path: map['path'],
      x: map['x'],
      y: map['y'],
      speed: map['speed'],
      gravity: map['gravity'],
    );
  }
}

final playerState = ValueNotifier<PlayerObject>(PlayerObject(path: '', x: 200, y: 100));

void savePlayer(PlayerObject player) async {
  final prefs = await SharedPreferences.getInstance();
  String playerJson = jsonEncode(player.toMap());
  prefs.setString('player', playerJson);
}


Future<PlayerObject?> loadPlayer() async {
  final prefs = await SharedPreferences.getInstance();
  String? savedPlayer = prefs.getString('player');
  if (savedPlayer != null) {
    Map<String, dynamic> playerMap = jsonDecode(savedPlayer);
    playerState.value = PlayerObject.fromMap(playerMap);
  }
  return playerState.value;
}

void loadStats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedPlayer = prefs.getString('player');

  if (savedPlayer != null) {
    Map<String, dynamic> playerMap = jsonDecode(savedPlayer);
    playerState.value = PlayerObject.fromMap(playerMap);
  }
}

void saveStats() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String playerJson = jsonEncode(playerState.value.toMap());
  prefs.setString('player', playerJson);
}

class ImageWidgetInfo {
  final String path;
  String name;
  double x;
  double y;
  bool colision;
  bool finished;

  ImageWidgetInfo(
      {required this.path,
      required this.x,
      required this.y,
      required this.colision,
      required this.name,
      this.finished = false});


  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'x': x,
      'y': y,
      'colision': colision,
      'name': name,
      'finished': finished,
    };
  }

  static ImageWidgetInfo fromMap(Map<String, dynamic> map) {
    return ImageWidgetInfo(
      path: map['path'],
      x: map['x'],
      y: map['y'],
      colision: map['colision'],
      name: map['name'],
      finished: map['finished'],
    );
  }
}
