import 'sheet_type.dart';

/// Una voce di una sezione a elenco (Discipline, Background, Pregi, Armi...).
///
/// [name] e' il nome scritto sulla riga, [value] il numero di pallini (se la
/// sezione li prevede), [fields] le colonne extra (Tipo, Costo, Danno...) e
/// [lines] le righe libere sotto la voce, usate per i poteri delle Discipline
/// nella scheda V5.
class TraitEntry {
  TraitEntry({
    this.name = '',
    this.value = 0,
    Map<String, String>? fields,
    List<String>? lines,
  }) : fields = fields ?? <String, String>{},
       lines = lines ?? <String>[];

  String name;
  int value;
  final Map<String, String> fields;
  final List<String> lines;

  bool get isEmpty =>
      name.trim().isEmpty &&
      value == 0 &&
      fields.values.every((v) => v.trim().isEmpty) &&
      lines.every((l) => l.trim().isEmpty);

  TraitEntry copy() => TraitEntry(
    name: name,
    value: value,
    fields: Map<String, String>.from(fields),
    lines: List<String>.from(lines),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    if (fields.isNotEmpty) 'fields': fields,
    if (lines.any((l) => l.isNotEmpty)) 'lines': lines,
  };

  static TraitEntry fromJson(Map<String, dynamic> json) => TraitEntry(
    name: json['name'] as String? ?? '',
    value: (json['value'] as num?)?.toInt() ?? 0,
    fields: (json['fields'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    ),
    lines: (json['lines'] as List?)?.map((e) => e?.toString() ?? '').toList(),
  );
}

/// La scheda di un personaggio.
///
/// Il modello e' volutamente generico: la struttura di ogni scheda vive nello
/// schema ([SheetSchema]), qui restano solo i dati inseriti dall'utente. Cosi'
/// le tre schede condividono editor, salvataggio e rendering.
class Character {
  Character({
    required this.id,
    required this.type,
    Map<String, String>? texts,
    Map<String, int>? dots,
    Map<String, List<TraitEntry>>? lists,
    Map<String, List<int>>? tracks,
    Set<String>? collapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : texts = texts ?? <String, String>{},
       dots = dots ?? <String, int>{},
       lists = lists ?? <String, List<TraitEntry>>{},
       tracks = tracks ?? <String, List<int>>{},
       collapsed = collapsed ?? <String>{},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final SheetType type;

  /// Campi di testo liberi (nome, cronaca, biografia, note...).
  final Map<String, String> texts;

  /// Tratti a pallini (attributi, abilità, virtù, tracker a punteggio).
  final Map<String, int> dots;

  /// Sezioni a elenco, indicizzate per id di sezione.
  final Map<String, List<TraitEntry>> lists;

  /// Tracker a caselle: ogni elemento e' lo stato della casella
  /// (0 = vuota, 1/2/3 = livelli di riempimento a seconda del tracker).
  final Map<String, List<int>> tracks;

  /// Le sezioni chiuse a fisarmonica, per chiave di sezione.
  ///
  /// Sta insieme alla scheda e non alle preferenze dell'app perche' e' una
  /// scelta che riguarda quel personaggio: chi non usa i Rituali li tiene
  /// chiusi su quella scheda, non su tutte.
  final Set<String> collapsed;

  final DateTime createdAt;
  DateTime updatedAt;

  bool isCollapsed(String key) => collapsed.contains(key);

  void toggleCollapsed(String key) {
    if (!collapsed.remove(key)) collapsed.add(key);
  }

  String get displayName {
    final n = texts['name']?.trim() ?? '';
    return n.isEmpty ? 'Senza nome' : n;
  }

  String get subtitleLine {
    final parts = <String>[
      texts['clan']?.trim() ?? '',
      texts['concept']?.trim() ?? texts['profile']?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' · ');
  }

  String text(String key) => texts[key] ?? '';
  int dot(String key) => dots[key] ?? 0;

  List<TraitEntry> list(String key) => lists.putIfAbsent(key, () => []);

  List<int> track(String key, int length) {
    final existing = tracks[key];
    if (existing == null) {
      final created = List<int>.filled(length, 0, growable: true);
      tracks[key] = created;
      return created;
    }
    if (existing.length < length) {
      existing.addAll(List<int>.filled(length - existing.length, 0));
    } else if (existing.length > length) {
      existing.removeRange(length, existing.length);
    }
    return existing;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.id,
    'texts': texts,
    'dots': dots,
    'lists': lists.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
    'tracks': tracks,
    if (collapsed.isNotEmpty) 'collapsed': collapsed.toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Character fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as String,
    type: SheetType.fromId(json['type'] as String?),
    texts: (json['texts'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    ),
    dots: (json['dots'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    ),
    lists: (json['lists'] as Map?)?.map(
      (k, v) => MapEntry(
        k.toString(),
        (v as List? ?? [])
            .map(
              (e) => TraitEntry.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      ),
    ),
    tracks: (json['tracks'] as Map?)?.map(
      (k, v) => MapEntry(
        k.toString(),
        (v as List? ?? []).map((e) => (e as num?)?.toInt() ?? 0).toList(),
      ),
    ),
    collapsed: (json['collapsed'] as List?)?.map((e) => e.toString()).toSet(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}
