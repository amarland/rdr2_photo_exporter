@TestOn('vm')
//
import 'package:flutter_test/flutter_test.dart';
import 'package:rdr2_photo_exporter/filesystem/filesystem.dart';
import 'package:rdr2_photo_exporter/models/game.dart';

void main() {
  group('valid photo files are parsed successfully', () {
    test('Grand Theft Auto V', () {
      final photo = parsePhotoFileSync('./test/res/PGTA5_1');
      expect(photo.imageData.length, 80046);
      expect(photo.title, 'Vinewood Hills');
      expect(photo.dateTaken, DateTime.utc(2022, 12, 28, 17, 49, 30));
      expect(photo.game, Game.gta5);
    });
    test('Red Dead Redemption II', () {
      final photo = parsePhotoFileSync('./test/res/PRDR3_1');
      expect(photo.imageData.length, 295346);
      expect(photo.title, 'Cornwall Kerosene & Tar');
      expect(photo.dateTaken, DateTime.utc(2022, 10, 26, 21, 48, 28));
      expect(photo.game, Game.rdr2);
    });
  });
}
