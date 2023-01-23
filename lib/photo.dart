import 'dart:typed_data';

import 'game.dart';

class Photo {
  const Photo({
    required this.imageData,
    String? title,
    this.dateTaken,
    required this.game,
    required this.path,
  }) : title = title ?? 'Untitled';

  final Uint8List imageData;
  final String title;
  final DateTime? dateTaken;
  final Game game;
  final String path;
}
