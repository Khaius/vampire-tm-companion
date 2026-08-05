import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/data/schemas.dart';
import 'package:vtm_companion/models/sheet_type.dart';

void main() {
  group('Limiti dei pallini presi dalle schede originali', () {
    test('V5 e V20 arrivano a 5, I Secoli Bui a 9', () {
      expect(SheetType.v5.traitMax, 5);
      expect(SheetType.v20.traitMax, 5);
      expect(SheetType.darkAges.traitMax, 9);
    });

    test('Discipline e Background dei Secoli Bui arrivano a 9', () {
      final schema = schemaFor(SheetType.darkAges);
      expect(schema.listSection('discipline').dotMax, 9);
      expect(schema.listSection('background').dotMax, 9);
      expect(schema.listSection('altre').dotMax, 9);
      // le Vie restano a 5 pallini come sul PDF
      expect(schema.listSection('vie').dotMax, 5);
      expect(schema.virtueMax, 5);
    });
  });

  group('Struttura delle tre schede', () {
    test('ogni scheda ha nove attributi in tre gruppi', () {
      for (final type in SheetType.values) {
        final schema = schemaFor(type);
        expect(schema.attributes.length, 3, reason: type.id);
        expect(
          schema.attributes.expand((g) => g.traits).length,
          9,
          reason: type.id,
        );
      }
    });

    test('le abilità sono divise in tre colonne', () {
      for (final type in SheetType.values) {
        final schema = schemaFor(type);
        expect(schema.abilities.length, 3, reason: type.id);
        expect(schema.abilityColumnTitles.length, 3, reason: type.id);
      }
    });

    test('nessuna chiave duplicata fra tratti, liste e tracker', () {
      for (final type in SheetType.values) {
        final schema = schemaFor(type);
        final keys = <String>[
          ...schema.identity.map((f) => f.key),
          ...schema.attributes.expand((g) => g.traits).map((t) => t.key),
          ...schema.abilities.expand((g) => g.traits).map((t) => t.key),
          ...schema.virtues.map((t) => t.key),
          ...schema.lists.map((l) => l.key),
          ...schema.tracks.map((t) => t.key),
          ...schema.textSections.map((t) => t.key),
        ];
        expect(
          keys.toSet().length,
          keys.length,
          reason: 'chiavi duplicate in ${type.id}',
        );
      }
    });

    test('i tracker rispecchiano i valori stampati sulle schede', () {
      final v5 = schemaFor(SheetType.v5);
      expect(v5.track('salute').length, 15);
      expect(v5.track('volonta').length, 15);
      expect(v5.track('umanita').length, 10);
      expect(v5.track('fame').length, 5);
      expect(v5.track('potenza_sangue').length, 10);

      final v20 = schemaFor(SheetType.v20);
      expect(v20.track('salute').length, 7);
      expect(v20.track('salute').rowLabels.first, 'Contuso');
      expect(v20.track('salute').rowLabels.last, 'Inabilitato');
      expect(v20.track('sangue').length, 20);
      expect(v20.track('volonta').length, 10);

      final darkAges = schemaFor(SheetType.darkAges);
      expect(darkAges.track('sangue').length, 50);
      expect(darkAges.track('sentiero').length, 10);
      expect(darkAges.hasTrack('umanita'), isFalse);
    });

    test('le abilità V20 e Secoli Bui differiscono come sui PDF', () {
      final v20 = schemaFor(SheetType.v20)
          .abilities
          .expand((g) => g.traits)
          .map((t) => t.label)
          .toSet();
      final darkAges = schemaFor(SheetType.darkAges)
          .abilities
          .expand((g) => g.traits)
          .map((t) => t.label)
          .toSet();

      expect(v20, contains('Armi da Fuoco'));
      expect(v20, contains('Informatica'));
      expect(darkAges, contains('Cavalcare'));
      expect(darkAges, contains('Tiro con l\'Arco'));
      expect(darkAges, contains('Teologia'));
      expect(darkAges, isNot(contains('Armi da Fuoco')));
    });

    test('la scheda V5 usa Fame e Potenza del Sangue, non le Virtù', () {
      final v5 = schemaFor(SheetType.v5);
      expect(v5.virtues, isEmpty);
      expect(v5.hasTrack('fame'), isTrue);
      expect(
        v5.identity.map((f) => f.key),
        containsAll(<String>['ambition', 'desire', 'predator']),
      );
      expect(v5.listSection('discipline').lineSlots, 5);
    });
  });
}
