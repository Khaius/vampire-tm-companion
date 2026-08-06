# Istruzioni per Claude Code

Questo file serve a chi apre il progetto in una sessione nuova, senza la
memoria di come è stato costruito. Leggilo prima di toccare qualsiasi cosa:
molte scelte che sembrano sbagliate sono deliberate, e sotto è spiegato
perché.

Il committente è italiano e **tutto quello che si vede a schermo è in
italiano**: testi, messaggi, tooltip. Anche i commenti nel codice, i nomi
dei test e i messaggi di commit sono in italiano. I nomi di classi, metodi e
variabili restano in inglese, come è normale in Dart.

## Che cos'è l'app

`vtm_companion` è un compagno da tavolo per **Vampire: The Masquerade**, in
Flutter, per telefono. Fa tre cose e solo tre:

1. **Schede personaggio** di quattro edizioni (V5 Camarilla Italia, V20 20°
   Anniversario, I Secoli Bui 20° Anniversario, I Secoli Bui 1ª edizione),
   create e modificate a mano;
2. **Tiro dei d10** con difficoltà e conteggio dei successi;
3. **Libreria di PDF** importati dal telefono e consultabili offline.

Vincoli che non vanno mai violati senza che l'utente lo chieda:

- **Gira solo in locale.** Nessun account, nessuna chiamata di rete, nessuna
  analitica. I dati stanno sul telefono e basta. L'unica cosa che esce è il
  file di esportazione, e solo quando l'utente lo condivide.
- **Niente validazione dei dati.** Si può salvare una scheda completamente
  vuota. L'unica regola è sui pallini, che restano fra 0 e il massimo della
  scheda (e della generazione).
- **La scheda è disegnata come il cartaceo**, ma viva: si tocca e cambia.

## Come si lavora

Flutter non è nel PATH: `export PATH="$PATH:/opt/flutter/bin"`.

```bash
flutter analyze                      # deve essere sempre pulito
flutter test                         # tutto, golden compresi
flutter test --exclude-tags golden   # come in CI
flutter test --update-goldens        # dopo un cambio di layout voluto
dart format lib test                 # prima di committare
```

**Guarda sempre i golden rigenerati** con lo strumento di lettura immagini
prima di committarli: sono l'unico modo per accorgersi che un layout si è
rotto. In CI i golden sono esclusi perché dipendono dal rendering del testo
della macchina che li ha generati.

Il ramo di lavoro è `claude/vtm-flutter-app-lde0ch`; si apre una PR verso
`main` e si unisce. Non si spinge mai direttamente su `main`.

## Mappa del codice

```
lib/
  core/
    app_state.dart      ChangeNotifier: schede, documenti, dadi, selezione,
                        esportazione e importazione. Unico punto che scrive.
    theme.dart          colori (VtmColors), tema Material, stili della scheda
  models/
    character.dart      Character e TraitEntry: solo dati, nessuna struttura
    sheet_type.dart     le quattro edizioni, con titoli, sigla e massimo
                        dei pallini
    dice.dart           DiceRoll: il conteggio dei successi
  data/
    sheet_schema.dart   i tipi che descrivono una scheda (FieldDef, TraitDef,
                        ListSection, TrackDef, TextSection, SheetSchema)
    schema_v5.dart            \
    schema_v20.dart            \  una costante per edizione: è QUI che
    schema_dark_ages.dart      /  vive la struttura delle schede
    schema_dark_ages_first.dart/
    schemas.dart        schemaFor(SheetType)
    generations.dart    tabella delle generazioni (max tratti, sangue)
    clans.dart          Discipline e debolezze di clan, una tabella per
                        edizione, più la precompilazione
    archetypes.dart     i trenta archetipi di Natura e Carattere
    character_repository.dart   file JSON per scheda + cartella foto
    character_transfer.dart     formato di esportazione e sua lettura
    document_repository.dart    i PDF importati
  ui/
    shell/              menu in basso a tre voci e navigazione
    characters/         lista, editor (character_edit_page) e scheda
                        renderizzata (sheet_page)
    dice/  documents/   le altre due sezioni
    widgets/            pallini, tracker, pergamena, dialoghi, foto
```

### Il cuore: lo schema

Ogni edizione è **una costante dichiarativa** (`schema_*.dart`). L'editor e
la scheda renderizzata leggono lo stesso schema, quindi non possono
divergere: aggiungere un tratto significa aggiungere una riga lì, e compare
in tutte e due le viste.

`Character` non sa niente della struttura: tiene mappe di testi, pallini,
liste e tracker indicizzate per chiave. Le chiavi le decide lo schema.
Questo è il motivo per cui quattro schede molto diverse condividono un solo
editor, un solo salvataggio e un solo rendering.

**Non aggiungere campi a `Character` per tratti specifici.** Se serve un
nuovo tratto, va nello schema.

**Le chiavi non si cambiano mai.** Sono scritte nei file JSON delle schede
già create: rinominare `ab.atletica` significa cancellare quel valore dalle
schede di chi gioca. Le abilità in comune fra le schede usano di proposito
la stessa chiave anche quando cambia il nome italiano (*Doti di Comando* dei
Secoli Bui di 1ª è `ab.autorita`, come l'*Autorità* della 20ª), e dei test lo
verificano.

## Decisioni prese, e perché

Cambiarle è legittimo se l'utente lo chiede; farlo per iniziativa propria no.

- **La chiave di firma è dentro il repository** (`android/app/vtm-signing.jks`)
  con la sua password. Non è una svista: senza, ogni build genera una chiave
  di debug diversa e Android rifiuta l'aggiornamento ("app non installata"),
  costringendo a disinstallare e perdere le schede. Il rovescio è scritto nel
  README. Non toglierla e non rigenerarla.
- **I pallini oltre il limite di generazione si vedono sbarrati**, non
  spariscono: un valore già inserito non va nascosto in silenzio. I **punti
  sangue** invece non vengono proprio disegnati, perché l'utente l'ha chiesto
  espressamente; se restano caselle segnate oltre il limite, una riga lo
  dice.
- **Le sezioni a elenco partono vuote.** Niente righe in bianco da saltare:
  si aggiunge una voce quando serve. Aprendo una scheda vecchia in modifica,
  le righe vuote rimaste vengono ripulite.
- **Le sezioni si aprono e si chiudono** toccandone il titolo, con le stesse
  chiavi nell'editor e nella scheda; la scelta è salvata nel file del
  personaggio (campo `collapsed`), non nelle preferenze dell'app.
- **La precompilazione da clan non cancella mai niente**: le Discipline già
  scritte restano con i loro pallini, la debolezza viene sostituita solo se
  vuota o se l'aveva scritta l'app per un altro clan.
- **Le tabelle dei clan sono per edizione**, anche quando il clan è lo
  stesso: cambiano le Discipline e i nomi italiani (V5 dice *Ascendente* e
  *Proteide*, la 20ª *Presenza* e *Protean*). I nomi delle Discipline V5
  sono stati estratti dai menu a tendina del PDF ufficiale, non scritti a
  memoria.
- **La scheda dei Secoli Bui 20° ha anche le abilità moderne** (Armi da
  Fuoco, Informatica, Guidare...): serve alle cronache che dal 1230 arrivano
  a oggi con salti temporali. Le abilità d'epoca restano. La scheda di **1ª
  edizione no**: ha le trenta abilità del 1996 e basta, perché è la scheda di
  quel regolamento e mescolarle la falserebbe.
- **Le due schede dei Secoli Bui si distinguono sempre con il numero di
  edizione**, mai con la sola ambientazione: *I Secoli Bui — 1ª Edizione* e
  *I Secoli Bui — 20° Anniversario*, sigle `SB1` e `SB20`. Nel codice sono
  `SheetType.darkAges1` e `SheetType.darkAges20`; l'`id` salvato su disco
  resta `dark_ages` per la 20ª (era già scritto nei file) e `dark_ages_1` per
  la nuova.
- **Esportazione in un solo file JSON**, foto comprese in base64, condiviso
  con il pannello di sistema. JSON e non un formato binario perché se un
  giorno l'app non ci fosse più il file resta leggibile. L'importazione crea
  **sempre** schede nuove: non sovrascrive mai quelle sul telefono.

## Trappole già pagate

Cose che sono già costate una build rotta o un pomeriggio. Non ripeterle.

- **Il push dei tag riceve 403** dal proxy: le credenziali di questo
  ambiente spingono solo rami. Le release si fanno avviando a mano il
  workflow con `release_tag`, e il tag lo crea GitHub.
- **Il numero di build va alzato a ogni release** (`pubspec.yaml`, il `+N`).
  Senza, Android considera l'APK un doppione e rifiuta l'aggiornamento.
  Attenzione: l'APK per architettura usa la serie 2000 e quello universale
  la serie bassa, quindi **non si può passare da un tipo all'altro**: per
  Android è un ritorno indietro. È scritto anche nelle note della release.
- **`notifyListeners()` dentro `dispose()`** fa crashare Flutter ("widget
  tree was locked"). Per questo esiste `AppState.flushAndNotifyLater`.
- **`DropdownButtonFormField`** va in assert se il valore non corrisponde
  esattamente a una delle voci: i valori fuori elenco vanno aggiunti come
  voce, ed è quello che fa `_SelectRow`.
- **Nei test widget il tempo è finto**: I/O vero (salvataggio, rilettura)
  va dentro `tester.runAsync`, altrimenti il test resta appeso dieci minuti.
- **`find.byIcon(Icons.more_vert)` non basta**: ce n'è uno nella barra in
  alto e uno per ogni scheda. Si scende da `find.byType(AppBar)`.
- **Nelle liste lunghe** un widget fuori schermo non è costruito: prima di
  toccarlo serve `ensureVisible` o `scrollUntilVisible` (indicando quale
  Scrollable, se ce n'è più d'uno nell'albero).
- **Gli overflow orizzontali** li trovano i test, non l'occhio: quando un
  testo può allungarsi (nomi di clan, etichette) va dentro `Flexible` o
  `Expanded`.

## Pubblicare una versione

1. Alza `version` in `pubspec.yaml` (parte semantica **e** numero di build).
2. `flutter analyze` pulito e `flutter test` tutto verde, golden riguardati.
3. Commit sul ramo di lavoro, PR verso `main`, merge.
4. Avvia **Actions → Build APK → Run workflow** su `main` con:
   - `release_tag`: es. `v1.5.0`
   - `highlights`: le novità, che finiscono in cima alle note (il testo
     fisso sta in `.github/release-notes.md`)
5. Verifica l'APK pubblicato scaricandolo davvero: firma
   (`sha256 5086ae2f…4194e`), `versionCode` cresciuto, allineamento a 16 KB.

Il link da dare alle persone è
<https://github.com/Khaius/vampire-tm-companion/releases/latest>.

## Cosa NON fare

- Non aggiungere dipendenze che richiedono rete o account.
- Non introdurre validazioni sui campi della scheda.
- Non rinominare le chiavi dello schema.
- Non toccare la chiave di firma né il `versionCode` a mano nel Gradle.
- Non creare pull request se l'utente non le ha chieste.
- Non riscrivere i golden senza guardarli.
