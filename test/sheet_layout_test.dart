import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/main.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';
import 'package:vtm_companion/ui/characters/character_edit_page.dart';
import 'package:vtm_companion/ui/widgets/tracks.dart';

void main() {
  late Directory temp;
  late AppState state;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_layout');
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

  Future<void> unlock(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.lock_outline).last);
    await tester.pumpAndSettle();
  }

  /// Le caselle disegnate della riserva di sangue.
  Finder bloodBoxes() => find.descendant(
    of: find
        .ancestor(of: find.text('Punti Sangue'), matching: find.byType(Column))
        .first,
    matching: find.byType(TrackBox),
  );

  group('Barra di scorrimento', () {
    testWidgets('c\'è sulla scheda e nell\'editor', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      expect(find.byType(Scrollbar), findsWidgets);

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();
      expect(find.byType(CharacterEditPage), findsOneWidget);
      expect(find.byType(Scrollbar), findsWidgets);
    });
  });

  group('Punti sangue oltre la generazione', () {
    testWidgets('senza generazione si vedono tutte quelle della scheda', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      expect(bloodBoxes(), findsNWidgets(20));
    });

    testWidgets('la tredicesima generazione ne mostra dieci', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      character.texts['generation'] = 'XIII';
      await openSheet(tester, character);
      expect(bloodBoxes(), findsNWidgets(10));
    });

    testWidgets('la settima ne mostra venti, la quinta quaranta', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges20);
      character.texts['name'] = 'Ysabeau';
      character.texts['generation'] = 'VII';
      await openSheet(tester, character);
      // la scheda dei Secoli Bui ne stampa cinquanta
      expect(bloodBoxes(), findsNWidgets(20));

      character.texts['generation'] = 'V';
      await tester.tap(find.byIcon(Icons.lock_outline).last);
      await tester.pumpAndSettle();
      expect(bloodBoxes(), findsNWidgets(40));
    });

    testWidgets('le caselle segnate oltre il limite vengono segnalate', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      character.track('sangue', 20)[15] = 1;
      character.texts['generation'] = 'XIII';
      await openSheet(tester, character);

      expect(bloodBoxes(), findsNWidgets(10));
      expect(find.textContaining('oltre il limite'), findsOneWidget);
      // il dato non è stato cancellato: è solo fuori vista
      expect(character.track('sangue', 20)[15], 1);
    });
  });

  group('Sezioni apribili e chiudibili', () {
    testWidgets('toccando il titolo la sezione sparisce e torna', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      expect(find.text('Forza'), findsOneWidget);
      await tester.tap(find.text('ATTRIBUTI'));
      await tester.pumpAndSettle();
      expect(find.text('Forza'), findsNothing);

      await tester.tap(find.text('ATTRIBUTI'));
      await tester.pumpAndSettle();
      expect(find.text('Forza'), findsOneWidget);
    });

    testWidgets('la scheda si ricorda quali sezioni erano chiuse', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      await tester.tap(find.text('ATTRIBUTI'));
      await tester.pumpAndSettle();
      expect(character.isCollapsed('attributi'), isTrue);

      // chiusa e riaperta la scheda, resta chiusa
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lucrezia'));
      await tester.pumpAndSettle();
      expect(find.text('Forza'), findsNothing);
    });

    testWidgets('la scelta sopravvive al salvataggio su disco', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      await tester.tap(find.text('ATTRIBUTI'));
      await tester.pumpAndSettle();

      // scrittura e rilettura vere: dentro testWidgets il tempo è finto e
      // l'I/O su disco non arriverebbe mai a completarsi
      final reloaded = await tester.runAsync(() async {
        await state.characterRepository.save(character);
        return (await state.characterRepository.loadAll()).single;
      });
      expect(reloaded!.isCollapsed('attributi'), isTrue);
      expect(reloaded.isCollapsed('abilita'), isFalse);
    });

    testWidgets('chiudere nell\'editor chiude anche sulla scheda', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      // nell'editor il titolo sta sotto l'Identità, che ora ha anche la foto
      await tester.scrollUntilVisible(
        find.text('ATTRIBUTI'),
        250,
        // sotto c'è ancora la scheda: si scorre quella dell'editor
        scrollable: find
            .descendant(
              of: find.byType(CharacterEditPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ATTRIBUTI'));
      await tester.pumpAndSettle();
      expect(find.text('Forza'), findsNothing);

      await tester.tap(find.text('SALVA'));
      await tester.pumpAndSettle();
      expect(find.text('Forza'), findsNothing);
    });
  });

  group('Sezioni a elenco senza righe vuote', () {
    testWidgets('una scheda nuova non stampa righe in bianco', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);

      // prima si vedevano sette "Pregio" e sette "Difetto" vuoti
      expect(find.text('Pregio'), findsNothing);
      expect(find.text('Difetto'), findsNothing);
      expect(character.list('pregi'), isEmpty);
    });

    testWidgets('dalla scheda si aggiunge una voce e resta solo quella', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      await unlock(tester);

      // la prima sezione a elenco della scheda V20 è Discipline
      final add = find.text('aggiungi voce').first;
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ascendente');
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();

      expect(character.list('discipline').length, 1);
      expect(character.list('discipline').single.name, 'Ascendente');
      expect(find.text('Ascendente'), findsOneWidget);
    });

    testWidgets('annullando non nasce nessuna riga', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      await unlock(tester);

      final add = find.text('aggiungi voce').first;
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(character.list('discipline'), isEmpty);
    });

    testWidgets('a scheda bloccata non si aggiunge niente', (tester) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      await openSheet(tester, character);
      expect(find.text('aggiungi voce'), findsNothing);
    });

    testWidgets('le righe vuote delle vecchie schede spariscono', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.v20);
      character.texts['name'] = 'Lucrezia';
      // come le salvava la versione precedente: sette righe, una scritta
      final pregi = character.list('pregi');
      pregi.add(TraitEntry(name: 'Volontà di ferro'));
      for (var i = 0; i < 6; i++) {
        pregi.add(TraitEntry());
      }

      await openSheet(tester, character);
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      expect(character.list('pregi').length, 1);
      expect(character.list('pregi').single.name, 'Volontà di ferro');
    });
  });

  group('Scheda dei Secoli Bui di prima edizione', () {
    testWidgets('si disegna e si apre in modifica senza sfondare le righe', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges1);
      character.texts.addAll({
        'name': 'Corvino da Rialto',
        'clan': 'Cappadoci',
        'generation': 'VIII',
        'attivita_prec': 'Speziale',
      });
      character.dots['ab.erboristeria'] = 4;
      await openSheet(tester, character);

      // le abilità del 1996, non quelle del 20° Anniversario
      expect(find.text('Erboristeria'), findsOneWidget);
      expect(find.text('Muoversi Silenziosamente'), findsOneWidget);
      expect(find.text('Armi da Fuoco'), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();
      expect(find.byType(CharacterEditPage), findsOneWidget);
    });

    testWidgets('stampa venti caselle di sangue, non cinquanta', (
      tester,
    ) async {
      final character = state.createCharacter(SheetType.darkAges1);
      character.texts['name'] = 'Corvino da Rialto';
      await openSheet(tester, character);
      expect(bloodBoxes(), findsNWidgets(20));
    });

    testWidgets('si scorre fino in fondo senza incidenti', (tester) async {
      final character = state.createCharacter(SheetType.darkAges1);
      character.texts['name'] = 'Corvino da Rialto';
      await openSheet(tester, character);

      // scorrendo si costruiscono tutte le sezioni: un overflow in una
      // qualsiasi di esse farebbe fallire il test qui
      await tester.scrollUntilVisible(
        find.text('STORIA DEL PERSONAGGIO'),
        600,
        maxScrolls: 200,
      );
      await tester.pumpAndSettle();
      expect(find.text('STORIA DEL PERSONAGGIO'), findsOneWidget);
    });
  });
}
