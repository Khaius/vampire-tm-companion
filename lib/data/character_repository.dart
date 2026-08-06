import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/character.dart';

/// Riduce la foto a qualcosa che stia in tasca.
///
/// Le foto di un telefono moderno pesano diversi megabyte l'una: cosi' come
/// sono renderebbero enormi sia la cartella dell'app sia i file esportati,
/// che devono poter passare da WhatsApp. Mille pixel sul lato lungo sono piu'
/// che sufficienti per un ritratto in una scheda.
Uint8List _shrinkPhoto(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  final resized = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: 1024)
      : img.copyResize(decoded, height: 1024);
  final source = (decoded.width <= 1024 && decoded.height <= 1024)
      ? decoded
      : resized;
  return img.encodeJpg(source, quality: 85);
}

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

  // ------------------------------------------------------------------ foto

  Future<Directory> _photoDirectory() async {
    final base = _overrideDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'foto'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Il percorso su disco della foto di una scheda, o null se non c'e'.
  Future<String?> photoPath(Character character) async {
    final name = character.photoFile;
    if (name == null) return null;
    final dir = await _photoDirectory();
    final file = File(p.join(dir.path, name));
    return await file.exists() ? file.path : null;
  }

  /// Copia nella cartella dell'app la foto scelta dal telefono.
  ///
  /// L'immagine viene rimpicciolita e riscritta in JPEG: da quel momento la
  /// scheda non dipende piu' dal file originale, che puo' anche sparire.
  Future<String> setPhotoFromFile(Character character, String sourcePath) =>
      _writePhoto(character, File(sourcePath).readAsBytesSync());

  /// Come [setPhotoFromFile], ma partendo dai byte: serve all'importazione,
  /// dove la foto arriva dentro al pacchetto.
  Future<String> setPhotoFromBytes(Character character, Uint8List bytes) =>
      _writePhoto(character, bytes);

  Future<String> _writePhoto(Character character, Uint8List raw) async {
    // il ridimensionamento e' lavoro pesante: fuori dal filo dell'interfaccia
    final small = await Isolate.run(() => _shrinkPhoto(raw));
    final dir = await _photoDirectory();
    final name = '${character.id}.jpg';
    await File(p.join(dir.path, name)).writeAsBytes(small, flush: true);
    character.photoFile = name;
    return name;
  }

  Future<void> removePhoto(Character character) async {
    final name = character.photoFile;
    character.photoFile = null;
    if (name == null) return;
    final dir = await _photoDirectory();
    final file = File(p.join(dir.path, name));
    if (await file.exists()) await file.delete();
  }

  /// I byte della foto, per l'esportazione.
  Future<Uint8List?> photoBytes(Character character) async {
    final path = await photoPath(character);
    if (path == null) return null;
    return File(path).readAsBytes();
  }
}
