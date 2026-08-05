import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_test');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('la scheda sopravvive al salvataggio e alla rilettura', () async {
    final repository = CharacterRepository(overrideDir: temp);
    final character = Character(id: 'abc', type: SheetType.darkAges);
    character.texts['name'] = 'Ysabeau di Aquitania';
    character.texts['clan'] = 'Toreador';
    character.dots['attr.forza'] = 7;
    character.list('discipline').add(TraitEntry(name: 'Ascendente', value: 4));
    character
        .list('armi')
        .add(TraitEntry(name: 'Spada lunga', fields: {'danno': 'Forza+2'}));
    character.track('sangue', 50)[3] = 1;

    await repository.save(character);

    final reloaded = (await repository.loadAll()).single;
    expect(reloaded.id, 'abc');
    expect(reloaded.type, SheetType.darkAges);
    expect(reloaded.displayName, 'Ysabeau di Aquitania');
    expect(reloaded.dot('attr.forza'), 7);
    expect(reloaded.list('discipline').single.name, 'Ascendente');
    expect(reloaded.list('discipline').single.value, 4);
    expect(reloaded.list('armi').single.fields['danno'], 'Forza+2');
    expect(reloaded.track('sangue', 50)[3], 1);
  });

  test('una scheda vuota è valida: nessun campo è obbligatorio', () async {
    final repository = CharacterRepository(overrideDir: temp);
    final character = Character(id: 'vuota', type: SheetType.v5);
    await repository.save(character);

    final reloaded = (await repository.loadAll()).single;
    expect(reloaded.displayName, 'Senza nome');
    expect(reloaded.texts, isEmpty);
    expect(reloaded.dot('attr.forza'), 0);
  });

  test('un file corrotto non impedisce di leggere le altre schede', () async {
    final repository = CharacterRepository(overrideDir: temp);
    await repository.save(Character(id: 'buona', type: SheetType.v20));
    final dir = Directory('${temp.path}/schede');
    await File('${dir.path}/rotta.json').writeAsString('{non json');

    final all = await repository.loadAll();
    expect(all.map((c) => c.id), ['buona']);
  });

  test('la lunghezza dei tracker si adatta allo schema', () {
    final character = Character(id: 'x', type: SheetType.v20);
    expect(character.track('salute', 7).length, 7);
    character.track('salute', 7)[6] = 3;
    // riletto con una lunghezza maggiore: i valori restano in testa
    final grown = character.track('salute', 10);
    expect(grown.length, 10);
    expect(grown[6], 3);
    expect(character.track('salute', 7).length, 7);
  });

  test('la selezione della scheda parte vuota e si chiude a mano', () async {
    final state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
    expect(state.selectedCharacterId, isNull);

    final created = state.createCharacter(SheetType.v20);
    state.selectCharacter(created.id);
    expect(state.selectedCharacterId, created.id);
    expect(state.selectedCharacter, isNotNull);

    state.closeSelectedCharacter();
    expect(state.selectedCharacterId, isNull);
  });

  test(
    'i documenti importati vengono copiati nella cartella dell\'app',
    () async {
      final source = File('${temp.path}/manuale.pdf');
      await source.writeAsBytes(List<int>.filled(2048, 37));

      final repository = DocumentRepository(overrideDir: temp);
      final doc = await repository.import(
        sourcePath: source.path,
        id: 'doc1',
        title: 'Manuale Base',
      );

      expect(doc.title, 'Manuale Base');
      expect(doc.sizeBytes, 2048);
      expect(await File(await repository.pathOf(doc)).exists(), isTrue);
      expect((await repository.loadAll()).single.id, 'doc1');

      // il PDF resta leggibile anche se l'originale sparisce
      await source.delete();
      expect(await File(await repository.pathOf(doc)).exists(), isTrue);

      await repository.delete(doc);
      expect(await repository.loadAll(), isEmpty);
    },
  );

  test('la coda dei dadi tiene lo storico della sessione', () async {
    final state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();

    state.setDicePool(5);
    state.setDifficulty(7);
    expect(state.dicePool, 5);
    expect(state.difficulty, 7);

    // il minimo è un dado e la difficoltà resta fra 2 e 10
    state.setDicePool(0);
    expect(state.dicePool, 1);
    state.setDifficulty(99);
    expect(state.difficulty, 10);

    state.roll();
    state.roll();
    expect(state.rollHistory.length, 2);
    state.clearHistory();
    expect(state.rollHistory, isEmpty);
  });
}
