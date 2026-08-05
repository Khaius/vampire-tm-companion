import 'package:flutter_test/flutter_test.dart';
import 'package:vtm_companion/models/dice.dart';

void main() {
  group('Conteggio del tiro', () {
    test('esempio delle specifiche: 5 dadi, difficoltà 7, 1-5-6-1-7', () {
      final roll = DiceRoll(
        pool: 5,
        difficulty: 7,
        values: [1, 5, 6, 1, 7],
        timestamp: DateTime(2026),
      );

      expect(roll.successes, 1, reason: 'solo il 7 raggiunge la difficoltà');
      expect(roll.ones, 2);
      expect(roll.total, -1, reason: 'un successo meno due uno');

      expect(roll.outcomeOf(7), DieOutcome.success);
      expect(roll.outcomeOf(1), DieOutcome.one);
      expect(roll.outcomeOf(5), DieOutcome.neutral);
      expect(roll.outcomeOf(6), DieOutcome.neutral);
    });

    test('un valore pari alla difficoltà è un successo', () {
      final roll = DiceRoll(
        pool: 3,
        difficulty: 6,
        values: [6, 6, 5],
        timestamp: DateTime(2026),
      );
      expect(roll.successes, 2);
      expect(roll.ones, 0);
      expect(roll.total, 2);
    });

    test('gli uno restano rossi anche a difficoltà bassa', () {
      final roll = DiceRoll(
        pool: 4,
        difficulty: 2,
        values: [1, 1, 2, 10],
        timestamp: DateTime(2026),
      );
      expect(roll.outcomeOf(1), DieOutcome.one);
      expect(roll.successes, 2);
      expect(roll.ones, 2);
      expect(roll.total, 0);
    });

    test('tutti gli esiti sono classificati', () {
      final roll = DiceRoll(
        pool: 3,
        difficulty: 8,
        values: [1, 4, 9],
        timestamp: DateTime(2026),
      );
      final outcomes = roll.results.map((r) => r.outcome).toList();
      expect(outcomes, [
        DieOutcome.one,
        DieOutcome.neutral,
        DieOutcome.success,
      ]);
    });

    test('il tiro casuale resta nell\'intervallo 1-10', () {
      for (var i = 0; i < 200; i++) {
        final roll = DiceRoll.roll(pool: 10, difficulty: 6);
        expect(roll.values.length, 10);
        for (final value in roll.values) {
          expect(value, inInclusiveRange(1, 10));
        }
        expect(roll.total, roll.successes - roll.ones);
      }
    });
  });
}
