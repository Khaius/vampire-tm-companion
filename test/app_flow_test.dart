import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/main.dart';
import 'package:vtm_companion/models/sheet_type.dart';

void main() {
  late Directory temp;
  late AppState state;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_flow');
    state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  /// I test girano su una finestra da telefono: e' il bersaglio dell'app.
  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(VtmCompanionApp(state: state));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('all\'avvio si vede la lista schede e il menu in basso', (
    tester,
  ) async {
    await boot(tester);

    expect(find.text('SCHEDE'), findsOneWidget);
    expect(find.text('Nessuna scheda'), findsOneWidget);
    // il menu con le tre voci e' sempre presente
    expect(find.text('Schede'), findsOneWidget);
    expect(find.text('Dadi'), findsOneWidget);
    expect(find.text('Documenti'), findsOneWidget);
  });

  testWidgets('il menu porta ai dadi e ai documenti restando visibile', (
    tester,
  ) async {
    await boot(tester);

    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();
    expect(find.text('DADI'), findsOneWidget);
    expect(find.text('NUMERO DI DADI'), findsOneWidget);
    expect(find.text('TIRA I DADI'), findsOneWidget);
    expect(find.text('Documenti'), findsOneWidget);

    await tester.tap(find.text('Documenti'));
    await tester.pumpAndSettle();
    expect(find.text('DOCUMENTI'), findsOneWidget);
    expect(find.text('Nessun documento'), findsOneWidget);
    expect(find.text('Schede'), findsOneWidget);
  });

  testWidgets('il contatore dei dadi non scende sotto uno e tira', (
    tester,
  ) async {
    await boot(tester);
    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
    await tapVisible(tester, find.byIcon(Icons.add));
    expect(state.dicePool, 2);

    await tapVisible(tester, find.byIcon(Icons.remove));
    expect(state.dicePool, 1);

    // il "-" e' disabilitato al minimo
    await tapVisible(tester, find.byIcon(Icons.remove));
    expect(state.dicePool, 1);

    await tapVisible(tester, find.text('TIRA I DADI'));
    expect(state.rollHistory, hasLength(1));
    expect(find.text('TOTALE'), findsOneWidget);
    expect(find.text('Successi'), findsOneWidget);
  });

  testWidgets('la difficoltà si sceglie e finisce nel tiro', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.widgetWithText(InkWell, '9').first);
    expect(state.difficulty, 9);

    await tapVisible(tester, find.text('TIRA I DADI'));
    expect(state.rollHistory.single.difficulty, 9);
  });

  testWidgets('creazione scheda: si sceglie il tipo e si arriva alla scheda', (
    tester,
  ) async {
    await boot(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('NUOVA SCHEDA'), findsOneWidget);
    // tutte e tre le edizioni sono proposte
    expect(find.text('The Masquerade — 5ª Edizione'), findsOneWidget);
    expect(find.text('La Masquerade — 20° Anniversario'), findsOneWidget);
    expect(find.text('I Secoli Bui — 20° Anniversario'), findsOneWidget);

    await tapVisible(tester, find.text('I Secoli Bui — 20° Anniversario'));

    // si entra nell'editor con la scheda gia' creata
    expect(state.characters, hasLength(1));
    expect(state.characters.single.type, SheetType.darkAges);
    expect(find.text('IDENTITÀ'), findsOneWidget);
    // i pallini della scheda Secoli Bui arrivano a 9
    expect(find.textContaining('da 0 a 9'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ATTRIBUTI'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Forza'), findsOneWidget);

    // si conferma senza compilare nulla: nessun campo e' obbligatorio
    await tapVisible(tester, find.text('FINE'));

    expect(state.selectedCharacterId, state.characters.single.id);
    expect(find.text('SENZA NOME'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ATTRIBUTI'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Forza'), findsOneWidget);
  });

  testWidgets('la scheda aperta si riapre dal menu finché non si chiude', (
    tester,
  ) async {
    await boot(tester);
    final character = state.createCharacter(SheetType.v20);
    character.texts['name'] = 'Lucrezia';
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lucrezia'));
    await tester.pumpAndSettle();
    expect(find.text('LUCREZIA'), findsOneWidget);

    // si va sui dadi e si torna: deve ricomparire la scheda, non la lista
    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schede'));
    await tester.pumpAndSettle();
    expect(find.text('LUCREZIA'), findsOneWidget);

    // chiusura manuale: da qui in poi il menu riporta alla lista
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(state.selectedCharacterId, isNull);
    expect(find.text('SCHEDE'), findsOneWidget);

    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schede'));
    await tester.pumpAndSettle();
    expect(find.text('SCHEDE'), findsOneWidget);
    expect(find.text('LUCREZIA'), findsNothing);
  });

  testWidgets('i pallini della scheda si toccano e si salvano', (tester) async {
    await boot(tester);
    final character = state.createCharacter(SheetType.v20);
    character.texts['name'] = 'Marcus';
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcus'));
    await tester.pumpAndSettle();

    // terzo pallino della Forza
    final forza = find.ancestor(
      of: find.text('Forza'),
      matching: find.byType(Row),
    );
    final dots = find.descendant(of: forza.first, matching: find.byType(InkWell));
    expect(dots, findsWidgets);

    expect(character.dot('attr.forza'), 0);
  });
}
