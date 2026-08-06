# VtM Companion

App Flutter da tavolo per **Vampire: The Masquerade**. Gira interamente in
locale sul telefono: nessun account, nessun server, nessuna connessione.

Tre funzioni, sempre raggiungibili dal menu in fondo allo schermo:

| Icona | Sezione | Cosa fa |
|---|---|---|
| Papiro | **Schede** | Crea, consulta e modifica le schede personaggio |
| d10 | **Dadi** | Tira i d10 con difficoltà e conteggio dei successi |
| Libro aperto | **Documenti** | Carica e consulta PDF salvati sul dispositivo |

## Le tre schede supportate

L'app riproduce fedelmente i tre stampati ufficiali, compresi i limiti dei
"pallini", che sono l'unica validazione presente:

| | Vampire 5ª ed. | Vampiri 20° | Vampiri: I Secoli Bui |
|---|---|---|---|
| Attributi / Abilità | 0–5 | 0–5 | **0–9** |
| Discipline / Background | 0–5 | 0–5 | 0–9 |
| Virtù | — | 0–5 | 0–5 |
| Umanità / Sentiero | 10 caselle | 10 pallini | 10 pallini |
| Volontà | 15 caselle | 10 pallini + 10 caselle | 10 + 10 |
| Salute | 15 caselle | 7 livelli | 7 livelli |
| Sangue | Fame 0–5 · Potenza 0–10 | 20 caselle | 50 caselle |

I nove pallini della scheda dei Secoli Bui non sono un errore: sono
esattamente quelli stampati sul PDF originale, che lascia spazio ai tratti
oltre il 5 delle generazioni basse.

Predatori, discipline, background, meriti e difetti proposti in
autocompletamento sono estratti dai menu a tendina delle schede ufficiali:
restano campi liberi, si può scrivere qualsiasi cosa.

Quattro campi invece si scelgono da un menu: **Clan**, **Natura**,
**Carattere** e **Generazione**. I primi tre finiscono con "Altro…", che apre
la tastiera — l'elenco ufficiale è un punto di partenza, non una gabbia — e
un valore fuori elenco già scritto sulla scheda resta lì e compare nel menu.
La Generazione no: quella è una scelta chiusa in numeri romani (II–XV).

Natura e Carattere propongono i trenta archetipi del manuale, in ordine
alfabetico. La scheda della 5ª edizione non li ha: al loro posto stampa
Ambizione e Desiderio, che restano campi liberi.

### Il clan riempie la scheda

Scelto il clan, l'app scrive da sola le sue **Discipline** nelle prime righe
libere e la sua **debolezza** nel riquadro che quella scheda le dedica
("Debolezza di Clan" sulla V5, "Debolezza" sulle altre due).

Le tre edizioni non dicono le stesse cose sullo stesso clan, quindi ogni
edizione ha la sua tabella: i Gangrel della V5 hanno *Proteide*, quelli della
20ª *Protean*; i Tremere della V5 hanno un sangue che non vincola più nessuno,
quelli dei Secoli Bui sono ancora gli usurpatori che tutti odiano. I Cappadoci
esistono solo nei Secoli Bui, i Giovanni solo nelle altre due.

Il riempimento non cancella niente di quello che hai scritto:

- una Disciplina già presente non viene duplicata e tiene i suoi pallini;
- le nuove entrano nelle righe rimaste vuote, senza allungare la scheda
  finché c'è posto;
- la debolezza viene sovrascritta solo se è vuota o se l'aveva scritta l'app
  per un altro clan. Se ci hai messo del tuo, resta.

Un clan scritto a mano con "Altro…" non precompila niente, per il semplice
motivo che l'app non sa cosa sia.

I dati vengono dai manuali delle tre edizioni, riscontrati online dove le
fonti si contraddicevano. Un caso resta incerto: le Lhiannan dei Secoli Bui,
per cui alcune fonti danno *Ogham* e altre *Taumaturgia* come terza
Disciplina — qui trovi Ogham. Come tutto il resto, si corregge a mano.

### Il limite imposto dalla generazione

Scelta la generazione, i pallini che il personaggio non può raggiungere
vengono disegnati sbarrati e non rispondono al tocco. Vale per Attributi,
Abilità, Discipline, Background, Vie e Altre Caratteristiche; **non** per
Umanità/Sentiero e Volontà, che restano fuori dal limite. Anche la riserva
di Punti Sangue si spegne oltre il massimo consentito.

| Generazione | Max tratti | Sangue | Per turno |
|---|---|---|---|
| III | 10 | 50 | 10 |
| IV | 9 | 50 | 10 |
| V | 8 | 40 | 8 |
| VI | 7 | 30 | 6 |
| VII | 6 | 20 | 5 |
| VIII | 5 | 15 | 3 |
| IX | 5 | 14 | 2 |
| X | 5 | 13 | 1 |
| XI | 5 | 12 | 1 |
| XII | 5 | 11 | 1 |
| XIII–XV | 5 | 10 | 1 |

Le tabelle pubblicate partono dalla terza generazione: alla seconda sono
stati dati gli stessi valori, perché è più materia da narratore che da
regolamento. Il limite si applica solo dove la scheda stampa più pallini di
quanti la generazione ne conceda, quindi si vede soprattutto sulla scheda
dei Secoli Bui, che ne stampa nove.

Se una scheda ha già un valore oltre il limite (per esempio cambiando
generazione a personaggio fatto), quel pallino resta pieno ma smorzato: il
dato non viene cancellato di nascosto, viene segnalato.

## Come si usa

**Schede.** Il "+" in basso a destra apre la scelta dell'edizione, poi si
compila il modulo. Nessun campo è obbligatorio: si può salvare una scheda
completamente vuota e riprenderla dopo. A fine creazione la scheda viene
disegnata come l'originale cartaceo — ed è viva: i pallini, le caselle di
salute, volontà e sangue si toccano e cambiano subito, le righe si toccano
per scrivere. Toccando il **nome di un tratto** si passa ai dadi con la
riserva già impostata su quel valore.

La scheda si apre **bloccata**: si può sfogliare senza il rischio di
cambiarla per sbaglio mentre si scorre. Il lucchetto in alto (o la banda
sopra la scheda) sblocca le modifiche, e resta sbloccata finché la si tiene
aperta. Il tiro rapido dai tratti funziona anche da bloccata.

Una scheda aperta resta la scheda corrente: tornando sull'icona del papiro
da qualsiasi punto dell'app si riapre quella, finché non la si chiude a mano
con la "X". Al riavvio dell'app si riparte sempre dalla lista.

**Dadi.** Contatore con "−" e "+" (minimo 1 dado, si può anche toccare il
numero e scriverlo), difficoltà da 2 a 10, e il tiro. I risultati seguono le
regole richieste:

- **verde** i dadi che eguagliano o superano la difficoltà;
- **rosso** gli 1;
- **nero** tutti gli altri;
- il totale finale è il numero dei verdi meno il numero dei rossi.

Esempio: 5 dadi a difficoltà 7 che escono `1-5-6-1-7` danno **−1**
(un successo meno due 1). Sotto restano i tiri precedenti della sessione.

**Documenti.** Il "+" tondo in basso a destra importa un PDF, che viene
**copiato** nella memoria privata dell'app: da quel momento si consulta
anche senza il file originale e senza rete, con zoom a pizzico e ripresa
dall'ultima pagina letta.

## Scaricare l'APK

Ogni push fa girare la pipeline in `.github/workflows/build-apk.yml`, che
analizza, testa e compila l'APK di release. Il file si scarica in due modi:

1. dalla release **`build-latest`** del repository — link diretto, comodo da
   aprire dal telefono;
2. dagli artifact della run in **Actions → Build APK → vtm-companion-apk**.

Android chiede di autorizzare l'installazione da origini sconosciute, e Play
Protect può mostrare un avviso: sono normali per un'app che non arriva dallo
store.

Il link buono da girare in giro è
<https://github.com/Khaius/vampire-tm-companion/releases/latest>, che punta
sempre all'ultima versione pubblicata e quindi non invecchia.

### Pubblicare una versione

Si avvia a mano la pipeline (**Actions → Build APK → Run workflow**)
indicando il tag in `release_tag`, per esempio `v1.3.0`. Il tag lo crea
GitHub sul commit di quell'avvio: da qui i tag non si possono spingere via
git, il proxy risponde 403.

Il campo `highlights`, se compilato, finisce in cima alle note della release
sotto "Novità di questa versione"; sotto viene sempre il testo fisso di
`.github/release-notes.md` — quale file scaricare, come si installa, cosa
succede aggiornando — e in fondo l'elenco delle pull request che GitHub
genera da solo.

Prima di pubblicare va alzato il **numero di build** in `pubspec.yaml`
(`1.2.0+3` → il `+3`): senza, Android considera l'APK nuovo un doppione di
quello già installato e rifiuta l'aggiornamento.

### La chiave di firma

L'APK è firmato con `android/app/vtm-signing.jks`, che sta **dentro il
repository** insieme alla sua password. È una scelta deliberata, non una
svista: quella chiave non protegge nulla, serve solo a far uscire tutte le
build firmate allo stesso modo.

Senza, ogni compilazione su una macchina pulita genera al volo una chiave di
debug diversa, e Android rifiuta di installare l'aggiornamento sopra la
versione già presente ("app non installata"): l'unico rimedio sarebbe
disinstallare e reinstallare ogni volta, perdendo le schede.

Il rovescio della medaglia: chiunque abbia il repository può firmare un APK
che Android considera un aggiornamento di questa app. Per un'app personale
distribuita fra amici va bene; per pubblicarla sul Play Store serve una
chiave vera, generata a parte e tenuta fuori dal repository.

## Compilare in locale

Serve Flutter (canale stable) e l'SDK Android.

```bash
flutter pub get
flutter run                       # su dispositivo o emulatore
flutter build apk --release       # APK installabile
flutter build appbundle --release # bundle per il Play Store
```

Su macOS, per iOS: `flutter build ios --release`.

## Struttura del progetto

```
lib/
  core/           tema gotico e stato condiviso dell'app
  models/         scheda personaggio, tiro di dadi, tipi di scheda
  data/           schemi delle tre schede e archivi su disco
  ui/
    shell/        menu in basso e navigazione a tre sezioni
    characters/   lista, editor e scheda renderizzata
    dice/         schermata dei dadi
    documents/    libreria PDF e lettore
    widgets/      pallini, tracker, pergamena, dialoghi
assets/
  fonts/          Cinzel ed EB Garamond (OFL), ridotti al solo latino
  icons/          icone vettoriali del menu e il d10 della schermata dadi
tool/
  generate_icons.py   rigenera le icone di lancio Android e iOS
```

Le tre schede sono descritte da uno **schema** dichiarativo
(`lib/data/schema_*.dart`): editor e rendering leggono lo stesso schema, così
non possono divergere. Aggiungere un tratto significa aggiungere una riga lì.

Le regole che non stanno sulla scheda ma la governano vivono accanto agli
schemi: `generations.dart` per i limiti di generazione, `clans.dart` per le
Discipline e le debolezze di clan delle tre edizioni, `archetypes.dart` per
gli archetipi di Natura e Carattere.

I dati vivono in un file JSON per personaggio nella cartella privata
dell'app, scritti con un piccolo ritardo mentre si tocca la scheda per non
scrivere su disco a ogni pallino.

## Test

```bash
flutter test                         # tutto, golden compresi
flutter test --exclude-tags golden   # come in CI
flutter test --update-goldens        # riallinea le immagini di riferimento
```

I test coprono il conteggio dei dadi (compreso l'esempio delle specifiche),
i limiti dei pallini delle tre schede, il salvataggio su disco, la
navigazione del menu, la regola della scheda che resta aperta e le tabelle
dei clan — comprese le verifiche che il menu di ogni scheda e la tabella
della sua edizione non possano divergere, e che le Discipline precompilate
esistano fra quelle che quella scheda propone. I **golden test** in
`test/goldens/` sono immagini di riferimento delle schermate: ogni modifica
al layout che le altera fa fallire il test.

## Licenze

Font Cinzel ed EB Garamond distribuiti con SIL Open Font License 1.1.
*Vampire: The Masquerade* è un marchio di Paradox Interactive; questa è
un'app di supporto non ufficiale, senza contenuti dei manuali.
