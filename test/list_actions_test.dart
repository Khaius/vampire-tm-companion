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
    temp = await Directory.systemTemp.createTemp('vtm_list');
    state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<void> boot(WidgetTester tester, {int schede = 2}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    for (var i = 0; i < schede; i++) {
      state.createCharacter(SheetType.v20).texts['name'] = 'Scheda ${i + 1}';
    }
    await tester.pumpWidget(VtmCompanionApp(state: state));
    await tester.pumpAndSettle();
  }

  /// Apre il menu a tre pallini della barra in alto.
  ///
  /// Non basta il primo che si trova: anche ogni scheda della lista ha il
  /// suo (modifica, duplica, elimina).
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Il menu delle azioni', () {
    testWidgets('ha creazione, importazione ed esportazione', (tester) async {
      await boot(tester);
      // il pulsante tondo "+" non c'è più: le azioni stanno nel menu
      expect(find.byType(FloatingActionButton), findsNothing);

      await openMenu(tester);
      expect(find.text('Nuova scheda'), findsOneWidget);
      expect(find.text('Importa'), findsOneWidget);
      expect(find.text('Esporta'), findsOneWidget);
    });

    testWidgets('la creazione è quella di prima, solo spostata', (
      tester,
    ) async {
      await boot(tester, schede: 0);
      await openMenu(tester);
      await tester.tap(find.text('Nuova scheda'));
      await tester.pumpAndSettle();
      expect(find.text('NUOVA SCHEDA'), findsOneWidget);
      expect(find.text('I Secoli Bui — 20° Anniversario'), findsOneWidget);
    });

    testWidgets('senza schede non si esporta niente', (tester) async {
      await boot(tester, schede: 0);
      await openMenu(tester);
      await tester.tap(find.text('Esporta'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('nessuna scheda da esportare'),
        findsOneWidget,
      );
      expect(find.text('ESPORTA'), findsNothing);
    });
  });

  group('La selezione per esportare', () {
    Future<void> enterExport(WidgetTester tester) async {
      await openMenu(tester);
      await tester.tap(find.text('Esporta'));
      await tester.pumpAndSettle();
    }

    testWidgets('compaiono i quadratini e la barra in basso', (tester) async {
      await boot(tester);
      await enterExport(tester);

      expect(find.text('ESPORTA'), findsOneWidget);
      expect(find.text('Seleziona tutto'), findsOneWidget);
      // un quadratino per ogni scheda, tutti vuoti
      expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(3));
      expect(find.byIcon(Icons.check_box), findsNothing);
    });

    testWidgets('toccando una scheda la si spunta invece di aprirla', (
      tester,
    ) async {
      await boot(tester);
      await enterExport(tester);

      await tester.tap(find.text('Scheda 1'));
      await tester.pumpAndSettle();

      // non si è aperta la scheda: siamo ancora nella lista
      expect(find.text('ESPORTA'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.text('Esporta (1)'), findsOneWidget);
    });

    testWidgets('"seleziona tutto" spunta e poi svuota', (tester) async {
      await boot(tester, schede: 3);
      await enterExport(tester);

      await tester.tap(find.text('Seleziona tutto'));
      await tester.pumpAndSettle();
      // le tre schede più il quadratino della barra
      expect(find.byIcon(Icons.check_box), findsNWidgets(4));
      expect(find.text('Esporta (3)'), findsOneWidget);

      await tester.tap(find.text('Deseleziona tutto'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_box), findsNothing);
      expect(find.text('Esporta'), findsOneWidget);
    });

    testWidgets('la X in alto esce dalla selezione', (tester) async {
      await boot(tester);
      await enterExport(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('SCHEDE'), findsOneWidget);
      expect(find.text('Seleziona tutto'), findsNothing);
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    });
  });
}
