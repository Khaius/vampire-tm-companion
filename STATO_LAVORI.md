# Stato dei lavori — VtM Companion

Documento di ripresa: cosa è fatto, cosa manca e come ripartire se la
sessione si interrompe.

**Ultimo aggiornamento:** 5 agosto 2026
**Branch:** `claude/vtm-flutter-app-lde0ch` (pushato su
`Khaius/vampire-tm-companion`)
**Ultimo commit:** `2baf2c1` — *App Flutter per Vampire: The Masquerade*

---

## In una riga

L'app è **completa e funzionante**: 127 file, 35 test verdi, analisi statica
pulita, tutto committato e pushato. Resta solo da **verificare che la
pipeline GitHub Actions abbia prodotto l'APK** e passarti il link.

---

## Cosa è stato consegnato

### Funzionalità richieste

| Richiesta | Stato | Dove |
|---|---|---|
| CRUD schede delle 3 edizioni | ✅ | `lib/ui/characters/`, `lib/data/schema_*.dart` |
| Tiro dei d10 | ✅ | `lib/ui/dice/dice_page.dart` |
| Caricare e consultare PDF locali | ✅ | `lib/ui/documents/` |
| Menu sempre visibile in basso con 3 icone | ✅ | `lib/ui/shell/bottom_menu.dart` |
| Icona papiro / d10 / libro con stelline | ✅ | `assets/icons/*.svg`, disegnate a mano |
| Scheda selezionata riaperta dal menu finché non chiusa | ✅ | `lib/ui/shell/root_shell.dart` (`_restoreSheet`) |
| "+" per nuova scheda, tipo scelto subito | ✅ | `lib/ui/characters/character_list_page.dart` |
| Nessuna validazione tranne i pallini | ✅ | `lib/ui/widgets/dots.dart` (`promptForNumber`) |
| Scheda renderizzata come il PDF | ✅ | `lib/ui/characters/sheet_page.dart` + `widgets/parchment.dart` |
| "+" tondo in basso a destra per i PDF | ✅ | `lib/ui/documents/documents_page.dart` |
| Dadi: d10 in alto, contatore ±, difficoltà, colori, totale | ✅ | `lib/ui/dice/dice_page.dart` |
| Icona di lancio dell'app | ✅ | `tool/generate_icons.py`, PNG già generati |

### Decisioni prese con te (risposte alle domande iniziali)

1. **Pallini Secoli Bui: massimo 9**, come stampato sul PDF (V5 e V20 → 5).
2. **Scheda interattiva al tocco**: pallini, salute, volontà, sangue si
   cambiano direttamente; le righe si toccano per scrivere.
3. **Consegna dell'APK via GitHub Actions** (l'SDK Android è bloccato dalla
   policy di rete di questo ambiente, non si può compilare qui).
4. **Extra dadi**: storico dei tiri della sessione + tiro rapido toccando il
   nome di un tratto sulla scheda. (Niente regola del fallimento critico:
   non l'hai scelta.)

### Dati estratti dai tuoi PDF

Non sono stati inventati: ho estratto testo, campi form e contato i pallini
pixel per pixel dai tre allegati.

- **Limiti pallini**: V5 5 · V20 5 · Secoli Bui 9 (verificato contando i
  glifi "O" riga per riga nel PDF).
- **Tracker**: V5 Salute 15 / Volontà 15 / Umanità 10 / Fame 5 / Potenza del
  Sangue 10; V20 Salute 7 livelli / Volontà 10+10 / Sangue 20; Secoli Bui
  Salute 7 / Volontà 10+10 / Sentiero 10 / Sangue 50.
- **Liste ufficiali** prese dai menu a tendina della scheda V5: 13 clan,
  10 predatori, 12 discipline, background, 18 meriti, 38 difetti,
  risonanze, tratti del rifugio.

---

## Stato tecnico

```
35 test verdi        flutter test
0 problemi           flutter analyze
11 golden            test/goldens/*.png (schermate di riferimento)
```

I golden sono stati **guardati uno per uno** per verificare che la resa
grafica somigliasse ai PDF: intestazione, cornice, righe puntinate, colonne
dei pallini allineate, colori dei dadi.

### Bug trovati e corretti durante la verifica

1. `notifyListeners()` chiamato in `dispose()` → crash "widget tree was
   locked". Risolto con `AppState.flushAndNotifyLater()`.
2. Notifica post-frame su `AppState` già distrutto. Risolto con flag
   `_disposed`.
3. Overflow orizzontali su schermi stretti (righe dei tratti, banner delle
   sezioni, pannello dei risultati).
4. Font EB Garamond non ereditato da alcuni stili del tema (sarebbe uscito
   Roboto sul telefono).
5. Colonne dei pallini non allineate: ora sono incolonnate come sul cartaceo.
6. Golden dei dadi non deterministico → seme fisso via `DiceRoll.random`.

---

## Cosa manca (unico punto aperto)

**Verificare l'esito della build su GitHub Actions e recuperare l'APK.**

Al momento della pausa la run era *in corso*:

- Run: https://github.com/Khaius/vampire-tm-companion/actions/runs/30989999964
- Step completati: checkout, setup Java; in corso: installazione Flutter.
- Step successivi: `flutter pub get` → `analyze` → `test --exclude-tags
  golden` → `build apk --release` → upload artifact → release
  `build-latest`.

### Come recuperare l'APK (anche da solo, senza di me)

1. Vai su **Actions → Build APK** nel repository.
2. Se la run è verde: apri la release **`build-latest`** nella pagina
   principale del repo e scarica `vtm-companion.apk` dal telefono.
   In alternativa scarica l'artifact `vtm-companion-apk` dalla run.
3. Sul telefono, autorizza l'installazione da origini sconosciute
   (l'APK è firmato con la chiave di debug).

### Se la build fosse rossa

I punti dove è più probabile che si rompa, in ordine:

1. **`pdfx` e Gradle**: è l'unica dipendenza con codice nativo. Se fallisce
   la compilazione Android, l'alternativa più semplice è sostituirla con
   `flutter_pdfview` in `lib/ui/documents/pdf_reader_page.dart` (l'unico
   file che la usa) e in `pubspec.yaml`.
2. **`minSdk`**: `pdfx` richiede API 21+. Se si lamenta, imposta
   `minSdk = 21` in `android/app/build.gradle.kts`.
3. **Permesso di scrittura della release**: il workflow ha già
   `permissions: contents: write`; se l'organizzazione lo blocca, resta
   comunque l'artifact scaricabile dalla run.

I log si leggono da **Actions → la run → job `build`**.

---

## Come riprendere il lavoro in una nuova sessione

L'ambiente è effimero: Flutter non è preinstallato. Per rimetterlo in piedi:

```bash
cd /home/user/vampire-tm-companion
git fetch origin claude/vtm-flutter-app-lde0ch
git checkout claude/vtm-flutter-app-lde0ch

# Flutter (storage.googleapis.com è raggiungibile, dl.google.com no)
curl -sSL -o /tmp/flutter.tar.xz \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.8-stable.tar.xz"
tar -xJf /tmp/flutter.tar.xz -C /opt
export PATH=/opt/flutter/bin:$PATH FLUTTER_ROOT=/opt/flutter
git config --global --add safe.directory /opt/flutter

flutter pub get
flutter test          # 35 test
flutter analyze       # deve dire "No issues found"
```

**Attenzione:** in questo ambiente `dl.google.com` è bloccato dalla policy di
rete, quindi **non è possibile compilare l'APK in locale**: manca l'SDK
Android. La build gira solo su GitHub Actions. Per la verifica visiva si
usano i golden test:

```bash
flutter test --update-goldens   # rigenera test/goldens/*.png, poi si guardano
```

---

## Mappa del codice

```
lib/
  main.dart                 avvio, splash finché legge i dati dal disco
  core/
    theme.dart              palette gotica e stili della pergamena
    app_state.dart          stato condiviso: schede, documenti, dadi, selezione
  models/
    sheet_type.dart         le tre edizioni e i loro limiti
    character.dart          modello generico della scheda + serializzazione
    dice.dart               tiro e conteggio (verde/rosso/nero)
  data/
    sheet_schema.dart       tipi dello schema dichiarativo
    schema_v5.dart          scheda Camarilla Italia
    schema_v20.dart         scheda 20° anniversario
    schema_dark_ages.dart   scheda I Secoli Bui (9 pallini)
    character_repository.dart   un JSON per scheda, scrittura ritardata
    document_repository.dart    PDF copiati in locale + indice
  ui/
    shell/root_shell.dart   3 sezioni con stack separati, regola di riapertura
    shell/bottom_menu.dart  il menu con le tre icone
    characters/             lista, editor, scheda renderizzata
    dice/dice_page.dart     schermata dei dadi
    documents/              libreria e lettore PDF
    widgets/                pallini, tracker, pergamena, dialoghi
```

**Il punto chiave dell'architettura:** le tre schede sono descritte da uno
*schema dichiarativo*. Editor e rendering leggono lo stesso schema, quindi
non possono divergere: per aggiungere o correggere un tratto basta toccare
`lib/data/schema_*.dart`.

---

## Idee per dopo (non richieste, non fatte)

- Esportazione/importazione della scheda in JSON per passarla fra telefoni.
- Firma dell'APK con una chiave vera, se vuoi distribuirlo ad altri.
- Ricerca nel testo dei PDF.
- Calcolo automatico della riserva di dadi (attributo + abilità) al posto
  del solo tratto singolo.
