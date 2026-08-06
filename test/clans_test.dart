import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/data/archetypes.dart';
import 'package:vtm_companion/data/clans.dart';
import 'package:vtm_companion/data/schemas.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';

void main() {
  group('Le tabelle dei clan e i menu delle schede non divergono', () {
    test('a ogni clan del menu corrisponde una regola, e viceversa', () {
      for (final type in SheetType.values) {
        final schema = schemaFor(type);
        final inMenu = schema.identity
            .firstWhere((f) => f.key == 'clan')
            .options;
        final withRules = clanRulesFor(type).map((c) => c.name).toList();
        expect(inMenu, withRules, reason: type.id);
      }
    });

    test('le Discipline precompilate sono quelle che la scheda propone', () {
      for (final type in SheetType.values) {
        final known = schemaFor(type).listSection('discipline').suggestions;
        for (final clan in clanRulesFor(type)) {
          for (final discipline in clan.disciplines) {
            expect(
              known,
              contains(discipline),
              reason: '${clan.name} (${type.id}): $discipline fuori elenco',
            );
          }
        }
      }
    });

    test('ogni clan con Discipline ne ha esattamente tre', () {
      for (final type in SheetType.values) {
        for (final clan in clanRulesFor(type)) {
          if (clan.disciplines.isEmpty) continue;
          expect(clan.disciplines.length, 3, reason: '${clan.name} ${type.id}');
        }
      }
    });

    test('nessuna debolezza è lasciata vuota', () {
      for (final type in SheetType.values) {
        for (final clan in clanRulesFor(type)) {
          expect(clan.weakness.trim(), isNotEmpty, reason: clan.name);
        }
      }
    });

    test('la scheda ha davvero il campo dove scriviamo la debolezza', () {
      for (final type in SheetType.values) {
        final schema = schemaFor(type);
        final key = schema.clanWeaknessKey;
        expect(key, isNotNull, reason: type.id);
        expect(schema.hasText(key!), isTrue, reason: '${type.id}: $key');
      }
    });
  });

  group('Lo stesso clan cambia da un\'edizione all\'altra', () {
    test('i Gangrel usano il nome della Disciplina della loro scheda', () {
      // la 5a edizione italiana dice "Proteide", la 20a "Protean"
      expect(clanRule(SheetType.v5, 'Gangrel')!.disciplines, [
        'Animalità',
        'Robustezza',
        'Proteide',
      ]);
      expect(clanRule(SheetType.v20, 'Gangrel')!.disciplines, [
        'Animalismo',
        'Robustezza',
        'Protean',
      ]);
    });

    test('i Tremere hanno debolezze diverse nelle tre edizioni', () {
      final v5 = clanRule(SheetType.v5, 'Tremere')!.weakness;
      final v20 = clanRule(SheetType.v20, 'Tremere')!.weakness;
      final darkAges = clanRule(SheetType.darkAges, 'Tremere')!.weakness;
      // nella 5a il loro sangue non vincola piu'; prima vincolava anche troppo
      expect(v5, contains('non vincola'));
      expect(v20, contains('due sorsi'));
      expect(darkAges, contains('usurpatori'));
    });

    test('i clan esistono solo nell\'edizione che li ha', () {
      expect(clanRule(SheetType.darkAges, 'Cappadoci'), isNotNull);
      expect(clanRule(SheetType.v20, 'Cappadoci'), isNull);
      expect(clanRule(SheetType.v20, 'Giovanni'), isNotNull);
      expect(clanRule(SheetType.darkAges, 'Giovanni'), isNull);
      expect(clanRule(SheetType.v5, 'Sangue Debole'), isNotNull);
    });

    test('un clan inventato non precompila niente', () {
      expect(clanRule(SheetType.v20, 'Pinco Pallino'), isNull);
      expect(clanRule(SheetType.v20, ''), isNull);
      expect(clanRule(SheetType.v20, null), isNull);
    });

    test('il nome si riconosce anche scritto storto', () {
      expect(clanRule(SheetType.v20, ' toreador ')!.name, 'Toreador');
    });
  });

  group('Cosa succede alla scheda quando si sceglie il clan', () {
    test('discipline e debolezza finiscono al loro posto', () {
      final character = Character(id: 'x', type: SheetType.v20);
      final schema = schemaFor(SheetType.v20);
      final filled = applyClanTemplate(
        character,
        schema,
        clanRule(SheetType.v20, 'Tremere')!,
      );

      expect(character.list('discipline').map((e) => e.name).take(3), [
        'Auspex',
        'Dominazione',
        'Taumaturgia',
      ]);
      expect(character.text('debolezza'), contains('due sorsi'));
      expect(filled.disciplines.length, 3);
      expect(filled.weaknessWritten, isTrue);
      expect(filled.message, contains('Taumaturgia'));
    });

    test('la 5a edizione scrive nel suo riquadro apposito', () {
      final character = Character(id: 'x', type: SheetType.v5);
      applyClanTemplate(
        character,
        schemaFor(SheetType.v5),
        clanRule(SheetType.v5, 'Nosferatu')!,
      );
      expect(character.text('debolezza_clan'), contains('Mostruosi'));
      expect(character.text('debolezza'), isEmpty);
    });

    test('quello che c\'era già non viene toccato', () {
      final character = Character(id: 'x', type: SheetType.v20);
      final schema = schemaFor(SheetType.v20);
      final entries = character.list('discipline');
      entries.add(TraitEntry(name: 'Auspex', value: 4));
      entries.add(TraitEntry(name: 'Necromanzia', value: 2));

      applyClanTemplate(character, schema, clanRule(SheetType.v20, 'Tremere')!);

      // Auspex era già lì con i suoi pallini: resta dov'è, non si duplica
      expect(entries.where((e) => e.name == 'Auspex').length, 1);
      expect(entries.firstWhere((e) => e.name == 'Auspex').value, 4);
      expect(entries.map((e) => e.name), containsAll(['Necromanzia']));
      expect(
        entries.map((e) => e.name),
        containsAll(['Dominazione', 'Taumaturgia']),
      );
    });

    test('le nuove Discipline entrano nelle righe rimaste vuote', () {
      final character = Character(id: 'x', type: SheetType.v20);
      final entries = character.list('discipline');
      for (var i = 0; i < 6; i++) {
        entries.add(TraitEntry());
      }
      applyClanTemplate(
        character,
        schemaFor(SheetType.v20),
        clanRule(SheetType.v20, 'Brujah')!,
      );

      expect(entries.length, 6, reason: 'non deve allungare la scheda');
      expect(entries.take(3).map((e) => e.name), [
        'Velocità',
        'Potenza',
        'Presenza',
      ]);
    });

    test('cambiando clan la debolezza scritta da noi viene sostituita', () {
      final character = Character(id: 'x', type: SheetType.v20);
      final schema = schemaFor(SheetType.v20);
      applyClanTemplate(character, schema, clanRule(SheetType.v20, 'Brujah')!);
      expect(character.text('debolezza'), contains('Sangue caldo'));

      applyClanTemplate(character, schema, clanRule(SheetType.v20, 'Ventrue')!);
      expect(character.text('debolezza'), contains('Palato esigente'));
      expect(character.text('debolezza'), isNot(contains('Sangue caldo')));
    });

    test('una debolezza scritta a mano non si tocca', () {
      final character = Character(id: 'x', type: SheetType.v20);
      character.texts['debolezza'] = 'Ha paura dei gatti neri.';
      final filled = applyClanTemplate(
        character,
        schemaFor(SheetType.v20),
        clanRule(SheetType.v20, 'Ventrue')!,
      );

      expect(character.text('debolezza'), 'Ha paura dei gatti neri.');
      expect(filled.weaknessWritten, isFalse);
      expect(filled.disciplines.length, 3);
      expect(filled.message, isNot(contains('debolezza')));
    });

    test('i Caitiff non hanno Discipline ma hanno una nota', () {
      final character = Character(id: 'x', type: SheetType.v20);
      final filled = applyClanTemplate(
        character,
        schemaFor(SheetType.v20),
        clanRule(SheetType.v20, 'Caitiff')!,
      );

      expect(character.list('discipline').every((e) => e.name.isEmpty), isTrue);
      expect(filled.disciplines, isEmpty);
      expect(character.text('debolezza'), contains('Senza clan'));
      expect(filled.message, contains('debolezza'));
    });
  });

  group('Archetipi di Natura e Carattere', () {
    test('le due schede che li hanno propongono la stessa lista', () {
      for (final type in [SheetType.v20, SheetType.darkAges]) {
        final identity = schemaFor(type).identity;
        for (final key in ['nature', 'demeanor']) {
          final field = identity.firstWhere((f) => f.key == key);
          expect(field.options, natureArchetypes, reason: '${type.id}.$key');
          expect(field.allowCustom, isTrue, reason: '${type.id}.$key');
        }
      }
    });

    test('la 5a edizione non li ha: al loro posto Ambizione e Desiderio', () {
      final keys = schemaFor(SheetType.v5).identity.map((f) => f.key);
      expect(keys, isNot(contains('nature')));
      expect(keys, containsAll(['ambition', 'desire']));
    });

    test('la lista è ordinata e senza doppioni', () {
      final sorted = [...natureArchetypes]..sort();
      expect(natureArchetypes, sorted);
      expect(natureArchetypes.toSet().length, natureArchetypes.length);
      expect(natureArchetypes.length, 30);
    });
  });
}
