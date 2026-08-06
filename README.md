# VtM Companion

App Flutter da tavolo per **Vampire: The Masquerade**. Gira interamente in
locale sul telefono: nessun account, nessun server, nessuna connessione.

Tre funzioni, sempre raggiungibili dal menu in fondo allo schermo:

| Icona | Sezione | Cosa fa |
|---|---|---|
| Papiro | **Schede** | Crea, consulta, modifica, esporta e importa le schede |
| d10 | **Dadi** | Tira i d10 con difficoltà e conteggio dei successi |
| Libro aperto | **Documenti** | Carica e consulta PDF salvati sul dispositivo |

## Le quattro schede supportate

L'app riproduce fedelmente i quattro stampati, compresi i limiti dei
"pallini", che sono l'unica validazione presente:

| | Vampire 5ª ed. | Vampiri 20° | Secoli Bui 20° | Secoli Bui 1ª ed. |
|---|---|---|---|---|
| Attributi / Abilità | 0–5 | 0–5 | **0–9** | **0–9** |
| Discipline / Background | 0–5 | 0–5 | 0–9 | 0–9 |
| Virtù | — | 0–5 | 0–5 | 0–9 |
| Umanità / Sentiero | 10 caselle | 10 pallini | 10 pallini | 10 pallini |
| Volontà | 15 caselle | 10 pallini + 10 caselle | 10 + 10 | 10 + 10 |
| Salute | 15 caselle | 7 livelli | 7 livelli | 7 livelli |
| Sangue | Fame 0–5 · Potenza 0–10 | 20 caselle | 50 caselle | 20 caselle |

I nove pallini delle due schede dei Secoli Bui non sono un errore: le
generazioni basse concedono tratti oltre il 5, e un valore alto va potuto
scrivere. Quelli che la generazione non concede si vedono sbarrati.

Le due schede dei Secoli Bui sono **edizioni diverse dello stesso gioco** e
si distinguono ovunque con il numero di edizione, sigle `SB20` e `SB1`.

La scheda dei Secoli Bui 20° tiene le sue abilità d'epoca — Cavalcare, Tiro
con l'Arco, Teologia, Governo Domestico, Saggezza Popolare, Enigmi,
Commercio — **e ha anche tutte quelle moderne** della 20ª: Armi da Fuoco,
Guidare, Criminalità, Bassifondi, Finanza, Informatica, Scienze, Tecnologia.
Serve alle cronache che partono nel Medioevo e con qualche salto temporale
arrivano ai nostri giorni: il personaggio non cambia scheda per strada.

La scheda di **prima edizione** ha invece le trenta abilità del 1996 e
basta: Recitazione, Schivare, Erboristeria, Musica, Muoversi
Silenziosamente, Lingue, Scienza, Governo Domestico, Saggezza Popolare. È la
scheda di quel regolamento, e mescolarci le abilità moderne la falserebbe.

Le abilità in comune usano la stessa chiave su tutte le schede anche quando
cambia il nome italiano — *Doti di Comando* e *Autorità* sono lo stesso
tratto — quindi un valore scritto resta lo stesso tratto ovunque.

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
("Debolezza di Clan" sulla V5, "Debolezza" o "Debolezze" sulle altre).

Le edizioni non dicono le stesse cose sullo stesso clan, quindi ognuna ha la
sua tabella: i Gangrel della V5 hanno *Proteide*, quelli della 20ª *Protean*;
i Tremere della V5 hanno un sangue che non vincola più nessuno, quelli dei
Secoli Bui sono ancora gli usurpatori che tutti odiano; i Salubri hanno
*Valeren* sulla scheda del 20° Anniversario e *Obeah* su quella di prima
edizione, perché Valeren è arrivato solo nel 2002. I Cappadoci esistono solo
nei Secoli Bui, i Giovanni solo nelle altre due.

Il riempimento non cancella niente di quello che hai scritto:

- una Disciplina già presente non viene duplicata e tiene i suoi pallini;
- le nuove entrano nelle righe rimaste vuote, senza allungare la scheda
  finché c'è posto;
- la debolezza viene sovrascritta solo se è vuota o se l'aveva scritta l'app
  per un altro clan. Se ci hai messo del tuo, resta.

Un clan scritto a mano con "Altro…" non precompila niente, per il semplice
motivo che l'app non sa cosa sia.

I dati vengono dai manuali delle varie edizioni, riscontrati online dove le
fonti si contraddicevano. Un caso resta incerto: le Lhiannan dei Secoli Bui,
per cui alcune fonti danno *Ogham* e altre *Taumaturgia* come terza
Disciplina — qui trovi Ogham. Come tutto il resto, si corregge a mano.

### Il limite imposto dalla generazione

Scelta la generazione, i pallini che il personaggio non può raggiungere
vengono disegnati sbarrati e non rispondono al tocco. Vale per Attributi,
Abilità, Discipline, Background, Vie e Altre Caratteristiche; **non** per
Umanità/Sentiero e Volontà, che restano fuori dal limite.

I **Punti Sangue** invece non vengono nemmeno disegnati: un personaggio di
tredicesima vede dieci caselle, non venti di cui dieci spente. La scheda dei
Secoli Bui ne stampa cinquanta, ma di settima generazione se ne vedono venti.
La scheda della 5ª edizione non ha punti sangue: al loro posto ci sono Fame e
Potenza del Sangue, che dalla generazione non dipendono.

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
dato non viene cancellato di nascosto, viene segnalato. Lo stesso vale per il
sangue, dove le caselle sparite non si possono smorzare: se oltre il limite
c'era qualcosa di segnato compare una riga che lo dice, e riportando la
generazione indietro le caselle tornano com'erano.

## Come si usa

**Schede.** Il menu in alto a destra (tre pallini) apre le tre azioni della
lista: **nuova scheda**, **importa** ed **esporta**. La creazione parte dalla
scelta dell'edizione, poi si compila il modulo. Nessun campo è obbligatorio:
si può salvare una scheda completamente vuota e riprenderla dopo. A fine creazione la scheda viene
disegnata come l'originale cartaceo — ed è viva: i pallini, le caselle di
salute, volontà e sangue si toccano e cambiano subito, le righe si toccano
per scrivere. Toccando il **nome di un tratto** si passa ai dadi con la
riserva già impostata su quel valore.

Ogni sezione si **apre e si chiude** toccandone il titolo, sulla scheda come
nel modulo di modifica: chi non usa i Rituali se li toglie di mezzo una volta
sola, perché la scelta viene salvata insieme al personaggio e vale in
entrambe le viste. Di fianco c'è la barra di scorrimento, per arrivare in
fondo a una scheda lunga senza venti passate di pollice.

Le sezioni a elenco — Discipline, Pregi, Difetti, Rituali, Vie... — partono
**vuote**: si aggiunge una riga con "aggiungi voce" quando serve, invece di
trovarne sette in bianco da saltare con gli occhi. Sulla scheda disegnata la
riga per aggiungere compare solo da sbloccata, e il nome viene chiesto
subito: una riga senza nome sarebbe di nuovo una riga vuota. Le schede fatte
con le versioni precedenti perdono le righe rimaste in bianco la prima volta
che si aprono in modifica.

**La foto del personaggio.** Nel modulo di modifica, in cima all'Identità,
c'è il riquadro del ritratto: si sceglie un'immagine dalla memoria del
telefono e viene **copiata dentro la scheda**, quindi resta anche se il file
originale sparisce. La foto compare in alto a sinistra sulla scheda
disegnata (da sbloccata si tocca per cambiarla, si tiene premuto per
toglierla) e come miniatura nella lista.

Le immagini vengono rimpicciolite a mille pixel sul lato lungo e riscritte in
JPEG: una foto da cinque megabyte ne occupa meno di duecento kilobyte, così
la cartella dell'app resta leggera e le schede esportate si possono mandare
via chat.

### Portare le schede altrove

Dal menu della lista, **Esporta** fa comparire un quadratino di fianco a ogni
scheda e una barra in fondo: da lì si sceglie cosa mandare — "seleziona
tutto" prende l'intera raccolta — e si conferma con l'icona di
condivisione. L'app scrive **un solo file** `.vtm.json` e lo passa al
pannello di condivisione del telefono: WhatsApp, Telegram, mail, Drive,
"Salva su file". Dentro ci sono le schede complete, foto comprese.

**Importa** legge quello stesso file. Ogni scheda entra come scheda nuova:
reimportare non sovrascrive mai quello che hai sul telefono, e se la scheda
c'era già il nome lo dice ("Lucrezia (importata)"). Un file rovinato o di
un'altra app non fa danni, dice solo cosa non va.

Il formato è JSON leggibile, non un formato binario: se un giorno questa app
non ci fosse più, le schede di una cronaca lunga restano aperte con un
qualunque editor di testo.

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
  data/           schemi delle quattro schede e archivi su disco
  ui/
    shell/        menu in basso e navigazione a tre sezioni
    characters/   lista, editor e scheda renderizzata
    dice/         schermata dei dadi
    documents/    libreria PDF e lettore
    widgets/      pallini, tracker, pergamena, dialoghi, foto
assets/
  fonts/          Cinzel ed EB Garamond (OFL), ridotti al solo latino
  icons/          icone vettoriali del menu e il d10 della schermata dadi
tool/
  generate_icons.py   rigenera le icone di lancio Android e iOS
```

Le quattro schede sono descritte da uno **schema** dichiarativo
(`lib/data/schema_*.dart`): editor e rendering leggono lo stesso schema, così
non possono divergere. Aggiungere un tratto significa aggiungere una riga lì.

Le regole che non stanno sulla scheda ma la governano vivono accanto agli
schemi: `generations.dart` per i limiti di generazione, `clans.dart` per le
Discipline e le debolezze di clan di ogni edizione, `archetypes.dart` per
gli archetipi di Natura e Carattere. `character_transfer.dart` tiene il
formato di esportazione e la sua lettura, compresi i controlli sui file che
non vanno bene.

Chi apre il progetto con **Claude Code** trovi in `CLAUDE.md` la mappa del
codice, le decisioni prese con le loro ragioni e le trappole già pagate.

I dati vivono in un file JSON per personaggio nella cartella privata
dell'app, scritti con un piccolo ritardo mentre si tocca la scheda per non
scrivere su disco a ogni pallino. Nello stesso file finiscono anche le
sezioni chiuse: sono una scelta che riguarda quel personaggio, non l'app. Le
foto stanno a parte, in `foto/`, così il file della scheda resta piccolo e si
legge in fretta; nell'esportazione invece viaggiano dentro al pacchetto.

## Test

```bash
flutter test                         # tutto, golden compresi
flutter test --exclude-tags golden   # come in CI
flutter test --update-goldens        # riallinea le immagini di riferimento
```

I test coprono l'esportazione e la rilettura delle schede (file rovinati
compresi), le foto, il conteggio dei dadi (compreso l'esempio delle specifiche),
i limiti dei pallini delle quattro schede, il salvataggio su disco, la
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
