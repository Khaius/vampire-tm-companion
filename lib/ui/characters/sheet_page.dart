import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/clans.dart';
import '../../data/generations.dart';
import '../../data/schemas.dart';
import '../../models/character.dart';
import '../../models/sheet_type.dart';
import '../widgets/character_photo.dart';
import '../widgets/dots.dart';
import '../widgets/parchment.dart';
import '../widgets/prompts.dart';
import '../widgets/tracks.dart';
import 'character_edit_page.dart';

/// Rotta della scheda aperta, usata anche dal menu in basso per riaprire
/// l'ultima scheda selezionata.
Route<void> sheetPageRoute(String characterId) => MaterialPageRoute(
  builder: (_) => SheetPage(characterId: characterId),
  settings: RouteSettings(name: 'sheet/$characterId'),
);

/// La scheda disegnata come l'originale cartaceo, ma viva: i pallini, le
/// caselle e i campi si toccano e si aggiornano subito.
class SheetPage extends StatefulWidget {
  const SheetPage({super.key, required this.characterId});

  final String characterId;

  @override
  State<SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends State<SheetPage> {
  late final AppState _state = context.read<AppState>();
  Character? _character;
  late SheetSchema _schema;

  /// La scheda si apre bloccata: sfogliarla non deve poterla cambiare per
  /// sbaglio. Si sblocca dal lucchetto in alto e resta sbloccata finche'
  /// la si tiene aperta.
  bool _locked = true;

  final ScrollController _scroll = ScrollController();

  /// Cambia quando la foto cambia: serve a far rileggere il file, che ha
  /// sempre lo stesso nome.
  int _photoVersion = 0;

  @override
  void initState() {
    super.initState();
    final character = _state.characterById(widget.characterId);
    if (character != null) {
      _character = character;
      _schema = schemaFor(character.type);
    }
  }

  /// La generazione scelta sulla scheda, se riconoscibile.
  GenerationRule? get _generation =>
      generationFromText(_character?.text('generation'));

  /// Massimo utilizzabile per un tratto: il minore fra i pallini stampati
  /// sulla scheda e quelli concessi dalla generazione.
  int _allowedFor(int sheetMax) => effectiveTraitMax(sheetMax, _generation);

  /// Quante caselle disegnare di un tracker: solo la riserva di sangue si
  /// accorcia con la generazione. Volontà e Salute non c'entrano.
  int? _visibleBoxes(TrackDef track) =>
      track.key == 'sangue' ? _generation?.bloodPool : null;

  /// Vero se restano segnate caselle oltre a quelle che si vedono: capita
  /// cambiando generazione a personaggio fatto, e va detto invece di far
  /// sparire il dato in silenzio.
  bool _hiddenMarks(Character character, TrackDef track) {
    final visible = _visibleBoxes(track);
    if (visible == null || visible >= track.length) return false;
    return character
        .track(track.key, track.length)
        .skip(visible)
        .any((state) => state > 0);
  }

  void _save() {
    final character = _character;
    if (character == null) return;
    character.updatedAt = DateTime.now();
    _state.characterRepository.saveDebounced(character);
  }

  @override
  void dispose() {
    _scroll.dispose();
    final character = _character;
    // Uscendo dalla scheda si scrive subito su disco e si aggiorna la lista
    // al frame successivo, quando l'albero non e' piu' bloccato.
    if (character != null) _state.flushAndNotifyLater(character);
    super.dispose();
  }

  Future<void> _editText(
    String key,
    String title, {
    bool multiline = false,
    List<String> options = const [],
    bool allowCustom = false,
  }) async {
    final character = _character!;
    final result = options.isNotEmpty
        ? await promptForChoice(
            context,
            title: title,
            initial: character.text(key),
            options: options,
            allowCustom: allowCustom,
          )
        : await promptForText(
            context,
            title: title,
            initial: character.text(key),
            multiline: multiline,
          );
    if (result == null) return;
    setState(() => character.texts[key] = result);
    _save();
    if (key == 'clan') _applyClan(character, result);
  }

  /// Scelto il clan, la scheda si scrive da sola per la parte che il clan
  /// detta: le sue Discipline e la sua debolezza.
  void _applyClan(Character character, String name) {
    final clan = clanRule(character.type, name);
    if (clan == null) return;
    final filled = applyClanTemplate(character, _schema, clan);
    if (filled.isEmpty) return;
    setState(() {});
    _save();
    final message = filled.message;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _quickRoll(String label, int value) {
    _state.requestQuickRoll(value < 1 ? 1 : value, label);
  }

  @override
  Widget build(BuildContext context) {
    final character = _character;
    if (character == null) {
      return const Scaffold(body: Center(child: Text('Scheda non trovata')));
    }
    final type = character.type;

    return Scaffold(
      backgroundColor: const Color(0xFF080607),
      appBar: AppBar(
        title: Text(
          character.displayName.toUpperCase(),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: _locked
                ? 'Scheda bloccata: tocca per poterla modificare'
                : 'Scheda modificabile: tocca per bloccarla',
            icon: Icon(_locked ? Icons.lock_outline : Icons.lock_open),
            color: _locked ? VtmColors.ash : VtmColors.bloodBright,
            onPressed: () => setState(() => _locked = !_locked),
          ),
          IconButton(
            tooltip: 'Modifica dati',
            icon: const Icon(Icons.edit_note),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CharacterEditPage(characterId: character.id),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Chiudi la scheda',
            icon: const Icon(Icons.close),
            onPressed: () {
              _state.closeSelectedCharacter();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Il telefono resta su una colonna; tablet e schermi larghi
            // recuperano l'impaginazione a colonne del cartaceo.
            final wide = constraints.maxWidth >= 1000;
            return Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              interactive: true,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 26),
                children: [
                  _LockBanner(
                    locked: _locked,
                    onToggle: () => setState(() => _locked = !_locked),
                  ),
                  const SizedBox(height: 10),
                  SheetPaper(
                    type: type,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildSheet(character, type, wide),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _locked
                          ? 'Scheda bloccata: puoi sfogliarla senza rischiare di '
                                'cambiarla. Tocca il nome di un tratto per tirare '
                                'i dadi.'
                          : 'Tocca i pallini e le caselle per aggiornarli, tocca '
                                'una riga per scrivere, tocca il nome di un tratto '
                                'per tirare i dadi.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: VtmColors.ash,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------- struttura

  /// Una fascia col suo blocco, che si apre e si chiude toccando il titolo.
  ///
  /// Le chiavi sono le stesse dell'editor: chiudendo i Rituali qui restano
  /// chiusi anche di la', ed e' quello che ci si aspetta.
  List<Widget> _band(
    Character character,
    SheetType type,
    String key,
    String title,
    Widget Function() body,
  ) {
    final collapsed = character.isCollapsed(key);
    return [
      SheetBanner(
        title,
        type: type,
        collapsed: collapsed,
        onToggle: () {
          setState(() => character.toggleCollapsed(key));
          _save();
        },
      ),
      if (!collapsed) body(),
    ];
  }

  List<Widget> _buildSheet(Character character, SheetType type, bool wide) {
    return [
      SheetMasthead(type: type),
      const SizedBox(height: 14),
      _identityBlock(character, wide),
      ..._band(
        character,
        type,
        'attributi',
        'Attributi',
        () => _traitColumns(
          character,
          _schema.attributes,
          wide,
          _schema.traitMax,
        ),
      ),
      ..._band(
        character,
        type,
        'abilita',
        type == SheetType.v5 ? 'Skills' : 'Abilità',
        () => _traitColumns(
          character,
          _schema.abilities,
          wide,
          _schema.traitMax,
          showColumnTitles: true,
        ),
      ),
      if (_schema.virtues.isNotEmpty)
        ..._band(
          character,
          type,
          'virtu',
          'Virtù',
          () => _virtuesBlock(character),
        ),
      for (final section in _schema.lists)
        ..._band(
          character,
          type,
          'list:${section.key}',
          section.title,
          () => _listBlock(character, section, wide),
        ),
      ..._band(
        character,
        type,
        'tracker',
        'Vantaggi e Stato',
        () => _tracksBlock(character, type, wide),
      ),
      for (final section in _schema.textSections)
        ..._band(
          character,
          type,
          'text:${section.key}',
          section.title,
          () => _textBlock(character, section, wide),
        ),
      for (final note in _schema.notes)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            note,
            textAlign: TextAlign.center,
            style: SheetTextStyles.small,
          ),
        ),
    ];
  }

  /// Sceglie o cambia il ritratto dalla memoria del telefono.
  Future<void> _changePhoto(Character character) async {
    final changed = await pickCharacterPhoto(_state, character);
    if (changed && mounted) setState(() => _photoVersion++);
  }

  Future<void> _dropPhoto(Character character) async {
    if (character.photoFile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Togliere la foto?'),
        content: const Text('La scheda resta, la foto viene cancellata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VtmColors.blood),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Togli'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _state.removePhoto(character);
    if (mounted) setState(() => _photoVersion++);
  }

  Widget _identityBlock(Character character, bool wide) {
    final grid = _identityFields(character, wide);
    // il riquadro della foto compare se c'e' una foto, oppure se la scheda
    // e' sbloccata: da bloccata non deve invitare a toccare niente
    if (character.photoFile == null && _locked) return grid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 6),
          child: GestureDetector(
            onTap: _locked ? null : () => _changePhoto(character),
            onLongPress: _locked ? null : () => _dropPhoto(character),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: VtmColors.ink, width: 1.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CharacterPhoto(
                state: _state,
                character: character,
                size: 96,
                radius: 3,
                version: _photoVersion,
                placeholder: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: VtmColors.ink,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: grid),
      ],
    );
  }

  Widget _identityFields(Character character, bool wide) {
    final fields = _schema.identity;
    return _Grid(
      columns: wide ? 3 : 1,
      children: [
        for (final field in fields)
          RuledValue(
            label: '${field.label}:',
            labelWidth: 96,
            value: character.text(field.key),
            placeholder: '—',
            onTap: _locked
                ? null
                : () => _editText(
                    field.key,
                    field.label,
                    options: field.options,
                    allowCustom: field.allowCustom,
                  ),
          ),
      ],
    );
  }

  Widget _traitColumns(
    Character character,
    List<TraitGroup> groups,
    bool wide,
    int max, {
    bool showColumnTitles = false,
  }) {
    final columns = <Widget>[
      for (final group in groups)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showColumnTitles || groups.length > 1)
              SheetColumnTitle(group.title),
            for (final trait in group.traits)
              _TraitLine(
                label: trait.label,
                specialty: trait.specialtyKey == null
                    ? null
                    : character.text(trait.specialtyKey!),
                value: character.dot(trait.key),
                max: max,
                allowed: _allowedFor(max),
                onRoll: () => _quickRoll(trait.label, character.dot(trait.key)),
                onChanged: _locked
                    ? null
                    : (v) {
                        setState(() => character.dots[trait.key] = v);
                        _save();
                      },
                onEditSpecialty: (_locked || trait.specialtyKey == null)
                    ? null
                    : () => _editText(
                        trait.specialtyKey!,
                        'Specializzazione — ${trait.label}',
                      ),
              ),
            for (final entry in character.list(group.extraListKey))
              if (!entry.isEmpty)
                _TraitLine(
                  label: entry.name.isEmpty ? '—' : entry.name,
                  value: entry.value,
                  max: max,
                  allowed: _allowedFor(max),
                  onRoll: entry.name.isEmpty
                      ? null
                      : () => _quickRoll(entry.name, entry.value),
                  onChanged: _locked
                      ? null
                      : (v) {
                          setState(() => entry.value = v);
                          _save();
                        },
                ),
            if (!_locked && group.extraSlots > 0)
              _AddRow(
                label: 'riga',
                onTap: () => _addExtraTrait(character, group),
              ),
          ],
        ),
    ];
    return _Grid(columns: wide ? 3 : 1, gap: 18, children: columns);
  }

  /// Aggiunge una riga libera in fondo a una colonna di Abilità.
  Future<void> _addExtraTrait(Character character, TraitGroup group) async {
    final name = await promptForText(context, title: group.title, initial: '');
    if (name == null || name.trim().isEmpty) return;
    setState(
      () => character.list(group.extraListKey).add(TraitEntry(name: name)),
    );
    _save();
  }

  Widget _virtuesBlock(Character character) {
    return Column(
      children: [
        for (final virtue in _schema.virtues)
          _TraitLine(
            label: virtue.label,
            value: character.dot(virtue.key),
            max: _schema.virtueMax,
            allowed: _allowedFor(_schema.virtueMax),
            onRoll: () => _quickRoll(virtue.label, character.dot(virtue.key)),
            onChanged: _locked
                ? null
                : (v) {
                    setState(() => character.dots[virtue.key] = v);
                    _save();
                  },
          ),
      ],
    );
  }

  Widget _listBlock(Character character, ListSection section, bool wide) {
    final entries = character.list(section.key);
    // Si mostra solo quello che c'e' scritto: niente righe in bianco da
    // saltare con gli occhi. Le altre si aggiungono quando servono.
    final visible = entries.where((entry) => !entry.isEmpty).toList();

    Widget rowFor(TraitEntry entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: RuledValue(
                    value: entry.name,
                    placeholder: section.nameLabel,
                    dense: true,
                    onTap: _locked
                        ? null
                        : () async {
                            final result = await promptForText(
                              context,
                              title: section.nameLabel,
                              initial: entry.name,
                            );
                            if (result == null) return;
                            setState(() => entry.name = result);
                            _save();
                          },
                  ),
                ),
                if (section.hasDots) ...[
                  const SizedBox(width: 8),
                  DotRow(
                    value: entry.value,
                    max: section.dotMax,
                    allowed: section.limitedByGeneration
                        ? _allowedFor(section.dotMax)
                        : null,
                    size: 11,
                    onChanged: _locked
                        ? null
                        : (v) {
                            setState(() => entry.value = v);
                            _save();
                          },
                  ),
                ],
              ],
            ),
            if (section.columns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    for (final column in section.columns) ...[
                      Expanded(
                        flex: column.flex,
                        child: RuledValue(
                          value: entry.fields[column.key] ?? '',
                          placeholder: column.label,
                          dense: true,
                          onTap: _locked
                              ? null
                              : () async {
                                  final result = await promptForText(
                                    context,
                                    title: column.label,
                                    initial: entry.fields[column.key] ?? '',
                                  );
                                  if (result == null) return;
                                  setState(
                                    () => entry.fields[column.key] = result,
                                  );
                                  _save();
                                },
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            if (section.lineSlots > 0)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Column(
                  children: [
                    for (var l = 0; l < section.lineSlots; l++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: RuledValue(
                          label: '${l + 1}',
                          labelWidth: 14,
                          dense: true,
                          value: l < entry.lines.length ? entry.lines[l] : '',
                          onTap: _locked
                              ? null
                              : () async {
                                  final result = await promptForText(
                                    context,
                                    title: 'Potere ${l + 1} — ${entry.name}',
                                    initial: l < entry.lines.length
                                        ? entry.lines[l]
                                        : '',
                                  );
                                  if (result == null) return;
                                  setState(() {
                                    while (entry.lines.length <= l) {
                                      entry.lines.add('');
                                    }
                                    entry.lines[l] = result;
                                  });
                                  _save();
                                },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final useTwoColumns =
        wide || (section.lineSlots == 0 && visible.length > 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isEmpty && _locked)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('—', style: SheetTextStyles.small),
          ),
        _Grid(
          columns: useTwoColumns ? 2 : 1,
          gap: 14,
          children: [for (final entry in visible) rowFor(entry)],
        ),
        if (!_locked) _AddRow(onTap: () => _addListEntry(character, section)),
      ],
    );
  }

  /// Aggiunge una voce a una sezione dalla scheda disegnata.
  ///
  /// Il nome si chiede subito: una riga senza nome sarebbe di nuovo una riga
  /// in bianco, che e' proprio quello che si voleva togliere. Se si annulla,
  /// la riga non nasce.
  Future<void> _addListEntry(Character character, ListSection section) async {
    final name = await promptForText(
      context,
      title: section.nameLabel,
      initial: '',
    );
    if (name == null || name.trim().isEmpty) return;
    setState(() => character.list(section.key).add(TraitEntry(name: name)));
    _save();
  }

  Widget _tracksBlock(Character character, SheetType type, bool wide) {
    final widgets = <Widget>[];
    for (final track in _schema.tracks) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                track.note == null
                    ? track.title
                    : '${track.title} · ${track.note}',
                style: SheetTextStyles.subheading,
              ),
              const SizedBox(height: 6),
              if (track.kind == TrackKind.dots)
                DotRow(
                  value: character.dot(track.key),
                  max: track.length,
                  size: 14,
                  alignment: MainAxisAlignment.center,
                  onChanged: _locked
                      ? null
                      : (v) {
                          setState(() => character.dots[track.key] = v);
                          _save();
                        },
                )
              else if (track.rowLabels.isNotEmpty)
                HealthLevels(
                  track: track,
                  states: character.track(track.key, track.length),
                  onChanged: _locked
                      ? null
                      : (i, v) {
                          setState(
                            () =>
                                character.track(track.key, track.length)[i] = v,
                          );
                          _save();
                        },
                )
              else
                BoxTrack(
                  states: character.track(track.key, track.length),
                  maxState: track.maxState,
                  perRow: track.perRow,
                  filledFirst: track.firstStateFilled,
                  // La riserva di sangue dipende dalla generazione: le
                  // caselle in piu' della scheda non si disegnano proprio.
                  visible: _visibleBoxes(track),
                  onChanged: _locked
                      ? null
                      : (i, v) {
                          setState(
                            () =>
                                character.track(track.key, track.length)[i] = v,
                          );
                          _save();
                        },
                ),
              if (_hiddenMarks(character, track))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'ci sono caselle segnate oltre il limite della generazione',
                    textAlign: TextAlign.center,
                    style: SheetTextStyles.small,
                  ),
                ),
              if (track.stateLegend.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    track.stateLegend.join('   ·   '),
                    style: SheetTextStyles.small,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return _Grid(columns: wide ? 2 : 1, gap: 18, children: widgets);
  }

  Widget _textBlock(Character character, TextSection section, bool wide) {
    final fields = section.fields;
    if (fields == null) {
      return RuledBlock(
        value: character.text(section.key),
        lines: section.lines,
        onTap: _locked
            ? null
            : () => _editText(section.key, section.title, multiline: true),
      );
    }
    return _Grid(
      columns: wide ? 2 : 1,
      children: [
        for (final field in fields)
          field.multiline
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.label, style: SheetTextStyles.label),
                      const SizedBox(height: 3),
                      RuledBlock(
                        value: character.text(field.key),
                        lines: 3,
                        onTap: _locked
                            ? null
                            : () => _editText(
                                field.key,
                                field.label,
                                multiline: true,
                              ),
                      ),
                    ],
                  ),
                )
              // Etichetta sopra la riga, come nei riquadri della scheda V5.
              : Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${field.label}:', style: SheetTextStyles.label),
                      RuledValue(
                        value: character.text(field.key),
                        placeholder: '—',
                        dense: true,
                        onTap: _locked
                            ? null
                            : () => _editText(
                                field.key,
                                field.label,
                                options: field.options,
                                allowCustom: field.allowCustom,
                              ),
                      ),
                    ],
                  ),
                ),
      ],
    );
  }
}

/// La riga per aggiungere una voce, in fondo a una sezione della scheda.
/// Compare solo a scheda sbloccata: da bloccata non deve tentare nessuno.
class _AddRow extends StatelessWidget {
  const _AddRow({this.label, required this.onTap});

  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 15, color: VtmColors.ink),
              const SizedBox(width: 4),
              // nelle colonne strette il testo si accorcia invece di
              // sfondare la riga
              Flexible(
                child: Text(
                  'aggiungi ${label ?? "voce"}',
                  overflow: TextOverflow.ellipsis,
                  style: SheetTextStyles.small,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una riga di tratto: nome (che lancia i dadi), specializzazione e pallini.
class _TraitLine extends StatelessWidget {
  const _TraitLine({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.allowed,
    this.specialty,
    this.onRoll,
    this.onEditSpecialty,
  });

  final String label;
  final int value;
  final int max;

  /// Null quando la scheda e' bloccata: i pallini restano visibili ma non
  /// rispondono al tocco.
  final ValueChanged<int>? onChanged;

  /// Pallini utilizzabili secondo la generazione.
  final int? allowed;

  final String? specialty;
  final VoidCallback? onRoll;
  final VoidCallback? onEditSpecialty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Nome e riga della specializzazione stanno in uno spazio elastico:
          // cosi' la colonna dei pallini resta allineata come sul cartaceo.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: onRoll,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: Text(
                        label,
                        style: SheetTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (specialty != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onEditSpecialty,
                      child: Container(
                        height: 18,
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.only(bottom: 1),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: VtmColors.rule,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Text(
                          specialty!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SheetTextStyles.small.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: DotRow(
              value: value,
              max: max,
              allowed: allowed,
              // con nove pallini serve un filo di spazio in piu' per i nomi
              size: max > 5 ? 10 : 11,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Griglia semplice: una colonna sul telefono, piu' colonne sui tablet.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children, this.gap = 12});

  final int columns;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            Padding(
              padding: EdgeInsets.only(bottom: gap / 2),
              child: child,
            ),
        ],
      );
    }

    final buckets = List.generate(columns, (_) => <Widget>[]);
    for (var i = 0; i < children.length; i++) {
      buckets[i % columns].add(
        Padding(
          padding: EdgeInsets.only(bottom: gap / 2),
          child: children[i],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buckets[i],
            ),
          ),
          if (i != columns - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

/// Banda in cima alla scheda: dice se le modifiche sono bloccate e permette
/// di cambiare stato senza cercare il pulsante nella barra.
class _LockBanner extends StatelessWidget {
  const _LockBanner({required this.locked, required this.onToggle});

  final bool locked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = locked ? VtmColors.ash : VtmColors.bloodBright;
    return Material(
      color: VtmColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                locked ? Icons.lock_outline : Icons.lock_open,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locked
                      ? 'Modifiche bloccate'
                      : 'Modifiche attive: la scheda cambia al tocco',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              Text(
                locked ? 'SBLOCCA' : 'BLOCCA',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
