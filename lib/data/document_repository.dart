import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Un PDF importato dall'utente e copiato nella memoria privata dell'app.
class LocalDocument {
  LocalDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.sizeBytes,
    required this.addedAt,
    this.lastPage = 1,
  });

  final String id;
  String title;
  final String fileName;
  final int sizeBytes;
  final DateTime addedAt;

  /// Ultima pagina letta, per riprendere la consultazione da dove si era.
  int lastPage;

  String get readableSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= 1024) return '${(sizeBytes / 1024).round()} KB';
    return '$sizeBytes B';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'addedAt': addedAt.toIso8601String(),
    'lastPage': lastPage,
  };

  static LocalDocument fromJson(Map<String, dynamic> json) => LocalDocument(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Documento',
    fileName: json['fileName'] as String,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    addedAt:
        DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
    lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
  );
}

/// Gestisce la libreria di PDF salvati sul dispositivo.
class DocumentRepository {
  DocumentRepository({Directory? overrideDir}) : _overrideDir = overrideDir;

  final Directory? _overrideDir;
  Directory? _dir;

  Future<Directory> _directory() async {
    if (_dir != null) return _dir!;
    final base = _overrideDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'documenti'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _dir = dir;
  }

  Future<File> _indexFile() async =>
      File(p.join((await _directory()).path, 'indice.json'));

  Future<List<LocalDocument>> loadAll() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      final docs = list
          .map((e) => LocalDocument.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      docs.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return docs;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeIndex(List<LocalDocument> docs) async {
    final file = await _indexFile();
    await file.writeAsString(
      jsonEncode(docs.map((d) => d.toJson()).toList()),
      flush: true,
    );
  }

  Future<String> pathOf(LocalDocument doc) async =>
      p.join((await _directory()).path, doc.fileName);

  /// Copia il PDF scelto dentro l'app: da quel momento e' consultabile anche
  /// senza il file originale e senza connessione.
  Future<LocalDocument> import({
    required String sourcePath,
    required String id,
    required String title,
  }) async {
    final dir = await _directory();
    final fileName = '$id.pdf';
    final dest = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(dest.path);

    final doc = LocalDocument(
      id: id,
      title: title,
      fileName: fileName,
      sizeBytes: await dest.length(),
      addedAt: DateTime.now(),
    );
    final docs = await loadAll();
    docs.insert(0, doc);
    await _writeIndex(docs);
    return doc;
  }

  Future<void> update(LocalDocument doc) async {
    final docs = await loadAll();
    final index = docs.indexWhere((d) => d.id == doc.id);
    if (index >= 0) {
      docs[index] = doc;
      await _writeIndex(docs);
    }
  }

  Future<void> delete(LocalDocument doc) async {
    final docs = await loadAll();
    docs.removeWhere((d) => d.id == doc.id);
    await _writeIndex(docs);
    final file = File(await pathOf(doc));
    if (await file.exists()) await file.delete();
  }
}
