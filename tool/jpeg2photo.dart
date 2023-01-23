import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln("Don't forget the arguments next time.");
    return;
  }
  final sourceFiles = args
      .expand((path) sync* {
        if (FileSystemEntity.isDirectorySync(path)) {
          yield* Directory(path).listSync().where((fse) {
            return fse is File &&
                RegExp(r'(?:\.jpe?g)$', caseSensitive: false)
                    .hasMatch(fse.path);
          }).cast<File>();
        } else {
          yield File(path);
        }
      })
      .map((f) => f.absolute)
      .toList(growable: false);
  for (var index = 0; index < sourceFiles.length; index++) {
    final sourceFile = sourceFiles[index];
    final sourceFilePath = sourceFile.path;
    if (!sourceFile.existsSync()) {
      stderr.writeln("'$sourceFilePath' is not a path to a file.");
      continue;
    }
    final startOfFileName = sourceFilePath.lastIndexOf(r'\') + 1;
    final fileName = sourceFilePath.substring(
      startOfFileName,
      sourceFilePath.lastIndexOf('.'),
    );
    final photoFile = File(
      sourceFilePath.replaceRange(
        startOfFileName,
        null,
        'PRDR3${(index + 1).toString().padLeft(10, '0')}_1',
      ),
    );
    final imageBytes = sourceFile.readAsBytesSync();
    if (imageBytes[0] != 0xFF || imageBytes[1] != 0xD8) {
      stderr.writeln("'$sourceFilePath' is not a JPEG image.");
      continue;
    }
    final builder = BytesBuilder(copy: false)
      ..add([0, 0, 0, 0x4, 0x50, 0, 0x48, 0, 0x4F, 0, 0x54, 0, 0x4F])
      ..add(Uint8List(287))
      ..add(imageBytes)
      ..add(Uint8List(1051656 - imageBytes.length))
      ..add(utf8.encode('TITL\u0000\u0001\u0000\u0000$fileName\u0000'));
    photoFile.writeAsBytesSync(builder.takeBytes(), flush: true);
  }
}
