import '../models/sheet_type.dart';

/// Un campo di testo semplice dell'intestazione o di una sezione.
class FieldDef {
  const FieldDef(
    this.key,
    this.label, {
    this.multiline = false,
    this.hint,
    this.suggestions = const [],
    this.options = const [],
    this.allowCustom = false,
  });
  final String key;
  final String label;
  final bool multiline;
  final String? hint;

  /// Valori proposti in autocompletamento (clan, predatori...), presi dai
  /// menu a tendina delle schede ufficiali. Restano campi liberi: si puo'
  /// scrivere qualsiasi cosa.
  final List<String> suggestions;

  /// Valori di una scelta chiusa: il campo diventa un menu a tendina e non
  /// si scrive a mano (la Generazione, in numeri romani).
  final List<String> options;

  /// Se vero il menu offre anche "Altro...", che apre la tastiera: vale per
  /// Clan, Natura e Carattere, dove l'elenco ufficiale non puo' esaurire
  /// quello che a un tavolo puo' venire in mente. La Generazione no: quella
  /// e' una scelta chiusa davvero.
  final bool allowCustom;

  bool get isSelect => options.isNotEmpty;
}

/// Un tratto a pallini con nome fisso (Forza, Atletica, Coraggio...).
class TraitDef {
  const TraitDef(this.key, this.label, {this.specialtyKey});
  final String key;
  final String label;

  /// Chiave del campo di testo per la specializzazione scritta sulla riga
  /// puntinata accanto al nome del tratto.
  final String? specialtyKey;
}

/// Un blocco di tratti (Fisici, Attitudini, Conoscenze...).
class TraitGroup {
  const TraitGroup(this.key, this.title, this.traits, {this.extraSlots = 0});
  final String key;
  final String title;
  final List<TraitDef> traits;

  /// Righe vuote extra stampate sulla scheda, compilabili a mano.
  final int extraSlots;

  String get extraListKey => 'extra_$key';
}

/// Una colonna testuale aggiuntiva in una sezione a elenco.
class ColumnDef {
  const ColumnDef(this.key, this.label, {this.flex = 2});
  final String key;
  final String label;
  final int flex;
}

/// Una sezione a elenco: Discipline, Background, Pregi, Armi, Rituali...
class ListSection {
  const ListSection({
    required this.key,
    required this.title,
    this.slots = 5,
    this.hasDots = false,
    this.dotMax = 5,
    this.limitedByGeneration = false,
    this.columns = const [],
    this.lineSlots = 0,
    this.suggestions = const [],
    this.nameLabel = 'Nome',
    this.hint,
  });

  final String key;
  final String title;

  /// Righe stampate sulla scheda: sono anche il minimo mostrato dall'editor.
  final int slots;

  final bool hasDots;
  final int dotMax;

  /// Se vero i pallini di questa sezione sottostanno al massimo imposto
  /// dalla generazione: vale per Discipline, Background, Vie e Altre
  /// Caratteristiche, non per pregi, difetti e rifugio.
  final bool limitedByGeneration;

  final List<ColumnDef> columns;

  /// Righe libere sotto ogni voce (i poteri delle Discipline su V5).
  final int lineSlots;

  /// Voci proposte in autocompletamento, estratte dalle schede ufficiali.
  final List<String> suggestions;

  final String nameLabel;
  final String? hint;
}

enum TrackKind {
  /// Punteggio a pallini pieni/vuoti (0..length).
  dots,

  /// Caselle a due stati: vuota o barrata.
  boxes,

  /// Caselle a più stati (danni superficiali/aggravati, contuso/leso/...).
  damage,
}

/// Un tracker: Salute, Volontà, Punti Sangue, Umanità, Fame...
class TrackDef {
  const TrackDef({
    required this.key,
    required this.title,
    required this.kind,
    required this.length,
    this.perRow = 10,
    this.maxState = 1,
    this.rowLabels = const [],
    this.rowPenalties = const [],
    this.stateLegend = const [],
    this.firstStateFilled = false,
    this.note,
  });

  final String key;
  final String title;
  final TrackKind kind;
  final int length;
  final int perRow;

  /// Stato massimo di ogni casella per i tracker [TrackKind.damage].
  final int maxState;

  /// Etichette per riga (livelli di Salute della scheda 20°).
  final List<String> rowLabels;
  final List<String> rowPenalties;

  /// Legenda degli stati, mostrata sotto al tracker.
  final List<String> stateLegend;

  /// Se vero il primo stato e' una casella piena invece che una barra:
  /// serve all'Umanita' di V5, dove il punteggio si riempie e le macchie si
  /// segnano con una croce.
  final bool firstStateFilled;

  final String? note;
}

/// Un blocco di testo libero (Biografia, Note, Debolezza...).
class TextSection {
  const TextSection(this.key, this.title, {this.lines = 4, this.fields});
  final String key;
  final String title;
  final int lines;

  /// Se valorizzato la sezione e' composta da campi etichettati invece che
  /// da un unico blocco di testo.
  final List<FieldDef>? fields;
}

/// Un raggruppamento di sezioni mostrato come pagina/step dell'editor.
class SheetPart {
  const SheetPart(this.title, this.sectionKeys);
  final String title;
  final List<String> sectionKeys;
}

/// La descrizione completa di una scheda: guida sia l'editor sia il
/// rendering fedele al PDF, cosi' i due restano sempre allineati.
class SheetSchema {
  const SheetSchema({
    required this.type,
    required this.identity,
    required this.attributes,
    required this.abilities,
    this.abilityColumnTitles = const [],
    this.virtues = const [],
    this.virtueMax = 5,
    this.lists = const [],
    this.tracks = const [],
    this.textSections = const [],
    this.notes = const [],
    this.clanWeaknessKey,
  });

  final SheetType type;
  final List<FieldDef> identity;
  final List<TraitGroup> attributes;
  final List<TraitGroup> abilities;
  final List<String> abilityColumnTitles;
  final List<TraitDef> virtues;
  final int virtueMax;
  final List<ListSection> lists;
  final List<TrackDef> tracks;
  final List<TextSection> textSections;

  /// Righe di promemoria stampate a fondo scheda (es. "Attributi: 7/5/3").
  final List<String> notes;

  /// Dove questa scheda scrive la debolezza di clan: la 5a edizione ha un
  /// riquadro suo ("Debolezza di Clan"), le altre due la mettono insieme
  /// alle debolezze generiche.
  final String? clanWeaknessKey;

  int get traitMax => type.traitMax;

  ListSection listSection(String key) => lists.firstWhere((l) => l.key == key);
  bool hasList(String key) => lists.any((l) => l.key == key);
  TrackDef track(String key) => tracks.firstWhere((t) => t.key == key);
  bool hasTrack(String key) => tracks.any((t) => t.key == key);
  TextSection textSection(String key) =>
      textSections.firstWhere((t) => t.key == key);
  bool hasText(String key) => textSections.any((t) => t.key == key);

  /// Tutti i tratti a pallini della scheda, usati dal tiro rapido.
  List<TraitDef> get allTraits => [
    for (final g in attributes) ...g.traits,
    for (final g in abilities) ...g.traits,
    ...virtues,
  ];
}
