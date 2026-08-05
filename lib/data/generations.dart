/// Regole legate alla generazione del vampiro.
///
/// La tabella e' quella classica di Vampiri: piu' ci si avvicina a Caino,
/// piu' alti sono il punteggio massimo dei tratti e la riserva di sangue.
/// Il massimo dei tratti vale per Attributi, Abilita', Discipline,
/// Background e Virtu'; **non** si applica a Umanita'/Sentiero e Volonta',
/// che restano fuori dal limite di generazione.
class GenerationRule {
  const GenerationRule({
    required this.generation,
    required this.roman,
    required this.traitMax,
    required this.bloodPool,
    required this.bloodPerTurn,
  });

  /// Numero della generazione (2 = seconda, 13 = tredicesima...).
  final int generation;

  /// Come si scrive sulla scheda: II, VII, XIII...
  final String roman;

  /// Punteggio massimo dei tratti soggetti al limite.
  final int traitMax;

  /// Punti sangue che il corpo puo' contenere.
  final int bloodPool;

  /// Punti sangue spendibili in un turno.
  final int bloodPerTurn;

  String get label => '$roman ($generation ª)';
}

/// Le generazioni proponibili sulla scheda, dalla seconda alla quindicesima.
///
/// Le tabelle pubblicate si fermano alla terza generazione: alla seconda
/// sono stati assegnati gli stessi valori della terza, perche' di fatto e'
/// territorio da narratore piu' che da regolamento.
const generationRules = <GenerationRule>[
  GenerationRule(
    generation: 2,
    roman: 'II',
    traitMax: 10,
    bloodPool: 50,
    bloodPerTurn: 10,
  ),
  GenerationRule(
    generation: 3,
    roman: 'III',
    traitMax: 10,
    bloodPool: 50,
    bloodPerTurn: 10,
  ),
  GenerationRule(
    generation: 4,
    roman: 'IV',
    traitMax: 9,
    bloodPool: 50,
    bloodPerTurn: 10,
  ),
  GenerationRule(
    generation: 5,
    roman: 'V',
    traitMax: 8,
    bloodPool: 40,
    bloodPerTurn: 8,
  ),
  GenerationRule(
    generation: 6,
    roman: 'VI',
    traitMax: 7,
    bloodPool: 30,
    bloodPerTurn: 6,
  ),
  GenerationRule(
    generation: 7,
    roman: 'VII',
    traitMax: 6,
    bloodPool: 20,
    bloodPerTurn: 5,
  ),
  GenerationRule(
    generation: 8,
    roman: 'VIII',
    traitMax: 5,
    bloodPool: 15,
    bloodPerTurn: 3,
  ),
  GenerationRule(
    generation: 9,
    roman: 'IX',
    traitMax: 5,
    bloodPool: 14,
    bloodPerTurn: 2,
  ),
  GenerationRule(
    generation: 10,
    roman: 'X',
    traitMax: 5,
    bloodPool: 13,
    bloodPerTurn: 1,
  ),
  GenerationRule(
    generation: 11,
    roman: 'XI',
    traitMax: 5,
    bloodPool: 12,
    bloodPerTurn: 1,
  ),
  GenerationRule(
    generation: 12,
    roman: 'XII',
    traitMax: 5,
    bloodPool: 11,
    bloodPerTurn: 1,
  ),
  GenerationRule(
    generation: 13,
    roman: 'XIII',
    traitMax: 5,
    bloodPool: 10,
    bloodPerTurn: 1,
  ),
  GenerationRule(
    generation: 14,
    roman: 'XIV',
    traitMax: 5,
    bloodPool: 10,
    bloodPerTurn: 1,
  ),
  GenerationRule(
    generation: 15,
    roman: 'XV',
    traitMax: 5,
    bloodPool: 10,
    bloodPerTurn: 1,
  ),
];

/// I numeri romani proposti dal menu della scheda.
///
/// Costante perche' gli schemi delle schede sono a loro volta costanti; il
/// test `generations_test.dart` verifica che resti allineata a
/// [generationRules].
const generationRomanOptions = <String>[
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
  'XIII',
  'XIV',
  'XV',
];

const _romanValues = <String, int>{
  'II': 2,
  'III': 3,
  'IV': 4,
  'V': 5,
  'VI': 6,
  'VII': 7,
  'VIII': 8,
  'IX': 9,
  'X': 10,
  'XI': 11,
  'XII': 12,
  'XIII': 13,
  'XIV': 14,
  'XV': 15,
};

/// Interpreta il campo Generazione della scheda.
///
/// Accetta il numero romano del menu ma anche quello che ci si puo'
/// ritrovare in una scheda scritta a mano prima d'ora: "13", "13ª", "XIII".
/// Se non riesce a capirlo restituisce null e nessun limite viene applicato.
GenerationRule? generationFromText(String? value) {
  if (value == null) return null;
  final text = value.trim().toUpperCase();
  if (text.isEmpty) return null;

  int? number;
  if (RegExp(r'^[IVX]+$').hasMatch(text)) {
    // numero romano puro: e' quello che scrive il menu della scheda
    number = _romanValues[text];
  } else {
    // scritture a mano tollerate: "13", "10ª", "8°". Si legge solo il
    // numero iniziale, cosi' parole come "ventesima" non vengono scambiate
    // per numeri romani a causa delle lettere che contengono.
    final match = RegExp(r'^(\d{1,2})').firstMatch(text);
    number = match == null ? null : int.tryParse(match.group(1)!);
  }
  if (number == null) return null;

  for (final rule in generationRules) {
    if (rule.generation == number) return rule;
  }
  return null;
}

/// Il massimo utilizzabile per un tratto: il minore fra quanto stampa la
/// scheda e quanto concede la generazione.
int effectiveTraitMax(int sheetMax, GenerationRule? generation) {
  if (generation == null) return sheetMax;
  return generation.traitMax < sheetMax ? generation.traitMax : sheetMax;
}
