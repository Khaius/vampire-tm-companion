import 'dart:math';

import 'package:flutter/foundation.dart';

/// Esito di un singolo d10.
enum DieOutcome {
  /// Uguale o superiore alla difficoltà: successo (verde).
  success,

  /// Un 1: sottrae un successo (rosso).
  one,

  /// Tutto il resto (nero).
  neutral,
}

class DieResult {
  const DieResult(this.value, this.outcome);
  final int value;
  final DieOutcome outcome;
}

/// Un tiro completo di d10 con il conteggio finale.
class DiceRoll {
  DiceRoll({
    required this.pool,
    required this.difficulty,
    required this.values,
    required this.timestamp,
    this.label,
  });

  final int pool;
  final int difficulty;
  final List<int> values;
  final DateTime timestamp;

  /// Nome del tratto da cui e' partito il tiro rapido, se presente.
  final String? label;

  /// Sorgente casuale del tiro. I test la sostituiscono con una a seme fisso
  /// per avere risultati riproducibili.
  @visibleForTesting
  static Random random = Random.secure();

  factory DiceRoll.roll({
    required int pool,
    required int difficulty,
    String? label,
  }) {
    final values = List<int>.generate(pool, (_) => random.nextInt(10) + 1);
    return DiceRoll(
      pool: pool,
      difficulty: difficulty,
      values: values,
      timestamp: DateTime.now(),
      label: label,
    );
  }

  DieOutcome outcomeOf(int value) {
    if (value == 1) return DieOutcome.one;
    if (value >= difficulty) return DieOutcome.success;
    return DieOutcome.neutral;
  }

  List<DieResult> get results =>
      values.map((v) => DieResult(v, outcomeOf(v))).toList();

  int get successes => values.where((v) => v != 1 && v >= difficulty).length;

  int get ones => values.where((v) => v == 1).length;

  /// Conteggio finale richiesto: successi meno gli uno.
  int get total => successes - ones;
}
