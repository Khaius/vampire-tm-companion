import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/main.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';
import 'package:vtm_companion/ui/widgets/dots.dart';

void main() {
  late Directory temp;
  late AppState state;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_features');
    state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<void> openSheet(WidgetTester tester, Character character) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(VtmCompanionApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text(character.displayName));
    await tester.pumpAndSettle();
  }

  /// I pallini di un tratto, in ordine.
  ///
  /// Il nome sta in una Row interna (nome + specializzazione), i pallini in
  /// quella esterna: si sale di un livello e si guarda dentro il DotRow, per
  /// non raccogliere anche i gesti del nome e della specializzazione.
  Finder dotsOf(String trait) => find.descendant(
    of: find.descendant(
      of: find.ancestor(of: find.text(trait), matching: find.byType(Row)).at(1),
      matching: find.byType(DotRow),
    ),
    matching: find.byType(GestureDetector),
  );

  /// Il campo di una riga "Etichetta: valore" della scheda.
  Finder fieldOf(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
    matching: find.byType(InkWell),
  );

  group('Blocco delle modifiche', () {
    testWidgets('la scheda si apre bloccata e il tocco non la cambia', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      expect(find.text('Modifiche bloccate'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);

      // terzo pallino della Forza: da bloccata non deve succedere nulla
      await tester.tap(dotsOf('Forza').at(2));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 0);
    });

    testWidgets('sbloccando, lo stesso tocco assegna il valore', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Modifiche attive'), findsOneWidget);

      await tester.tap(dotsOf('Forza').at(2));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 3);
    });

    testWidgets('si puo'
        ' richiudere il lucchetto', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_open).last);
      await tester.pumpAndSettle();

      expect(find.text('Modifiche bloccate'), findsOneWidget);
      await tester.tap(dotsOf('Forza').at(2));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 0);
    });
  });

  group('Limite dei pallini per generazione', () {
    testWidgets('sui Secoli Bui la settima generazione ferma i dadi al sesto', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges);
      character.texts['name'] = 'Ysabeau';
      character.texts['generation'] = 'VII'; // massimo 6
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      // la scheda stampa nove pallini
      expect(dotsOf('Forza'), findsNWidgets(9));

      // il sesto e' ancora utilizzabile
      await tester.tap(dotsOf('Forza').at(5));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 6);

      // il settimo non risponde: resta il valore precedente
      await tester.tap(dotsOf('Forza').at(6), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 6);
    });

    testWidgets('la dodicesima generazione ferma i dadi al quinto', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges);
      character.texts['name'] = 'Ysabeau';
      character.texts['generation'] = 'XII'; // massimo 5
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(dotsOf('Forza').at(4));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 5);

      await tester.tap(dotsOf('Forza').at(5), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 5);
    });

    testWidgets('senza generazione indicata vale quanto stampa la scheda', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges);
      character.texts['name'] = 'Ysabeau';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(dotsOf('Forza').at(8));
      await tester.pumpAndSettle();
      expect(character.dot('attr.forza'), 9);
    });
  });

  /// Sceglie una voce dal menu di un campo, scorrendo se serve.
  Future<void> pickOption(WidgetTester tester, String option) async {
    final item = find.text(option).last;
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  group('Clan che precompila la scheda', () {
    testWidgets('scegliendo il clan arrivano Discipline e debolezza', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(fieldOf('Clan:').first);
      await tester.pumpAndSettle();
      await pickOption(tester, 'Tremere');

      expect(character.text('clan'), 'Tremere');
      expect(character.list('discipline').map((e) => e.name), containsAll([
        'Auspex',
        'Dominazione',
        'Taumaturgia',
      ]));
      expect(character.text('debolezza'), contains('due sorsi'));
      // e si vedono sulla scheda, non solo nei dati
      expect(find.text('Taumaturgia'), findsWidgets);
    });

    testWidgets('dal menu si può anche scriversi un clan proprio', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges);
      character.texts['name'] = 'Ysabeau';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(fieldOf('Clan:').first);
      await tester.pumpAndSettle();
      await pickOption(tester, 'Altro...');

      await tester.enterText(find.byType(TextField), 'Gargoyle');
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();

      expect(character.text('clan'), 'Gargoyle');
      // un clan fuori elenco non precompila niente: non sappiamo cosa sia
      expect(character.list('discipline').every((e) => e.name.isEmpty), isTrue);
      expect(character.text('debolezza'), isEmpty);
    });
  });

  group('Natura e Carattere fra gli archetipi', () {
    testWidgets('la Natura si sceglie dall\'elenco', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(fieldOf('Natura:').first);
      await tester.pumpAndSettle();

      expect(find.text('Architetto'), findsOneWidget);
      expect(find.text('Visionario'), findsOneWidget);
      await pickOption(tester, 'Architetto');

      expect(character.text('nature'), 'Architetto');
    });
  });

  group('Generazione a scelta chiusa', () {
    testWidgets('la si sceglie fra i numeri romani', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();

      await tester.tap(fieldOf('Generazione:').first);
      await tester.pumpAndSettle();

      // il menu propone i romani, non un campo libero
      expect(find.text('II'), findsOneWidget);
      expect(find.text('XIII'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('XIII'));
      await tester.pumpAndSettle();
      expect(character.text('generation'), 'XIII');
    });
  });
}
