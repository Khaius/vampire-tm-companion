import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/character.dart';
import '../../models/sheet_type.dart';
import '../shell/nav_icons.dart';
import 'character_edit_page.dart';
import 'sheet_page.dart';

/// L'elenco delle schede salvate sul telefono.
class CharacterListPage extends StatelessWidget {
  const CharacterListPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final characters = context.select<AppState, List<Character>>(
      (s) => s.characters,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('SCHEDE')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNew(context),
        tooltip: 'Nuova scheda',
        child: const Icon(Icons.add, size: 30),
      ),
      body: characters.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
              itemCount: characters.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _CharacterCard(character: characters[index]),
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
              'Tocca il "+" in basso a destra per creare la tua prima scheda '
              'e scegliere fra le tre edizioni disponibili.',
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
  const _CharacterCard({required this.character});

  final Character character;

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
        onTap: () {
          state.selectCharacter(character.id);
          Navigator.of(context).push(sheetPageRoute(character.id));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: character.type.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: character.type.accent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  character.type == SheetType.darkAges
                      ? 'SB'
                      : character.type.shortLabel,
                  style: const TextStyle(
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
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
