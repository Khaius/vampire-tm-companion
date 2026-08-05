import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/data/generations.dart';

void main() {
  group('Tabella delle generazioni', () {
    test('il menu propone i numeri romani dalla II alla XV', () {
      expect(generationRomanOptions.first, 'II');
      expect(generationRomanOptions.last, 'XV');
      expect(generationRomanOptions.length, 14);
      // il menu e la tabella non devono poter divergere
      expect(
        generationRomanOptions,
        generationRules.map((g) => g.roman).toList(),
      );
      expect(
        generationRules.map((g) => g.generation).toList(),
        List.generate(14, (i) => i + 2),
      );
    });

    test('i massimi dei tratti seguono le regole', () {
      int maxOf(String roman) => generationFromText(roman)!.traitMax;
      // gli esempi citati nella richiesta
      expect(maxOf('VII'), 6);
      expect(maxOf('XII'), 5);
      // il resto della progressione verso Caino
      expect(maxOf('VI'), 7);
      expect(maxOf('V'), 8);
      expect(maxOf('IV'), 9);
      expect(maxOf('III'), 10);
      // dall'ottava in giu' il massimo resta cinque
      for (final roman in ['VIII', 'IX', 'X', 'XI', 'XIII', 'XIV', 'XV']) {
        expect(maxOf(roman), 5, reason: roman);
      }
    });

    test('la riserva di sangue segue le regole', () {
      int poolOf(String roman) => generationFromText(roman)!.bloodPool;
      expect(poolOf('XIII'), 10);
      expect(poolOf('XII'), 11);
      expect(poolOf('XI'), 12);
      expect(poolOf('X'), 13);
      expect(poolOf('IX'), 14);
      expect(poolOf('VIII'), 15);
      expect(poolOf('VII'), 20);
      expect(poolOf('VI'), 30);
      expect(poolOf('V'), 40);
      expect(poolOf('IV'), 50);
    });

    test('il sangue spendibile per turno segue le regole', () {
      int turnOf(String roman) => generationFromText(roman)!.bloodPerTurn;
      expect(turnOf('XIII'), 1);
      expect(turnOf('X'), 1);
      expect(turnOf('IX'), 2);
      expect(turnOf('VIII'), 3);
      expect(turnOf('VII'), 5);
      expect(turnOf('VI'), 6);
      expect(turnOf('V'), 8);
      expect(turnOf('IV'), 10);
    });
  });

  group('Lettura del campo Generazione', () {
    test('riconosce i numeri romani del menu', () {
      expect(generationFromText('XIII')!.generation, 13);
      expect(generationFromText('vii')!.generation, 7);
    });

    test('riconosce anche le scritture precedenti a mano', () {
      expect(generationFromText('13')!.generation, 13);
      expect(generationFromText('10ª')!.generation, 10);
      expect(generationFromText(' 8 ')!.generation, 8);
    });

    test('su un valore incomprensibile non impone alcun limite', () {
      for (final value in ['', '   ', 'boh', null, 'ventesima', '99']) {
        expect(generationFromText(value), isNull, reason: '$value');
      }
    });
  });

  group('Massimo effettivo di un tratto', () {
    test('vince il piu'
        ' basso fra scheda e generazione', () {
      final settima = generationFromText('VII'); // massimo 6
      // scheda dei Secoli Bui: nove pallini stampati, sei utilizzabili
      expect(effectiveTraitMax(9, settima), 6);
      // scheda V20: cinque stampati, la generazione non li aumenta
      expect(effectiveTraitMax(5, settima), 5);
    });

    test('una generazione bassa non alza il massimo della scheda', () {
      final terza = generationFromText('III'); // massimo 10
      expect(effectiveTraitMax(5, terza), 5);
      expect(effectiveTraitMax(9, terza), 9);
    });

    test('senza generazione vale quanto stampa la scheda', () {
      expect(effectiveTraitMax(9, null), 9);
      expect(effectiveTraitMax(5, null), 5);
    });
  });
}
