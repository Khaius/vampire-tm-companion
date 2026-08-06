import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/data/schemas.dart';
import 'package:vtm_companion/models/sheet_type.dart';

void main() {
  group('Limiti dei pallini presi dalle schede originali', () {
    test('V5 e V20 arrivano a 5, I Secoli Bui a 9', () {
      expect(SheetType.v5.traitMax, 5);
      expect(SheetType.v20.traitMax, 5);
      expect(SheetType.darkAges20.traitMax, 9);
    });

    test('Discipline e Background dei Secoli Bui arrivano a 9', () {
      final schema = schemaFor(SheetType.darkAges20);
      expect(schema.listSection('discipline').dotMax, 9);
      expect(schema.listSection('background').dotMax, 9);
      expect(schema.listSection('altre').dotMax, 9);
      // le Vie restano a 5 pallini come sul PDF
      expect(schema.listSection('vie').dotMax, 5);
      expect(schema.virtueMax, 5);
    });

    test('anche I Secoli Bui di prima edizione arrivano a 9', () {
      expect(SheetType.darkAges1.traitMax, 9);
      final schema = schemaFor(SheetType.darkAges1);
      expect(schema.listSection('discipline').dotMax, 9);
      expect(schema.listSection('background').dotMax, 9);
      expect(schema.listSection('altre').dotMax, 9);
      expect(schema.virtueMax, 9);
    });
  });

  group('Le due schede dei Secoli Bui', () {
    test('sono edizioni distinte, con id diversi e cornice medievale', () {
      expect(SheetType.darkAges20.id, 'dark_ages');
      expect(SheetType.darkAges1.id, 'dark_ages_1');
      expect(SheetType.darkAges20.isDarkAges, isTrue);
      expect(SheetType.darkAges1.isDarkAges, isTrue);
      expect(SheetType.v20.isDarkAges, isFalse);
      // il numero di edizione compare sia nel sottotitolo sia nella sigla
      expect(SheetType.darkAges20.subtitle, contains('20°'));
      expect(SheetType.darkAges1.subtitle, contains('1ª'));
      expect(
        SheetType.darkAges1.badge,
        isNot(SheetType.darkAges20.badge),
        reason: 'le due sigle si devono poter distinguere nella lista',
      );
    });

    test('la prima edizione ha le abilità del 1996 e non quelle moderne', () {
      final labels = schemaFor(
        SheetType.darkAges1,
      ).abilities.expand((g) => g.traits).map((t) => t.label).toSet();

      expect(
        labels,
        containsAll(<String>[
          'Recitazione',
          'Schivare',
          'Erboristeria',
          'Musica',
          'Muoversi Silenziosamente',
          'Lingue',
          'Scienza',
          'Governo Domestico',
          'Saggezza Popolare',
        ]),
      );
      // le abilità moderne della scheda 20° qui non ci sono
      expect(
        labels.intersection(<String>{
          'Armi da Fuoco',
          'Informatica',
          'Guidare',
          'Tecnologia',
        }),
        isEmpty,
      );
      // dieci per colonna, come sono stampate
      for (final group in schemaFor(SheetType.darkAges1).abilities) {
        expect(group.traits.length, 10, reason: group.key);
      }
    });

    test('le abilità equivalenti condividono la chiave con la scheda 20°', () {
      Map<String, String> keysByLabel(SheetType type) => {
        for (final trait in schemaFor(type).abilities.expand((g) => g.traits))
          trait.label: trait.key,
      };
      final vecchia = keysByLabel(SheetType.darkAges20);
      final prima = keysByLabel(SheetType.darkAges1);

      // stessa abilità, nome italiano diverso fra le due edizioni
      const equivalenze = <String, String>{
        'Doti di Comando': 'Autorità',
        'Recitazione': 'Espressività',
        'Addestrare Animali': 'Affinità Animale',
        'Mestiere': 'Manualità',
        'Mischia': 'Armi da Mischia',
        'Muoversi Silenziosamente': 'Furtività',
        'Scienza': 'Scienze',
      };
      for (final entry in equivalenze.entries) {
        expect(
          prima[entry.key],
          vecchia[entry.value],
          reason: 'chiave diversa per ${entry.key}',
        );
      }
      // e quelle che si chiamano uguale usano ovviamente la stessa chiave
      for (final entry in prima.entries) {
        if (!vecchia.containsKey(entry.key)) continue;
        expect(
          entry.value,
          vecchia[entry.key],
          reason: 'chiave diversa per ${entry.key}',
        );
      }
    });

    test('i tracker della prima edizione sono quelli stampati', () {
      final schema = schemaFor(SheetType.darkAges1);
      expect(schema.track('sangue').length, 20);
      expect(schema.track('sentiero').length, 10);
      expect(schema.track('volonta').length, 10);
      expect(schema.track('salute').length, 7);
      expect(schema.track('salute').rowLabels.first, 'Contusione');
      expect(schema.track('salute').rowLabels.last, 'Ferita Incapacitante');
      expect(schema.hasTrack('umanita'), isFalse);
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

      final darkAges = schemaFor(SheetType.darkAges20);
      expect(darkAges.track('sangue').length, 50);
      expect(darkAges.track('sentiero').length, 10);
      expect(darkAges.hasTrack('umanita'), isFalse);
    });

    test(
      'i Secoli Bui tengono le proprie abilità e hanno anche le moderne',
      () {
        final v20 = schemaFor(
          SheetType.v20,
        ).abilities.expand((g) => g.traits).map((t) => t.label).toSet();
        final darkAges = schemaFor(
          SheetType.darkAges20,
        ).abilities.expand((g) => g.traits).map((t) => t.label).toSet();

        // le abilità d'epoca restano solo sulla scheda dei Secoli Bui
        expect(darkAges, containsAll(<String>['Cavalcare', 'Teologia']));
        expect(darkAges, contains('Tiro con l\'Arco'));
        expect(v20, isNot(contains('Cavalcare')));

        // ...e le moderne ci sono tutte, per le cronache che attraversano
        // i secoli fino a oggi
        expect(darkAges, containsAll(v20), reason: 'manca un\'abilità moderna');
      },
    );

    test('le abilità in comune usano la stessa chiave nelle due schede', () {
      Map<String, String> keysByLabel(SheetType type) => {
        for (final trait in schemaFor(type).abilities.expand((g) => g.traits))
          trait.label: trait.key,
      };
      final v20 = keysByLabel(SheetType.v20);
      final darkAges = keysByLabel(SheetType.darkAges20);
      for (final entry in v20.entries) {
        expect(
          darkAges[entry.key],
          entry.value,
          reason: 'chiave diversa per ${entry.key}',
        );
      }
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
