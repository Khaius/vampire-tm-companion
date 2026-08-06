import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/character_repository.dart';
import '../data/character_transfer.dart';
import '../data/document_repository.dart';
import '../models/character.dart';
import '../models/dice.dart';
import '../models/sheet_type.dart';

/// Richiesta di tiro rapido partita da un tratto della scheda.
class QuickRollRequest {
  const QuickRollRequest(this.pool, this.label);
  final int pool;
  final String label;
}

/// Stato condiviso dell'applicazione. Tutto vive in locale: le schede e i
/// documenti su disco, la selezione corrente e lo storico dei tiri solo in
/// memoria, cosi' a ogni riavvio si riparte dalla lista delle schede.
class AppState extends ChangeNotifier {
  AppState({
    CharacterRepository? characterRepository,
    DocumentRepository? documentRepository,
  }) : _characters = characterRepository ?? CharacterRepository(),
       _documents = documentRepository ?? DocumentRepository();

  final CharacterRepository _characters;
  final DocumentRepository _documents;
  static const _uuid = Uuid();

  CharacterRepository get characterRepository => _characters;
  DocumentRepository get documentRepository => _documents;

  bool _ready = false;
  bool get ready => _ready;

  List<Character> _all = [];
  List<Character> get characters => List.unmodifiable(_all);

  List<LocalDocument> _docs = [];
  List<LocalDocument> get documents => List.unmodifiable(_docs);

  /// Scheda aperta: resta selezionata finche' l'utente non la chiude a mano.
  String? _selectedId;
  String? get selectedCharacterId => _selectedId;

  Character? get selectedCharacter {
    final id = _selectedId;
    if (id == null) return null;
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  final List<DiceRoll> _history = [];
  List<DiceRoll> get rollHistory => List.unmodifiable(_history);

  QuickRollRequest? _quickRoll;
  QuickRollRequest? get quickRoll => _quickRoll;

  /// Richiesta di passare a una sezione del menu in basso, usata dal tiro
  /// rapido per portare l'utente sui dadi.
  final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  int _dicePool = 1;
  int get dicePool => _dicePool;

  int _difficulty = 6;
  int get difficulty => _difficulty;

  Future<void> init() async {
    _all = await _characters.loadAll();
    _docs = await _documents.loadAll();
    _ready = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- schede

  Character createCharacter(SheetType type) {
    final character = Character(id: _uuid.v4(), type: type);
    _all.insert(0, character);
    _characters.save(character);
    notifyListeners();
    return character;
  }

  Character? characterById(String id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Da chiamare dopo ogni modifica in scheda: aggiorna la data e programma
  /// il salvataggio su disco.
  void touch(Character character, {bool immediate = false}) {
    character.updatedAt = DateTime.now();
    if (immediate) {
      _characters.flush(character);
    } else {
      _characters.saveDebounced(character);
    }
    notifyListeners();
  }

  /// Salva subito e avvisa gli ascoltatori al frame successivo.
  ///
  /// Serve quando si esce da una pagina: durante lo smontaggio dell'albero
  /// widget Flutter vieta di far ricostruire altri rami, quindi la notifica
  /// va rimandata.
  void flushAndNotifyLater(Character character) {
    character.updatedAt = DateTime.now();
    _characters.flush(character);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      notifyListeners();
    });
  }

  Future<void> deleteCharacter(Character character) async {
    _all.removeWhere((c) => c.id == character.id);
    if (_selectedId == character.id) _selectedId = null;
    await _characters.removePhoto(character);
    await _characters.delete(character.id);
    notifyListeners();
  }

  // ------------------------------------------------------------------ foto

  Future<void> setPhoto(Character character, String sourcePath) async {
    await _characters.setPhotoFromFile(character, sourcePath);
    touch(character, immediate: true);
  }

  Future<void> removePhoto(Character character) async {
    await _characters.removePhoto(character);
    touch(character, immediate: true);
  }

  // --------------------------------------------------- esporta e importa

  /// Scrive il pacchetto delle schede scelte e ne restituisce il file.
  ///
  /// Il file finisce nella cartella di appoggio dell'app: da li' lo prende
  /// il pannello di condivisione del telefono. Non serve nessun permesso,
  /// perche' non usciamo mai dallo spazio dell'app finche' non e' l'utente
  /// a decidere dove mandarlo.
  Future<File> exportCharacters(
    List<Character> characters, {
    Directory? overrideDir,
  }) async {
    final photos = <String, Uint8List>{};
    for (final character in characters) {
      final bytes = await _characters.photoBytes(character);
      if (bytes != null) photos[character.id] = bytes;
    }

    final base =
        overrideDir ??
        await getTemporaryDirectory().catchError(
          (_) async => getApplicationDocumentsDirectory(),
        );
    final dir = Directory(p.join(base.path, 'export'));
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File(p.join(dir.path, CharacterTransfer.fileName(characters)));
    await file.writeAsString(
      CharacterTransfer.encode(characters, photos: photos),
      flush: true,
    );
    return file;
  }

  /// Aggiunge alla raccolta le schede lette da un file esportato.
  ///
  /// Ogni scheda entra sempre come scheda nuova, con un id suo: reimportare
  /// un file non sovrascrive mai il lavoro fatto sul telefono. Se la stessa
  /// scheda c'era gia', il nome lo dice.
  Future<List<Character>> importCharacters(
    List<ImportedCharacter> imported,
  ) async {
    final existingIds = _all.map((c) => c.id).toSet();
    final added = <Character>[];

    for (final entry in imported) {
      final source = entry.character;
      final copy = Character(
        id: _uuid.v4(),
        type: source.type,
        texts: Map<String, String>.from(source.texts),
        dots: Map<String, int>.from(source.dots),
        lists: source.lists.map(
          (k, v) => MapEntry(k, v.map((e) => e.copy()).toList()),
        ),
        tracks: source.tracks.map((k, v) => MapEntry(k, List<int>.from(v))),
        collapsed: Set<String>.from(source.collapsed),
      );
      if (existingIds.contains(source.id)) {
        copy.texts['name'] = '${source.displayName} (importata)';
      }
      if (entry.photo != null) {
        await _characters.setPhotoFromBytes(copy, entry.photo!);
      }
      await _characters.save(copy);
      _all.insert(0, copy);
      added.add(copy);
    }

    notifyListeners();
    return added;
  }

  Future<Character> duplicateCharacter(Character source) async {
    final copy = Character(
      id: _uuid.v4(),
      type: source.type,
      texts: Map<String, String>.from(source.texts),
      dots: Map<String, int>.from(source.dots),
      lists: source.lists.map(
        (k, v) => MapEntry(k, v.map((e) => e.copy()).toList()),
      ),
      tracks: source.tracks.map((k, v) => MapEntry(k, List<int>.from(v))),
      collapsed: Set<String>.from(source.collapsed),
    );
    copy.texts['name'] = '${source.displayName} (copia)';
    final photo = await _characters.photoBytes(source);
    if (photo != null) await _characters.setPhotoFromBytes(copy, photo);
    _all.insert(0, copy);
    await _characters.save(copy);
    notifyListeners();
    return copy;
  }

  void selectCharacter(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Chiusura manuale della scheda: solo cosi' il menu in basso torna a
  /// mostrare la lista invece della scheda aperta.
  void closeSelectedCharacter() {
    if (_selectedId == null) return;
    _selectedId = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ documenti

  Future<LocalDocument> importDocument({
    required String sourcePath,
    required String title,
  }) async {
    final doc = await _documents.import(
      sourcePath: sourcePath,
      id: _uuid.v4(),
      title: title,
    );
    _docs = await _documents.loadAll();
    notifyListeners();
    return doc;
  }

  Future<void> deleteDocument(LocalDocument doc) async {
    await _documents.delete(doc);
    _docs = await _documents.loadAll();
    notifyListeners();
  }

  Future<void> renameDocument(LocalDocument doc, String title) async {
    doc.title = title;
    await _documents.update(doc);
    notifyListeners();
  }

  Future<void> rememberPage(LocalDocument doc, int page) async {
    if (doc.lastPage == page) return;
    doc.lastPage = page;
    await _documents.update(doc);
  }

  // ----------------------------------------------------------------- dadi

  void setDicePool(int value) {
    final clamped = value.clamp(1, 99);
    if (_dicePool == clamped) return;
    _dicePool = clamped;
    notifyListeners();
  }

  void setDifficulty(int value) {
    final clamped = value.clamp(2, 10);
    if (_difficulty == clamped) return;
    _difficulty = clamped;
    notifyListeners();
  }

  DiceRoll roll({String? label}) {
    final result = DiceRoll.roll(
      pool: _dicePool,
      difficulty: _difficulty,
      label: label,
    );
    _history.insert(0, result);
    if (_history.length > 30) _history.removeLast();
    notifyListeners();
    return result;
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    tabRequest.dispose();
    super.dispose();
  }

  /// Prepara il tiro con i dadi di un tratto toccato sulla scheda e porta
  /// l'utente sulla schermata dei dadi.
  void requestQuickRoll(int pool, String label) {
    _dicePool = pool.clamp(1, 99);
    _quickRoll = QuickRollRequest(_dicePool, label);
    notifyListeners();
    tabRequest.value = 1;
  }

  void consumeQuickRoll() {
    if (_quickRoll == null) return;
    _quickRoll = null;
    notifyListeners();
  }
}
