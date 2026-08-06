import 'dart:convert';
import 'dart:typed_data';

import '../models/character.dart';

/// Esportazione e importazione delle schede.
///
/// Il formato e' un unico file JSON con dentro tutte le schede scelte, foto
/// comprese (in base64). Un solo file perche' deve poter passare da WhatsApp
/// o da una mail senza istruzioni: chi lo riceve lo apre con l'app e le
/// schede entrano.
///
/// JSON e non un formato binario per un motivo preciso: se un giorno l'app
/// non ci fosse piu', il file resta leggibile con un editor di testo. Le
/// schede di una cronaca lunga meritano di sopravvivere all'app.
class CharacterTransfer {
  /// Marca del formato. Serve a distinguere il file da un JSON qualsiasi.
  static const format = 'vtm-companion.schede';

  /// Versione del formato: si alza solo se la struttura cambia in modo
  /// incompatibile, cosi' una versione futura sa cosa ha in mano.
  static const version = 1;

  /// Costruisce il contenuto del file da esportare.
  ///
  /// [photos] associa l'id della scheda ai byte della sua foto: le foto
  /// vengono incluse perche' senza, chi riceve la scheda riceve mezzo
  /// personaggio.
  static String encode(
    List<Character> characters, {
    Map<String, Uint8List> photos = const {},
    String? appVersion,
  }) {
    final payload = <String, dynamic>{
      'format': format,
      'version': version,
      'app': ?appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'characters': [
        for (final character in characters)
          <String, dynamic>{
            ...character.toJson(),
            if (photos[character.id] case final bytes?)
              'photoData': base64Encode(bytes),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Nome suggerito per il file esportato.
  ///
  /// Una scheda sola porta il nome del personaggio: chi lo riceve capisce
  /// cos'e' senza aprirlo.
  static String fileName(List<Character> characters, {DateTime? now}) {
    final stamp = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    if (characters.length == 1) {
      final clean = characters.single.displayName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      return '${clean.isEmpty ? "scheda" : clean}-$stamp.vtm.json';
    }
    return 'schede-${characters.length}-$stamp.vtm.json';
  }
}

/// Una scheda letta da un file, con la sua foto se c'era.
class ImportedCharacter {
  const ImportedCharacter(this.character, this.photo);
  final Character character;
  final Uint8List? photo;
}

/// Quello che il file conteneva, o il motivo per cui non si e' potuto usare.
class ImportResult {
  const ImportResult.ok(this.characters) : error = null;
  const ImportResult.failed(this.error) : characters = const [];

  final List<ImportedCharacter> characters;

  /// Messaggio gia' pronto da mostrare, in italiano: l'errore lo legge chi
  /// gioca, non chi programma.
  final String? error;

  bool get isOk => error == null;
}

/// Legge un file esportato.
///
/// Non si fida di niente: un file scelto per sbaglio, troncato a meta' da
/// una chat o scritto per un'altra app non deve mandare in crisi l'app, deve
/// solo produrre un messaggio comprensibile.
ImportResult decodeTransfer(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const ImportResult.failed(
      'Il file non è leggibile: potrebbe essersi rovinato durante il '
      'trasferimento.',
    );
  }

  if (decoded is! Map) {
    return const ImportResult.failed(
      'Questo file non contiene schede di VtM Companion.',
    );
  }
  if (decoded['format'] != CharacterTransfer.format) {
    return const ImportResult.failed(
      'Questo file non è un\'esportazione di VtM Companion.',
    );
  }
  final fileVersion = (decoded['version'] as num?)?.toInt() ?? 0;
  if (fileVersion > CharacterTransfer.version) {
    return const ImportResult.failed(
      'Il file è stato creato con una versione più recente dell\'app: '
      'aggiornala e riprova.',
    );
  }

  final raws = decoded['characters'];
  if (raws is! List || raws.isEmpty) {
    return const ImportResult.failed('Il file non contiene nessuna scheda.');
  }

  final characters = <ImportedCharacter>[];
  for (final entry in raws) {
    if (entry is! Map) continue;
    try {
      final json = Map<String, dynamic>.from(entry);
      final photo = json.remove('photoData');
      characters.add(
        ImportedCharacter(
          Character.fromJson(json),
          photo is String ? base64Decode(photo) : null,
        ),
      );
    } catch (_) {
      // una scheda illeggibile non deve far perdere le altre
    }
  }

  if (characters.isEmpty) {
    return const ImportResult.failed(
      'Le schede contenute nel file non sono leggibili.',
    );
  }
  return ImportResult.ok(characters);
}
