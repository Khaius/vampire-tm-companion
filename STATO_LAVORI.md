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

Il codice dell'app non è mai stato in discussione: analisi, test e golden
sono verdi anche in CI. I problemi sono stati tutti nel *toolchain Android*,
e sono stati diagnosticati leggendo i log e corretti uno per uno.

### Diario della compilazione

| Run | Esito | Causa e rimedio |
|---|---|---|
| 1 e 2 | rosse | `compileReleaseJavaWithJavac`: il registrant non trovava `FilePickerPlugin`. Il template di Flutter 3.44 parte con **AGP 9 / Gradle 9**, mentre i plugin sono costruiti sulla linea AGP 8 (pdfx dichiara 8.5.2, file_selector_android 8.13.1): sotto AGP 9 la compilazione Kotlin dei loro moduli non produce classi. Rimedio: AGP 8.13.1, Gradle 8.14, Kotlin 2.3.20 — tutti sopra le soglie richieste da Flutter (AGP ≥ 8.6, Gradle ≥ 8.7, KGP ≥ 2.0). In più `file_picker` è stato sostituito con `file_selector`, mantenuto dal team Flutter. |
| 3 | **verde** | Ha prodotto l'APK alle 08:57. Attenzione: le API di GitHub sui job restituiscono stato in cache e per un pezzo hanno continuato a dire "in corso", facendomi credere che fosse bloccata. Il segnale affidabile è la release, non lo stato del job. |
| 4 | annullata | Conteneva modifiche a NDK e memoria di Gradle nate da quella diagnosi sbagliata. Sono state riportate indietro: la configurazione di build è di nuovo esattamente quella della run 3. |

Al workflow è comunque rimasta la parte utile: annulla la build precedente
quando ne parte una nuova e ha un tetto di tempo, così un blocco vero
fallisce presto invece di restare appeso.

### Firma dell'APK (problema trovato dopo la consegna)

I primi APK uscivano firmati con la chiave di **debug**, che AGP genera al
volo quando non la trova. Ogni run parte da una macchina pulita, quindi ogni
build aveva una firma diversa: Android rifiuta di installare un
aggiornamento firmato in modo diverso da quello già installato, con il
messaggio "app non installata".

Rimedio: chiave stabile in `android/app/vtm-signing.jks`, versionata nel
repository con la sua password, usata dalla `signingConfig` di release.
Non protegge un segreto — serve solo a rendere le build sovrapponibili.
Impronta SHA-256 del certificato:
`50:86:AE:2F:51:A7:07:3A:E1:66:6F:92:C9:7D:30:99:F0:45:F7:BB:92:5E:21:56:E0:9A:48:54:FA:C4:19:4E`.

**Chi ha installato un APK precedente deve disinstallarlo una volta sola**:
da lì in avanti gli aggiornamenti si installano sopra senza perdere nulla.

### Come recuperare l'APK (anche da solo, senza di me)

1. Vai su **Actions → Build APK** nel repository.
2. Se la run è verde: apri la release **`build-latest`** nella pagina
   principale del repo e scarica `vtm-companion.apk` dal telefono.
   In alternativa scarica l'artifact `vtm-companion-apk` dalla run.
3. Sul telefono, autorizza l'installazione da origini sconosciute
   (l'APK è firmato con la chiave di debug).

### Se la build fosse ancora rossa

1. Leggi il log da **Actions → la run → job `build`**: l'errore vero è nelle
   ultime righe dello step "Compila l'APK di release".
2. Se il problema resta su `pdfx` (l'unico plugin non ufficiale rimasto),
   si sostituisce con `flutter_pdfview` toccando due file soli:
   `lib/ui/documents/pdf_reader_page.dart` e `pubspec.yaml`.
3. Se si lamenta del `minSdk`, imposta `minSdk = 24` esplicitamente in
   `android/app/build.gradle.kts`.
4. Se la release `build-latest` non viene creata ma l'APK è compilato, è un
   problema di permessi del repository: l'artifact della run resta comunque
   scaricabile.

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
