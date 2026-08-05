import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/clans.dart';
import '../../data/generations.dart';
import '../../data/schemas.dart';
import '../../models/character.dart';
import '../widgets/dots.dart';
import '../widgets/prompts.dart';
import '../widgets/tracks.dart';

/// Il modulo di inserimento dati della scheda.
///
/// Nessun campo e' obbligatorio: si puo' salvare una scheda completamente
/// vuota e riempirla piu' avanti. L'unico controllo e' sui pallini, che
/// restano nell'intervallo consentito dalla scheda scelta.
class CharacterEditPage extends StatefulWidget {
  const CharacterEditPage({
    super.key,
    required this.characterId,
    this.isNew = false,
  });

  final String characterId;
  final bool isNew;

  @override
  State<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends State<CharacterEditPage> {
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
      _prepareSlots(character);
    }
  }

  /// Prepara le righe stampate sulla scheda cosi' l'editor mostra da subito
  /// lo stesso numero di spazi del cartaceo.
  void _prepareSlots(Character character) {
    for (final section in _schema.lists) {
      final entries = character.list(section.key);
      while (entries.length < section.slots) {
        entries.add(TraitEntry());
      }
    }
    for (final group in _schema.abilities) {
      if (group.extraSlots == 0) continue;
      final entries = character.list(group.extraListKey);
      while (entries.length < group.extraSlots) {
        entries.add(TraitEntry());
      }
    }
  }

  /// Cambia a ogni precompilazione da clan. Entra nelle chiavi dei campi
  /// gia' disegnati per farli ricostruire: i TextFormField si tengono il
  /// testo che avevano, e senza questo mostrerebbero ancora le righe vuote.
  int _prefillEpoch = 0;

  /// La generazione scelta, se riconoscibile dal campo della scheda.
  GenerationRule? get _generation =>
      generationFromText(_character?.text('generation'));

  /// Scelto il clan, si scrivono le sue Discipline e la sua debolezza.
  void _applyClan(Character character, String name) {
    final clan = clanRule(character.type, name);
    if (clan == null) return;
    final filled = applyClanTemplate(character, _schema, clan);
    if (filled.isEmpty) return;
    setState(() => _prefillEpoch++);
    _save();
    final message = filled.message;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Il massimo davvero utilizzabile per un tratto.
  int _allowedFor(int sheetMax) => effectiveTraitMax(sheetMax, _generation);

  void _save() {
    final character = _character;
    if (character == null) return;
    character.updatedAt = DateTime.now();
    _state.characterRepository.saveDebounced(character);
  }

  @override
  void dispose() {
    final character = _character;
    if (character != null) {
      _state.flushAndNotifyLater(character);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = _character;
    if (character == null) {
      return const Scaffold(body: Center(child: Text('Scheda non trovata')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'NUOVA SCHEDA' : 'MODIFICA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: widget.isNew ? 'Annulla creazione' : 'Chiudi',
          onPressed: () async {
            if (!widget.isNew) {
              Navigator.pop(context);
              return;
            }
            final discard = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Annullare la creazione?'),
                content: const Text('La scheda appena creata verrà eliminata.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continua a compilare'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: VtmColors.blood,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Elimina'),
                  ),
                ],
              ),
            );
            if (discard == true && context.mounted) {
              Navigator.pop(context, false);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              widget.isNew ? 'FINE' : 'SALVA',
              style: const TextStyle(
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.w700,
                color: VtmColors.bloodBright,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          if (widget.isNew)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VtmColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A2C2E)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: VtmColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Compila quello che vuoi: puoi lasciare tutto vuoto e '
                        'riprendere più tardi. I pallini vanno da 0 a '
                        '${_schema.traitMax}.',
                        style: const TextStyle(
                          color: VtmColors.ash,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _Section(
            title: 'Identità',
            children: [
              for (final field in _schema.identity)
                _TextRow(
                  key: ValueKey('id_${field.key}_$_prefillEpoch'),
                  field: field,
                  value: character.text(field.key),
                  onChanged: (v) {
                    character.texts[field.key] = v;
                    // i menu a tendina si ridisegnano sul valore salvato;
                    // i campi liberi no, o perderebbero il cursore
                    if (field.isSelect) setState(() {});
                    _save();
                    if (field.key == 'clan') _applyClan(character, v);
                  },
                ),
            ],
          ),
          _Section(
            title: 'Attributi',
            children: [
              for (final group in _schema.attributes) ...[
                _GroupLabel(group.title),
                for (final trait in group.traits)
                  DotStepper(
                    label: trait.label,
                    value: character.dot(trait.key),
                    max: _schema.traitMax,
                    allowed: _allowedFor(_schema.traitMax),
                    onChanged: (v) {
                      setState(() => character.dots[trait.key] = v);
                      _save();
                    },
                  ),
              ],
            ],
          ),
          _Section(
            title: 'Abilità',
            children: [
              for (final group in _schema.abilities) ...[
                _GroupLabel(group.title),
                for (final trait in group.traits)
                  DotStepper(
                    label: trait.label,
                    value: character.dot(trait.key),
                    max: _schema.traitMax,
                    allowed: _allowedFor(_schema.traitMax),
                    trailing: trait.specialtyKey == null
                        ? null
                        : _SpecialtyButton(
                            value: character.text(trait.specialtyKey!),
                            label: trait.label,
                            onChanged: (v) {
                              setState(
                                () => character.texts[trait.specialtyKey!] = v,
                              );
                              _save();
                            },
                          ),
                    onChanged: (v) {
                      setState(() => character.dots[trait.key] = v);
                      _save();
                    },
                  ),
                if (group.extraSlots > 0)
                  ..._extraAbilityRows(character, group),
              ],
            ],
          ),
          if (_schema.virtues.isNotEmpty)
            _Section(
              title: 'Virtù',
              children: [
                for (final virtue in _schema.virtues)
                  DotStepper(
                    label: virtue.label,
                    value: character.dot(virtue.key),
                    max: _schema.virtueMax,
                    allowed: _allowedFor(_schema.virtueMax),
                    onChanged: (v) {
                      setState(() => character.dots[virtue.key] = v);
                      _save();
                    },
                  ),
              ],
            ),
          for (final section in _schema.lists)
            _Section(
              title: section.title,
              subtitle: section.hint,
              children: [
                _ListSectionEditor(
                  key: ValueKey('list_${section.key}_$_prefillEpoch'),
                  section: section,
                  character: character,
                  allowedDots: section.limitedByGeneration
                      ? _allowedFor(section.dotMax)
                      : section.dotMax,
                  onChanged: _save,
                ),
              ],
            ),
          _Section(
            title: 'Tracker',
            children: [
              for (final track in _schema.tracks) ...[
                _GroupLabel(
                  track.note == null
                      ? track.title
                      : '${track.title} (${track.note})',
                ),
                if (track.kind == TrackKind.dots)
                  DotStepper(
                    label: track.title,
                    value: character.dot(track.key),
                    max: track.length,
                    onChanged: (v) {
                      setState(() => character.dots[track.key] = v);
                      _save();
                    },
                  )
                else if (track.rowLabels.isNotEmpty)
                  HealthLevels(
                    track: track,
                    states: character.track(track.key, track.length),
                    color: VtmColors.ash,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      color: VtmColors.bone,
                    ),
                    onChanged: (i, v) {
                      setState(() {
                        character.track(track.key, track.length)[i] = v;
                      });
                      _save();
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: BoxTrack(
                      states: character.track(track.key, track.length),
                      maxState: track.maxState,
                      perRow: track.perRow,
                      color: VtmColors.ash,
                      filledFirst: track.firstStateFilled,
                      // la riserva di sangue dipende dalla generazione
                      allowed: track.key == 'sangue'
                          ? _generation?.bloodPool
                          : null,
                      onChanged: (i, v) {
                        setState(() {
                          character.track(track.key, track.length)[i] = v;
                        });
                        _save();
                      },
                    ),
                  ),
                if (track.stateLegend.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: Text(
                      'Tocca per cambiare stato · ${track.stateLegend.join(" · ")}',
                      style: const TextStyle(
                        color: VtmColors.ash,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          for (final section in _schema.textSections)
            _Section(
              title: section.title,
              children: [
                if (section.fields != null)
                  for (final field in section.fields!)
                    _TextRow(
                      key: ValueKey('txt_${field.key}_$_prefillEpoch'),
                      field: field,
                      value: character.text(field.key),
                      onChanged: (v) {
                        character.texts[field.key] = v;
                        _save();
                      },
                    )
                else
                  _TextRow(
                    key: ValueKey('txt_${section.key}_$_prefillEpoch'),
                    field: FieldDef(
                      section.key,
                      section.title,
                      multiline: true,
                    ),
                    value: character.text(section.key),
                    minLines: section.lines,
                    onChanged: (v) {
                      character.texts[section.key] = v;
                      _save();
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _extraAbilityRows(Character character, TraitGroup group) {
    final entries = character.list(group.extraListKey);
    return [
      for (var i = 0; i < entries.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: entries[i].name,
                  decoration: const InputDecoration(
                    hintText: 'Altra abilità',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    entries[i].name = v;
                    _save();
                  },
                ),
              ),
              const SizedBox(width: 8),
              DotRow(
                value: entries[i].value,
                max: _schema.traitMax,
                allowed: _allowedFor(_schema.traitMax),
                color: VtmColors.ash,
                filledColor: VtmColors.bloodBright,
                size: 12,
                onChanged: (v) {
                  setState(() => entries[i].value = v);
                  _save();
                },
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() => entries.add(TraitEntry()));
            _save();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Aggiungi riga'),
        ),
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: VtmColors.gold,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: VtmColors.ash, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: VtmColors.bone,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.minLines,
  });

  final FieldDef field;
  final String value;
  final ValueChanged<String> onChanged;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final lines = minLines ?? (field.multiline ? 3 : 1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: field.isSelect
          ? _SelectRow(field: field, value: value, onChanged: onChanged)
          : field.suggestions.isEmpty
          ? TextFormField(
              initialValue: value,
              decoration: InputDecoration(
                labelText: field.label,
                hintText: field.hint,
              ),
              minLines: lines,
              maxLines: field.multiline || lines > 1 ? lines + 4 : 1,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
            )
          : _SuggestField(
              label: field.label,
              value: value,
              suggestions: field.suggestions,
              onChanged: onChanged,
            ),
    );
  }
}

/// Campo a scelta chiusa: Generazione, Clan, Natura e Carattere.
///
/// Se il campo lo consente, l'ultima voce e' "Altro..." e apre la tastiera;
/// e un valore fuori elenco gia' scritto sulla scheda compare comunque nel
/// menu, altrimenti il campo lo perderebbe.
class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FieldDef field;
  final String value;
  final ValueChanged<String> onChanged;

  /// Sentinella della voce "Altro...": uno spazio davanti, cosi' non puo'
  /// coincidere con niente di scritto a mano.
  static const _writeItMyself = ' altro';

  @override
  Widget build(BuildContext context) {
    final outsideList = value.isNotEmpty && !field.options.contains(value);
    return DropdownButtonFormField<String>(
      // la chiave lega il campo al valore salvato: quando la scheda cambia
      // da sola (la scelta del clan) il menu si ridisegna aggiornato
      key: ValueKey('${field.key}_$value'),
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: InputDecoration(labelText: field.label),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— non indicato —'),
        ),
        if (outsideList)
          DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Cinzel', fontSize: 16),
            ),
          ),
        for (final option in field.options)
          DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Cinzel', fontSize: 16),
            ),
          ),
        if (field.allowCustom)
          const DropdownMenuItem<String>(
            value: _writeItMyself,
            child: Text(
              'Altro...',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 16,
                color: VtmColors.gold,
              ),
            ),
          ),
      ],
      onChanged: (v) async {
        if (v != _writeItMyself) {
          onChanged(v ?? '');
          return;
        }
        final typed = await promptForText(
          context,
          title: field.label,
          initial: value,
        );
        if (typed != null) onChanged(typed);
      },
    );
  }
}

/// Campo libero con proposte prese dalle schede ufficiali: si puo' comunque
/// scrivere qualsiasi cosa.
class _SuggestField extends StatelessWidget {
  const _SuggestField({
    required this.label,
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: value),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return suggestions;
        return suggestions.where((s) => s.toLowerCase().contains(query));
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.arrow_drop_down, color: VtmColors.ash),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: VtmColors.surfaceHigh,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 380),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final option in options)
                    InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Text(option),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpecialtyButton extends StatelessWidget {
  const _SpecialtyButton({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value.isEmpty ? 'Specializzazione' : value,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          final result = await promptForText(
            context,
            title: 'Specializzazione — $label',
            initial: value,
          );
          if (result != null) onChanged(result);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            value.isEmpty ? Icons.label_outline : Icons.label,
            size: 18,
            color: value.isEmpty ? VtmColors.ash : VtmColors.gold,
          ),
        ),
      ),
    );
  }
}

/// Editor di una sezione a elenco: Discipline, Background, Pregi, Armi...
class _ListSectionEditor extends StatefulWidget {
  const _ListSectionEditor({
    super.key,
    required this.section,
    required this.character,
    required this.allowedDots,
    required this.onChanged,
  });

  final ListSection section;
  final Character character;

  /// Pallini utilizzabili: gia' ridotti dalla generazione dove serve.
  final int allowedDots;

  final VoidCallback onChanged;

  @override
  State<_ListSectionEditor> createState() => _ListSectionEditorState();
}

class _ListSectionEditorState extends State<_ListSectionEditor> {
  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final entries = widget.character.list(section.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: section.suggestions.isEmpty
                          ? TextFormField(
                              key: ValueKey('${section.key}_$i'),
                              initialValue: entries[i].name,
                              decoration: InputDecoration(
                                hintText: section.nameLabel,
                                isDense: true,
                              ),
                              onChanged: (v) {
                                entries[i].name = v;
                                widget.onChanged();
                              },
                            )
                          : _SuggestField(
                              label: section.nameLabel,
                              value: entries[i].name,
                              suggestions: section.suggestions,
                              onChanged: (v) {
                                entries[i].name = v;
                                widget.onChanged();
                              },
                            ),
                    ),
                    if (entries.length > section.slots)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        tooltip: 'Rimuovi riga',
                        onPressed: () {
                          setState(() => entries.removeAt(i));
                          widget.onChanged();
                        },
                      ),
                  ],
                ),
                if (section.hasDots)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        DotRow(
                          value: entries[i].value,
                          max: section.dotMax,
                          allowed: widget.allowedDots,
                          color: VtmColors.ash,
                          filledColor: VtmColors.bloodBright,
                          size: 12,
                          onChanged: (v) {
                            setState(() => entries[i].value = v);
                            widget.onChanged();
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${entries[i].value} / ${widget.allowedDots}',
                          style: const TextStyle(
                            color: VtmColors.ash,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (section.columns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        for (final column in section.columns) ...[
                          Expanded(
                            flex: column.flex,
                            child: TextFormField(
                              key: ValueKey(
                                '${section.key}_${i}_${column.key}',
                              ),
                              initialValue: entries[i].fields[column.key] ?? '',
                              decoration: InputDecoration(
                                hintText: column.label,
                                isDense: true,
                              ),
                              onChanged: (v) {
                                entries[i].fields[column.key] = v;
                                widget.onChanged();
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
                    padding: const EdgeInsets.only(top: 6, left: 10),
                    child: Column(
                      children: [
                        for (var l = 0; l < section.lineSlots; l++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: TextFormField(
                              key: ValueKey('${section.key}_${i}_line$l'),
                              initialValue: l < entries[i].lines.length
                                  ? entries[i].lines[l]
                                  : '',
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Potere ${l + 1}',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (v) {
                                while (entries[i].lines.length <= l) {
                                  entries[i].lines.add('');
                                }
                                entries[i].lines[l] = v;
                                widget.onChanged();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => entries.add(TraitEntry()));
              widget.onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Aggiungi voce'),
          ),
        ),
      ],
    );
  }
}
