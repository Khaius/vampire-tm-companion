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

Clan, predatori, discipline, background, meriti e difetti proposti in
autocompletamento sono estratti dai menu a tendina delle schede ufficiali.
Restano campi liberi: si può scrivere qualsiasi cosa.

## Come si usa

**Schede.** Il "+" in basso a destra apre la scelta dell'edizione, poi si
compila il modulo. Nessun campo è obbligatorio: si può salvare una scheda
completamente vuota e riprenderla dopo. A fine creazione la scheda viene
disegnata come l'originale cartaceo — ed è viva: i pallini, le caselle di
salute, volontà e sangue si toccano e cambiano subito, le righe si toccano
per scrivere. Toccando il **nome di un tratto** si passa ai dadi con la
riserva già impostata su quel valore.

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
navigazione del menu e la regola della scheda che resta aperta. I **golden
test** in `test/goldens/` sono immagini di riferimento delle schermate: ogni
modifica al layout che le altera fa fallire il test.

## Licenze

Font Cinzel ed EB Garamond distribuiti con SIL Open Font License 1.1.
*Vampire: The Masquerade* è un marchio di Paradox Interactive; questa è
un'app di supporto non ufficiale, senza contenuti dei manuali.
