@Tags(['golden'])
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/core/app_state.dart';
import 'package:vtm_companion/data/character_repository.dart';
import 'package:vtm_companion/data/document_repository.dart';
import 'package:vtm_companion/main.dart';
import 'package:vtm_companion/models/dice.dart';
import 'package:vtm_companion/models/character.dart';
import 'package:vtm_companion/models/sheet_type.dart';

/// Carica i font veri dell'app: senza, i golden mostrerebbero rettangoli.
Future<void> _loadFonts() async {
  const fonts = {
    'Cinzel': [
      'assets/fonts/Cinzel-Regular.ttf',
      'assets/fonts/Cinzel-Bold.ttf',
    ],
    'EBGaramond': [
      'assets/fonts/EBGaramond-Regular.ttf',
      'assets/fonts/EBGaramond-SemiBold.ttf',
      'assets/fonts/EBGaramond-Italic.ttf',
    ],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }

  // Le icone Material vivono nell'SDK, non fra gli asset dell'app: senza
  // questo passaggio i golden mostrerebbero quadratini al loro posto.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final iconFont = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(iconFont.readAsBytes().then((b) => ByteData.view(b.buffer)));
      await loader.load();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late AppState state;

  setUpAll(_loadFonts);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('vtm_golden');
    state = AppState(
      characterRepository: CharacterRepository(overrideDir: temp),
      documentRepository: DocumentRepository(overrideDir: temp),
    );
    await state.init();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Character seedV20() {
    final character = state.createCharacter(SheetType.v20);
    character.texts.addAll({
      'name': 'Lucrezia Baldi',
      'player': 'Cristiano',
      'chronicle': 'Roma di Notte',
      'clan': 'Toreador',
      'generation': 'XIII',
      'nature': 'Artista',
      'demeanor': 'Seduttrice',
      'concept': 'Gallerista',
      'sire': 'Ottavia',
      'spec.ab.espressivita': 'Pittura',
      'debolezza': 'Deve superare Autocontrollo davanti alla vera bellezza.',
    });
    character.dots.addAll({
      'attr.forza': 2,
      'attr.destrezza': 3,
      'attr.costituzione': 2,
      'attr.carisma': 4,
      'attr.persuasione': 3,
      'attr.aspetto': 4,
      'attr.percezione': 3,
      'attr.intelligenza': 3,
      'attr.prontezza': 2,
      'ab.espressivita': 3,
      'ab.empatia': 2,
      'ab.autorita': 3,
      'virtu.coscienza': 3,
      'virtu.autocontrollo': 4,
      'virtu.coraggio': 3,
      'volonta': 6,
      'umanita': 7,
    });
    character.list('discipline').addAll([
      TraitEntry(name: 'Ascendente', value: 3),
      TraitEntry(name: 'Auspex', value: 2),
    ]);
    character.list('background').addAll([
      TraitEntry(name: 'Risorse', value: 3),
      TraitEntry(name: 'Contatti', value: 2),
    ]);
    character.track('salute', 7)[0] = 1;
    character.track('salute', 7)[1] = 2;
    for (var i = 0; i < 4; i++) {
      character.track('sangue', 20)[i] = 1;
    }
    return character;
  }

  Future<void> boot(WidgetTester tester) async {
    // 412x900 logici (un telefono comune) a 2x: golden leggibili senza
    // appesantire il repository.
    tester.view.physicalSize = const Size(824, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(VtmCompanionApp(state: state));
    await tester.pumpAndSettle();
  }

  testWidgets('lista schede', (tester) async {
    seedV20();
    final darkAges = state.createCharacter(SheetType.darkAges);
    darkAges.texts.addAll({
      'name': 'Ysabeau d\'Aquitania',
      'clan': 'Cappadoci',
    });
    final v5 = state.createCharacter(SheetType.v5);
    v5.texts.addAll({'name': 'Dante Ferrara', 'clan': 'Brujah'});

    await boot(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_lista_schede.png'),
    );
  });

  testWidgets('scelta del tipo di scheda', (tester) async {
    await boot(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_nuova_scheda.png'),
    );
  });

  testWidgets('scheda renderizzata V20', (tester) async {
    final character = seedV20();
    await boot(tester);
    await tester.tap(find.text(character.displayName));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03_scheda_v20_testa.png'),
    );

    // stessa testata a modifiche sbloccate
    await tester.tap(find.byIcon(Icons.lock_outline).last);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/12_scheda_sbloccata.png'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/04_scheda_v20_abilita.png'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/05_scheda_v20_vantaggi.png'),
    );
  });

  testWidgets('editor della scheda', (tester) async {
    final character = seedV20();
    await boot(tester);
    await tester.tap(find.text(character.displayName));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06_editor_attributi.png'),
    );
  });

  testWidgets('dadi con risultato', (tester) async {
    // seme fisso: il golden deve mostrare sempre lo stesso tiro
    DiceRoll.random = Random(1988);
    addTearDown(() => DiceRoll.random = Random.secure());
    await boot(tester);
    await tester.tap(find.text('Dadi'));
    await tester.pumpAndSettle();
    state.setDicePool(5);
    state.setDifficulty(7);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07_dadi.png'),
    );

    await tester.ensureVisible(find.text('TIRA I DADI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TIRA I DADI'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/08_dadi_risultato.png'),
    );
  });

  testWidgets('scheda Secoli Bui con i nove pallini', (tester) async {
    final character = state.createCharacter(SheetType.darkAges);
    character.texts.addAll({
      'name': 'Ysabeau d\'Aquitania',
      'clan': 'Cappadoci',
      'generation': 'V',
      'concept': 'Monaca erudita',
      'chronicle': 'Le Notti di Provenza',
    });
    character.dots.addAll({
      'attr.forza': 6,
      'attr.destrezza': 4,
      'attr.costituzione': 5,
      'attr.carisma': 3,
      'attr.persuasione': 5,
      'attr.aspetto': 4,
      'attr.percezione': 7,
      'attr.intelligenza': 8,
      'attr.prontezza': 5,
    });

    await boot(tester);
    await tester.tap(find.text(character.displayName));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -560));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/10_scheda_secoli_bui.png'),
    );
  });

  testWidgets('tracker della scheda V5', (tester) async {
    final character = state.createCharacter(SheetType.v5);
    character.texts.addAll({
      'name': 'Dante Ferrara',
      'clan': 'Brujah',
      'ambition': 'Rovesciare il Principe',
      'predator': 'Randagio',
    });
    character.dots.addAll({'fame': 3, 'potenza_sangue': 2});
    character.track('salute', 15)[0] = 1;
    character.track('salute', 15)[1] = 1;
    character.track('salute', 15)[2] = 2;
    character.track('volonta', 15)[0] = 1;
    for (var i = 0; i < 7; i++) {
      character.track('umanita', 10)[i] = 1;
    }
    character.track('umanita', 10)[7] = 2;

    await boot(tester);
    await tester.tap(find.text(character.displayName));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -4200));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/11_tracker_v5.png'),
    );
  });

  testWidgets('libreria documenti vuota', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Documenti'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/09_documenti.png'),
    );
  });
}
