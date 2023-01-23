import 'dart:convert';
import 'dart:io';

// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_windows/path_provider_windows.dart'
    show PathProviderWindows;
import 'package:win32/win32.dart';

import 'game.dart';
import 'photo.dart';

Stream<String> getPhotoPaths() async* {
  final rootPath = path.join(
    (await (PathProviderWindows().getApplicationDocumentsPath()))!,
    'Rockstar Games',
  );
  final directories = [
    Directory(path.join(rootPath, 'Red Dead Redemption 2', 'Profiles')),
    Directory(path.join(rootPath, 'GTA V', 'Profiles')),
  ];
  for (final profilesDirectory in directories) {
    if (await profilesDirectory.exists()) {
      final profileDirectories =
          profilesDirectory.list().whereType<Directory>();
      await for (final profileDirectory in profileDirectories) {
        yield* (profileDirectory.list().whereType<File>((file) {
          final fileName = path.basenameWithoutExtension(file.path);
          return fileName.startsWith('PRDR3') || fileName.startsWith('PGTA5');
        }).map((photoFile) => photoFile.path));
      }
    }
  }
}

Future<Photo> parsePhotoFile(String path) async {
  RandomAccessFile? randomAccessFile;
  Uint8List? imageBytes;
  String? title;
  String? timestampAsString;
  Game game;
  try {
    randomAccessFile = await (await File(path).open()).setPosition(0x03);
    switch (await randomAccessFile.readByte()) {
      case 0x1:
        game = Game.gta5;
        break;
      case 0x4:
        game = Game.rdr2;
        break;
      default:
        throw const FormatException();
    }
    final headerBytes = await randomAccessFile.read(9);
    if (utf8.decode(headerBytes) != 'P\u0000H\u0000O\u0000T\u0000O') {
      throw const FormatException();
    }
    final isGameGta5 = game == Game.gta5;
    await randomAccessFile.setPosition(isGameGta5 ? 0x124 : 0x12C);
    final startOfImageBytes = await randomAccessFile.read(2);
    if (startOfImageBytes[0] != 0xFF && startOfImageBytes[1] != 0xD8) {
      throw const FormatException();
    }
    var bytesBuilder = BytesBuilder(copy: false)..add(startOfImageBytes);
    var previouslyReadBytes = 0;
    var fileCanBeReadFurther = true;
    var endOfImageReached = false;
    var startOfMetadataBlockReached = false;
    var endOfMetadataBlockReached = false;

    int previouslyReadByte(int offset) {
      final shiftAmount = offset * 8;
      return (previouslyReadBytes & 0xFF << (shiftAmount)) >> shiftAmount;
    }

    do {
      const segmentMaxSize = 4096;
      final segment = await randomAccessFile.read(segmentMaxSize);
      fileCanBeReadFurther = segment.length == segmentMaxSize;
      for (var index = 0; index < segment.length; index++) {
        var byte = segment[index];
        if (!endOfImageReached) {
          if (byte == 0xD9 && previouslyReadBytes & 0xFF == 0xFF) {
            endOfImageReached = true;
            bytesBuilder.add(Uint8List.sublistView(segment, 0, index + 1));
            imageBytes = bytesBuilder.takeBytes();
            bytesBuilder = BytesBuilder(copy: true);
            await randomAccessFile.setPosition(
              isGameGta5 ? 0x80124 : 0x10012C,
            ); // JSON
            break;
          }
        } else if (!startOfMetadataBlockReached) {
          final timestampJsonKeyFound = byte == 0x3A &&
              previouslyReadByte(0) == 0x22 &&
              previouslyReadByte(1) == 0x74 &&
              previouslyReadByte(2) == 0x61 &&
              previouslyReadByte(3) == 0x65 &&
              previouslyReadByte(4) == 0x72 &&
              previouslyReadByte(5) == 0x63 &&
              previouslyReadByte(6) == 0x22 /* "creat": */;
          if (timestampJsonKeyFound ||
              byte == 0x4C &&
                  previouslyReadByte(0) == 0x54 &&
                  previouslyReadByte(1) == 0x49 &&
                  previouslyReadByte(2) == 0x54 /* TITL */) {
            startOfMetadataBlockReached = true;
            endOfMetadataBlockReached = false;
            index += timestampJsonKeyFound ? 1 : 5;
            byte = segment[index];
          }
        } else if (!endOfMetadataBlockReached && byte == 0x0 || byte == 0x2C) {
          endOfMetadataBlockReached = true;
          startOfMetadataBlockReached = false;
          final decodedString = utf8.decode(bytesBuilder.takeBytes());
          if (timestampAsString == null) {
            timestampAsString = decodedString;
            index = 3079; // TITL
          } else {
            title = decodedString;
            break;
          }
        }
        if (startOfMetadataBlockReached && !endOfMetadataBlockReached) {
          bytesBuilder.addByte(byte);
        }
        previouslyReadBytes = (previouslyReadBytes << 8) + byte;
      }
      if (!endOfImageReached) {
        bytesBuilder.add(segment);
      }
    } while (fileCanBeReadFurther);
  } finally {
    await randomAccessFile?.close();
  }
  DateTime? dateTaken;
  if (timestampAsString != null) {
    final timestamp = int.tryParse(timestampAsString);
    if (timestamp != null) {
      dateTaken = DateTime.fromMillisecondsSinceEpoch(
        Duration(seconds: timestamp).inMilliseconds,
        isUtc: true,
      );
    }
  }
  if (imageBytes == null) {
    throw const FormatException();
  }
  return Photo(
    imageData: imageBytes,
    title: title,
    dateTaken: dateTaken,
    game: game,
    path: path,
  );
}

Future<bool?> savePhotos(Iterable<Photo> photos) async {
  if (photos.isEmpty) return null;
  if (photos.length == 1) return _savePhoto(photos.first);
  final Directory? directory;
  try {
    directory = DirectoryPicker().getDirectory();
  } catch (e) {
    return false;
  }
  if (directory == null) return null;
  var success = true;
  for (final photo in photos) {
    try {
      await File(path.join(directory.path, '${photo.title}.jpeg'))
          .writeAsBytes(photo.imageData);
    } catch (_) {
      success = false;
    }
  }
  return success;
}

Future<bool?> _savePhoto(Photo photo) async {
  const jpegExtensions = ['.jpg', '.jpeg', '.jfif', '.jpe', '.jif', '.jfi'];
  File? file;
  try {
    final picker = SaveFilePicker()
      ..initialDirectory =
          await PathProviderWindows().getPath(FOLDERID_Pictures)
      ..fileName = photo.title
      ..defaultExtension = 'jpeg'
      ..filterSpecification = {
        'JPEG Files': jpegExtensions.map((it) => '*$it').join(';'),
      };
    file = picker.getFile();
  } catch (_) {
    return false;
  }
  if (file == null) return null;
  final extension = path.extension(file.path);
  if (!jpegExtensions.contains(extension)) {
    file = File('${path.basenameWithoutExtension(file.path)}.jpeg');
    MessageBox(
      0,
      TEXT(
        'The format of the extracted image is JPEG/JFIF; '
        'the extension of the file has been changed to .jpeg.',
      ),
      TEXT('Warning'),
      MB_ICONWARNING,
    );
  }
  try {
    await file.writeAsBytes(photo.imageData);
  } catch (_) {
    return false;
  }
  return true;
}

Future<bool?> deletePhotos(Iterable<Photo> photos) async {
  if (photos.isEmpty) return null;
  var success = true;
  for (final photo in photos) {
    try {
      await File(photo.path).delete();
    } catch (_) {
      success = false;
    }
  }
  return success;
}

extension _StreamElementTypeFiltering<T> on Stream<T> {
  Stream<S> whereType<S>([bool Function(T event)? test]) =>
      where((e) => e is S && (test?.call(e) ?? true)).cast();
}
