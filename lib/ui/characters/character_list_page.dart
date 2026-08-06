import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/character_transfer.dart';
import '../../models/character.dart';
import '../../models/sheet_type.dart';
import '../shell/nav_icons.dart';
import '../widgets/character_photo.dart';
import 'character_edit_page.dart';
import 'sheet_page.dart';

/// L'elenco delle schede salvate sul telefono.
class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  /// Fuori dalla modalita' esportazione e' null; dentro contiene gli id
  /// spuntati, anche zero.
  Set<String>? _picked;

  bool get _picking => _picked != null;

  Future<void> _createNew(BuildContext context) async {
    final type = await Navigator.of(context).push<SheetType>(
      MaterialPageRoute(builder: (_) => const _TypePickerPage()),
    );
    if (type == null || !context.mounted) return;

    final state = context.read<AppState>();
    final character = state.createCharacter(type);

    final kept = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CharacterEditPage(characterId: character.id, isNew: true),
      ),
    );
    if (!context.mounted) return;

    if (kept == false) {
      await state.deleteCharacter(character);
      return;
    }
    state.selectCharacter(character.id);
    if (!context.mounted) return;
    Navigator.of(context).push(sheetPageRoute(character.id));
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Importa le schede da un file esportato.
  Future<void> _import() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Schede VtM',
          extensions: ['json'],
          mimeTypes: ['application/json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (file == null) return;

    final result = decodeTransfer(await file.readAsString());
    if (!result.isOk) {
      _say(result.error!);
      return;
    }
    if (!mounted) return;
    final added = await context.read<AppState>().importCharacters(
      result.characters,
    );
    _say(
      added.length == 1
          ? 'Importata la scheda di ${added.single.displayName}.'
          : 'Importate ${added.length} schede.',
    );
  }

  /// Scrive il pacchetto e lo passa al pannello di condivisione.
  Future<void> _export(List<Character> characters) async {
    if (characters.isEmpty) return;
    final state = context.read<AppState>();
    File file;
    try {
      file = await state.exportCharacters(characters);
    } catch (_) {
      _say('Non è stato possibile preparare il file da esportare.');
      return;
    }
    setState(() => _picked = null);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: characters.length == 1
            ? 'Scheda di ${characters.single.displayName}'
            : 'Schede di VtM Companion',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = context.select<AppState, List<Character>>(
      (s) => s.characters,
    );
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(
        title: Text(_picking ? 'ESPORTA' : 'SCHEDE'),
        leading: _picking
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Annulla',
                onPressed: () => setState(() => _picked = null),
              )
            : null,
        actions: [
          if (!_picking)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Azioni sulle schede',
              onSelected: (value) async {
                switch (value) {
                  case 'new':
                    await _createNew(context);
                  case 'import':
                    await _import();
                  case 'export':
                    if (characters.isEmpty) {
                      _say('Non c\'è ancora nessuna scheda da esportare.');
                      return;
                    }
                    setState(() => _picked = <String>{});
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'new',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add),
                    title: Text('Nuova scheda'),
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.file_download_outlined),
                    title: Text('Importa'),
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.ios_share),
                    title: Text('Esporta'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          if (characters.isEmpty)
            const _EmptyState()
          else
            ListView.separated(
              padding: EdgeInsets.fromLTRB(14, 10, 14, _picking ? 96 : 30),
              itemCount: characters.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final character = characters[index];
                return _CharacterCard(
                  character: character,
                  picked: picked?.contains(character.id),
                  onPick: picked == null
                      ? null
                      : () => setState(() {
                          if (!picked.remove(character.id)) {
                            picked.add(character.id);
                          }
                        }),
                );
              },
            ),
          if (picked != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ExportBar(
                selected: picked.length,
                total: characters.length,
                onSelectAll: () => setState(() {
                  if (picked.length == characters.length) {
                    picked.clear();
                  } else {
                    picked
                      ..clear()
                      ..addAll(characters.map((c) => c.id));
                  }
                }),
                onExport: () => _export(
                  characters.where((c) => picked.contains(c.id)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La barra che compare durante l'esportazione, sopra al menu in basso.
class _ExportBar extends StatelessWidget {
  const _ExportBar({
    required this.selected,
    required this.total,
    required this.onSelectAll,
    required this.onExport,
  });

  final int selected;
  final int total;
  final VoidCallback onSelectAll;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final all = selected == total && total > 0;
    return Material(
      color: VtmColors.surfaceHigh,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectAll,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        all ? Icons.check_box : Icons.check_box_outline_blank,
                        color: VtmColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          all ? 'Deseleziona tutto' : 'Seleziona tutto',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 15,
                            color: VtmColors.bone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1, indent: 10, endIndent: 10),
              Expanded(
                child: InkWell(
                  onTap: selected == 0 ? null : onExport,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ios_share,
                        color: selected == 0
                            ? VtmColors.ash
                            : VtmColors.bloodBright,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          selected == 0 ? 'Esporta' : 'Esporta ($selected)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 15,
                            color: selected == 0
                                ? VtmColors.ash
                                : VtmColors.bone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VtmIcon(VtmIcons.scroll, size: 64, color: Color(0xFF4A3B3D)),
            const SizedBox(height: 22),
            Text(
              'Nessuna scheda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Apri il menu in alto a destra: da lì crei la tua prima scheda '
              'scegliendo fra le tre edizioni, oppure importi una scheda che '
              'ti hanno mandato.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VtmColors.ash, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, this.picked, this.onPick});

  final Character character;

  /// Null fuori dalla modalita' esportazione; dentro dice se e' spuntata.
  final bool? picked;
  final VoidCallback? onPick;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la scheda?'),
        content: Text(
          '"${character.displayName}" verrà cancellata dal dispositivo. '
          'L\'operazione non è reversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VtmColors.blood),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteCharacter(character);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isSelected = context.select<AppState, bool>(
      (s) => s.selectedCharacterId == character.id,
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? VtmColors.blood : const Color(0xFF3A2C2E),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            onPick ??
            () {
              state.selectCharacter(character.id);
              Navigator.of(context).push(sheetPageRoute(character.id));
            },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              if (picked != null) ...[
                Icon(
                  picked! ? Icons.check_box : Icons.check_box_outline_blank,
                  color: picked! ? VtmColors.bloodBright : VtmColors.ash,
                ),
                const SizedBox(width: 12),
              ],
              _CharacterAvatar(character: character),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.displayName,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      character.subtitleLine.isEmpty
                          ? character.type.subtitle
                          : character.subtitleLine,
                      style: const TextStyle(
                        color: VtmColors.ash,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (picked != null)
                const SizedBox(width: 8)
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CharacterEditPage(characterId: character.id),
                          ),
                        );
                      case 'duplicate':
                        await state.duplicateCharacter(character);
                      case 'delete':
                        await _confirmDelete(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifica dati')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il quadratino a sinistra della riga: la foto se c'e', altrimenti la
/// sigla dell'edizione.
class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: character.type.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: character.type.accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        character.type == SheetType.darkAges ? 'SB' : character.type.shortLabel,
        style: const TextStyle(
          fontFamily: 'Cinzel',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
    if (character.photoFile == null) return badge;
    return CharacterPhoto(
      state: context.read<AppState>(),
      character: character,
      size: 44,
      placeholder: badge,
    );
  }
}

/// Primo passo della creazione: si sceglie subito il tipo di scheda.
class _TypePickerPage extends StatelessWidget {
  const _TypePickerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NUOVA SCHEDA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Scegli l\'edizione: la scheda verrà creata e disegnata come '
              'l\'originale cartaceo.',
              style: TextStyle(color: VtmColors.ash, height: 1.4),
            ),
          ),
          for (final type in SheetType.values) ...[
            _TypeCard(type: type),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final SheetType type;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, type),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: type.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.shortLabel.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'max ${type.traitMax} pallini',
                    style: const TextStyle(color: VtmColors.ash, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                type.title,
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                type.subtitle,
                style: const TextStyle(color: VtmColors.gold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                type.description,
                style: const TextStyle(
                  color: VtmColors.ash,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
