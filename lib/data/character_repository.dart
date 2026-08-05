import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/character.dart';

/// Archivio delle schede: un file JSON per personaggio nella cartella privata
/// dell'app. Nessuna rete, nessun database: lettura e scrittura dirette, cosi'
/// l'avvio resta immediato anche su telefoni lenti.
class CharacterRepository {
  CharacterRepository({Directory? overrideDir}) : _overrideDir = overrideDir;

  final Directory? _overrideDir;
  Directory? _dir;

  final Map<String, Timer> _pendingWrites = {};

  Future<Directory> _directory() async {
    if (_dir != null) return _dir!;
    final base = _overrideDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'schede'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _dir = dir;
  }

  Future<List<Character>> loadAll() async {
    final dir = await _directory();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final characters = <Character>[];
    for (final file in files) {
      try {
        final raw = await file.readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        characters.add(Character.fromJson(json));
      } catch (_) {
        // Un file corrotto non deve impedire l'apertura delle altre schede.
      }
    }
    characters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return characters;
  }

  Future<void> save(Character character) async {
    final dir = await _directory();
    final file = File(p.join(dir.path, '${character.id}.json'));
    await file.writeAsString(jsonEncode(character.toJson()), flush: true);
  }

  /// Salvataggio ritardato: durante la modifica interattiva della scheda i
  /// tocchi sui pallini sono continui, si scrive su disco quando l'utente
  /// smette per un attimo.
  void saveDebounced(
    Character character, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _pendingWrites[character.id]?.cancel();
    _pendingWrites[character.id] = Timer(delay, () {
      _pendingWrites.remove(character.id);
      save(character);
    });
  }

  Future<void> flush(Character character) async {
    _pendingWrites.remove(character.id)?.cancel();
    await save(character);
  }

  Future<void> delete(String id) async {
    _pendingWrites.remove(id)?.cancel();
    final dir = await _directory();
    final file = File(p.join(dir.path, '$id.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
