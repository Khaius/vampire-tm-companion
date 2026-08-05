import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/schemas.dart';
import '../../models/character.dart';
import '../../models/sheet_type.dart';
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

  @override
  void initState() {
    super.initState();
    final character = _state.characterById(widget.characterId);
    if (character != null) {
      _character = character;
      _schema = schemaFor(character.type);
    }
  }

  void _save() {
    final character = _character;
    if (character == null) return;
    character.updatedAt = DateTime.now();
    _state.characterRepository.saveDebounced(character);
  }

  @override
  void dispose() {
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
  }) async {
    final character = _character!;
    final result = await promptForText(
      context,
      title: title,
      initial: character.text(key),
      multiline: multiline,
    );
    if (result == null) return;
    setState(() => character.texts[key] = result);
    _save();
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 26),
              children: [
                SheetPaper(
                  type: type,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildSheet(character, type, wide),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'Tocca i pallini e le caselle per aggiornarli, tocca una '
                    'riga per scrivere, tocca il nome di un tratto per tirare '
                    'i dadi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: VtmColors.ash, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------- struttura

  List<Widget> _buildSheet(Character character, SheetType type, bool wide) {
    return [
      SheetMasthead(type: type),
      const SizedBox(height: 14),
      _identityBlock(character, wide),
      SheetBanner('Attributi', type: type),
      _traitColumns(character, _schema.attributes, wide, _schema.traitMax),
      SheetBanner(
        type == SheetType.v5 ? 'Skills' : 'Abilità',
        type: type,
      ),
      _traitColumns(
        character,
        _schema.abilities,
        wide,
        _schema.traitMax,
        showColumnTitles: true,
      ),
      if (_schema.virtues.isNotEmpty) ...[
        SheetBanner('Virtù', type: type),
        _virtuesBlock(character),
      ],
      for (final section in _schema.lists) ...[
        SheetBanner(section.title, type: type),
        _listBlock(character, section, wide),
      ],
      SheetBanner('Vantaggi e Stato', type: type),
      _tracksBlock(character, type, wide),
      for (final section in _schema.textSections) ...[
        SheetBanner(section.title, type: type),
        _textBlock(character, section, wide),
      ],
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

  Widget _identityBlock(Character character, bool wide) {
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
            onTap: () => _editText(field.key, field.label),
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
                onRoll: () => _quickRoll(trait.label, character.dot(trait.key)),
                onChanged: (v) {
                  setState(() => character.dots[trait.key] = v);
                  _save();
                },
                onEditSpecialty: trait.specialtyKey == null
                    ? null
                    : () => _editText(
                        trait.specialtyKey!,
                        'Specializzazione — ${trait.label}',
                      ),
              ),
            for (final entry in character.list(group.extraListKey))
              _TraitLine(
                label: entry.name.isEmpty ? '—' : entry.name,
                value: entry.value,
                max: max,
                onRoll: entry.name.isEmpty
                    ? null
                    : () => _quickRoll(entry.name, entry.value),
                onChanged: (v) {
                  setState(() => entry.value = v);
                  _save();
                },
              ),
          ],
        ),
    ];
    return _Grid(columns: wide ? 3 : 1, gap: 18, children: columns);
  }

  Widget _virtuesBlock(Character character) {
    return Column(
      children: [
        for (final virtue in _schema.virtues)
          _TraitLine(
            label: virtue.label,
            value: character.dot(virtue.key),
            max: _schema.virtueMax,
            onRoll: () => _quickRoll(virtue.label, character.dot(virtue.key)),
            onChanged: (v) {
              setState(() => character.dots[virtue.key] = v);
              _save();
            },
          ),
      ],
    );
  }

  Widget _listBlock(Character character, ListSection section, bool wide) {
    final entries = character.list(section.key);
    final visible = <TraitEntry>[];
    for (var i = 0; i < entries.length; i++) {
      // Si mostrano le righe stampate sulla scheda piu' tutto cio' che
      // l'utente ha effettivamente scritto.
      if (i < section.slots || !entries[i].isEmpty) visible.add(entries[i]);
    }
    if (visible.isEmpty) {
      for (var i = 0; i < section.slots; i++) {
        entries.add(TraitEntry());
        visible.add(entries.last);
      }
    }

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
                    onTap: () async {
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
                    size: 11,
                    onChanged: (v) {
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
                          onTap: () async {
                            final result = await promptForText(
                              context,
                              title: column.label,
                              initial: entry.fields[column.key] ?? '',
                            );
                            if (result == null) return;
                            setState(() => entry.fields[column.key] = result);
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
                          onTap: () async {
                            final result = await promptForText(
                              context,
                              title: 'Potere ${l + 1} — ${entry.name}',
                              initial:
                                  l < entry.lines.length ? entry.lines[l] : '',
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

    final useTwoColumns = wide || (section.lineSlots == 0 && visible.length > 6);
    return _Grid(
      columns: useTwoColumns ? 2 : 1,
      gap: 14,
      children: [for (final entry in visible) rowFor(entry)],
    );
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
                  onChanged: (v) {
                    setState(() => character.dots[track.key] = v);
                    _save();
                  },
                )
              else if (track.rowLabels.isNotEmpty)
                HealthLevels(
                  track: track,
                  states: character.track(track.key, track.length),
                  onChanged: (i, v) {
                    setState(
                      () => character.track(track.key, track.length)[i] = v,
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
                  onChanged: (i, v) {
                    setState(
                      () => character.track(track.key, track.length)[i] = v,
                    );
                    _save();
                  },
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
        onTap: () => _editText(section.key, section.title, multiline: true),
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
                        onTap: () => _editText(
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
                        onTap: () => _editText(field.key, field.label),
                      ),
                    ],
                  ),
                ),
      ],
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
    this.specialty,
    this.onRoll,
    this.onEditSpecialty,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
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
            Padding(padding: EdgeInsets.only(bottom: gap / 2), child: child),
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
