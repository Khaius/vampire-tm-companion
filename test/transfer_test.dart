import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/character_transfer.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';

/// Una finta foto di 1600x1200, come ne fa un telefono.
List<int> fakePhoto() {
  final image = img.Image(width: 1600, height: 1200);
  img.fill(image, color: img.ColorRgb8(120, 20, 30));
  return img.encodeJpg(image);
}

void main() {
  late Directory temp;
  late AppState state;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_transfer');
    state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Character seed(String name, {SheetType type = SheetType.v20}) {
    final character = state.createCharacter(type);
    character.texts['name'] = name;
    character.texts['clan'] = 'Toreador';
    character.dots['attr.forza'] = 3;
    character.list('discipline').add(TraitEntry(name: 'Auspex', value: 2));
    character.track('sangue', 20)[0] = 1;
    character.toggleCollapsed('rituali');
    return character;
  }

  group('Il formato del file', () {
    test('una scheda esce e rientra identica', () async {
      final original = seed('Lucrezia Baldi');
      final raw = CharacterTransfer.encode([original]);

      final result = decodeTransfer(raw);
      expect(result.isOk, isTrue);
      final read = result.characters.single.character;

      expect(read.displayName, 'Lucrezia Baldi');
      expect(read.type, SheetType.v20);
      expect(read.dot('attr.forza'), 3);
      expect(read.list('discipline').single.name, 'Auspex');
      expect(read.list('discipline').single.value, 2);
      expect(read.track('sangue', 20)[0], 1);
      expect(read.isCollapsed('rituali'), isTrue);
    });

    test('il file è JSON leggibile, con la sua marca', () {
      final raw = CharacterTransfer.encode([seed('Ysabeau')]);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['format'], 'vtm-companion.schede');
      expect(json['version'], 1);
      expect(json['characters'], hasLength(1));
      // indentato: si apre con un editor di testo e si capisce
      expect(raw, contains('\n  "format"'));
    });

    test('il nome del file dice cosa contiene', () {
      final una = CharacterTransfer.fileName([
        seed('Lucrezia Baldi'),
      ], now: DateTime(2026, 8, 6));
      expect(una, 'Lucrezia-Baldi-2026-08-06.vtm.json');

      final tante = CharacterTransfer.fileName([
        seed('Uno'),
        seed('Due'),
      ], now: DateTime(2026, 8, 6));
      expect(tante, 'schede-2-2026-08-06.vtm.json');
    });
  });

  group('File che non vanno bene', () {
    test('un file che non è JSON', () {
      final result = decodeTransfer('non sono json');
      expect(result.isOk, isFalse);
      expect(result.error, contains('non è leggibile'));
    });

    test('un JSON di un\'altra app', () {
      final result = decodeTransfer('{"pippo": 1}');
      expect(result.isOk, isFalse);
      expect(result.error, contains('non è un\'esportazione'));
    });

    test('un file di una versione futura', () {
      final result = decodeTransfer(
        jsonEncode({
          'format': CharacterTransfer.format,
          'version': 99,
          'characters': [],
        }),
      );
      expect(result.isOk, isFalse);
      expect(result.error, contains('più recente'));
    });

    test('un file senza schede', () {
      final result = decodeTransfer(
        jsonEncode({
          'format': CharacterTransfer.format,
          'version': 1,
          'characters': [],
        }),
      );
      expect(result.isOk, isFalse);
      expect(result.error, contains('nessuna scheda'));
    });

    test('una scheda rotta non fa perdere le altre', () {
      final buona = seed('Buona');
      final result = decodeTransfer(
        jsonEncode({
          'format': CharacterTransfer.format,
          'version': 1,
          'characters': [
            {'questo': 'non è una scheda'},
            buona.toJson(),
          ],
        }),
      );
      expect(result.isOk, isTrue);
      expect(result.characters, hasLength(1));
      expect(result.characters.single.character.displayName, 'Buona');
    });
  });

  group('Importazione dentro l\'app', () {
    test('la scheda importata è sempre una scheda nuova', () async {
      final original = seed('Lucrezia');
      final result = decodeTransfer(CharacterTransfer.encode([original]));

      final added = await state.importCharacters(result.characters);
      expect(added, hasLength(1));
      expect(state.characters, hasLength(2));
      // id nuovo: reimportare non sovrascrive mai quella sul telefono
      expect(added.single.id, isNot(original.id));
      expect(added.single.dot('attr.forza'), 3);
      // ...e il nome dice che è un doppione
      expect(added.single.displayName, 'Lucrezia (importata)');
    });

    test('una scheda che non c\'è tiene il suo nome', () async {
      final raw = CharacterTransfer.encode([seed('Ysabeau')]);
      final result = decodeTransfer(raw);
      // la scheda di partenza sparisce dal telefono: non è più un doppione
      await state.deleteCharacter(state.characters.first);

      final added = await state.importCharacters(result.characters);
      expect(added.single.displayName, 'Ysabeau');
    });

    test('la scheda importata finisce su disco', () async {
      final result = decodeTransfer(CharacterTransfer.encode([seed('Elena')]));
      final added = await state.importCharacters(result.characters);

      final onDisk = await CharacterRepository(overrideDir: temp).loadAll();
      expect(onDisk.map((c) => c.id), contains(added.single.id));
    });
  });

  group('Foto', () {
    test('viene rimpicciolita e riscritta in JPEG', () async {
      final character = seed('Lucrezia');
      final source = File('${temp.path}/originale.jpg');
      await source.writeAsBytes(fakePhoto());
      expect(await source.length(), greaterThan(2000));

      await state.setPhoto(character, source.path);

      expect(character.photoFile, '${character.id}.jpg');
      final stored = await state.characterRepository.photoBytes(character);
      final decoded = img.decodeImage(stored!)!;
      expect(decoded.width, 1024, reason: 'il lato lungo va portato a 1024');
      expect(decoded.height, 768);

      // la scheda non dipende più dal file di partenza
      await source.delete();
      expect(await state.characterRepository.photoPath(character), isNotNull);
    });

    test('viaggia dentro il file esportato', () async {
      final character = seed('Lucrezia');
      final source = File('${temp.path}/originale.jpg');
      await source.writeAsBytes(fakePhoto());
      await state.setPhoto(character, source.path);

      final photos = {
        character.id: (await state.characterRepository.photoBytes(character))!,
      };
      final raw = CharacterTransfer.encode([character], photos: photos);
      final result = decodeTransfer(raw);
      expect(result.characters.single.photo, isNotNull);

      final added = await state.importCharacters(result.characters);
      final restored = await state.characterRepository.photoPath(added.single);
      expect(restored, isNotNull);
      expect(img.decodeImage(File(restored!).readAsBytesSync()), isNotNull);
    });

    test('togliere la foto cancella il file', () async {
      final character = seed('Lucrezia');
      final source = File('${temp.path}/originale.jpg');
      await source.writeAsBytes(fakePhoto());
      await state.setPhoto(character, source.path);
      final path = await state.characterRepository.photoPath(character);

      await state.removePhoto(character);
      expect(character.photoFile, isNull);
      expect(File(path!).existsSync(), isFalse);
    });

    test('cancellando la scheda se ne va anche la foto', () async {
      final character = seed('Lucrezia');
      final source = File('${temp.path}/originale.jpg');
      await source.writeAsBytes(fakePhoto());
      await state.setPhoto(character, source.path);
      final path = await state.characterRepository.photoPath(character);

      await state.deleteCharacter(character);
      expect(File(path!).existsSync(), isFalse);
    });

    test('il nome della foto sopravvive al salvataggio', () async {
      final character = seed('Lucrezia');
      final source = File('${temp.path}/originale.jpg');
      await source.writeAsBytes(fakePhoto());
      await state.setPhoto(character, source.path);

      await state.characterRepository.save(character);
      final reloaded = (await state.characterRepository.loadAll()).firstWhere(
        (c) => c.id == character.id,
      );
      expect(reloaded.photoFile, '${character.id}.jpg');
    });
  });

  group('Il file scritto sul telefono', () {
    test('esportando si ottiene un file leggibile', () async {
      final uno = seed('Lucrezia');
      final due = seed('Ysabeau', type: SheetType.darkAges);

      final file = await state.exportCharacters([uno, due], overrideDir: temp);
      expect(await file.exists(), isTrue);

      final result = decodeTransfer(await file.readAsString());
      expect(result.isOk, isTrue);
      expect(
        result.characters.map((c) => c.character.displayName),
        containsAll(<String>['Lucrezia', 'Ysabeau']),
      );
      expect(
        result.characters.map((c) => c.character.type),
        containsAll(<SheetType>[SheetType.v20, SheetType.darkAges]),
      );
    });
  });
}
