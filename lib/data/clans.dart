import '../models/character.dart';
import '../models/sheet_type.dart';
import 'sheet_schema.dart';

/// Un clan con quello che porta in dote: le Discipline che gli sono proprie
/// e la debolezza che tutti i suoi membri si portano dietro.
///
/// Le tre edizioni non dicono le stesse cose sullo stesso clan — cambiano le
/// Discipline, cambia il testo della debolezza e cambiano perfino i nomi
/// italiani delle Discipline — quindi ogni edizione ha la sua tabella.
class ClanDef {
  const ClanDef(this.name, this.disciplines, this.weakness);

  final String name;

  /// Le Discipline di clan, con i nomi usati dalla scheda di quell'edizione.
  /// Vuota per Caitiff e Sangue Debole, che non ne hanno.
  final List<String> disciplines;

  final String weakness;
}

/// Clan della scheda 5a edizione (Camarilla Italia).
///
/// I nomi delle Discipline sono quelli del menu a tendina del PDF, compreso
/// "Ascendente" per Presence e "Proteide" per Protean: la 5a edizione
/// italiana traduce diversamente dalla 20a.
const v5ClanRules = <ClanDef>[
  ClanDef('Brujah', ['Velocità', 'Potenza', 'Ascendente'], 'Impulsi Violenti: '
      'sottrai dadi pari alla Gravità della Debolezza ai tiri per resistere '
      'alla frenesia di collera.'),
  ClanDef('Caitiff', [], 'Nessuna Debolezza di clan: i Caitiff non discendono '
      'da nessun Antidiluviano. In cambio non hanno Discipline di clan — le '
      'imparano tutte come fuori clan — e fra i Cainiti non contano nulla.'),
  ClanDef('Gangrel', ['Animalità', 'Robustezza', 'Proteide'], 'Bestiale: dopo '
      'ogni frenesia il corpo trattiene tratti animaleschi pari alla Gravità '
      'della Debolezza, uno per ogni categoria di riserve che penalizzano.'),
  ClanDef('Giovanni', ['Auspex', 'Robustezza', 'Oblivion'], 'Bacio Doloroso: '
      'il morso non dà estasi ma agonia. Chi si offre volontario deve '
      'superare Costituzione + Fermezza a difficoltà 2 + Gravità della '
      'Debolezza per non ritrarsi; un vampiro morso rischia la frenesia di '
      'terrore. Nella 5a edizione i Giovanni sono parte degli Hecata.'),
  ClanDef('Lasombra', ['Dominazione', 'Oblivion', 'Potenza'], 'Divorati '
      'dall\'Oscurità: non hanno riflesso e nessuna registrazione li tiene. '
      'Specchi, foto, telecamere e microfoni li restituiscono distorti, con '
      'penalità pari alla Gravità della Debolezza.'),
  ClanDef('Malkavian', ['Auspex', 'Dominazione', 'Oscurazione'], 'Prospettiva '
      'Frantumata: a ogni Fallimento Bestiale o Compulsione la follia '
      'riemerge, con penalità pari alla Gravità della Debolezza a una '
      'categoria di riserve (Fisiche, Sociali o Mentali) per tutta la scena.'),
  ClanDef('Nosferatu', ['Animalità', 'Oscurazione', 'Potenza'], 'Mostruosi: '
      'non possono passare per umani. Niente Meriti di Aspetto, e penalità '
      'pari alla Gravità della Debolezza a ogni tiro sociale che non sia '
      'intimidire.'),
  ClanDef('Ravnos', ['Animalità', 'Oscurazione', 'Ascendente'], 'Fuoco nel '
      'Sangue: dormire due volte di fila nello stesso posto li fa bruciare al '
      'risveglio, con danni aggravati pari alla Gravità della Debolezza.'),
  ClanDef('Sangue Debole', [], 'Nessuna Debolezza di clan, a meno di prendere '
      'il difetto Maledizione di Clan. Al posto delle Discipline i Sangue '
      'Debole hanno l\'Alchimia, e il loro sangue è troppo annacquato per '
      'creare legami o progenie.'),
  ClanDef('Toreador', ['Auspex', 'Ascendente', 'Velocità'], 'Estetismo: '
      'davanti alla vera bellezza restano rapiti, con penalità pari alla '
      'Gravità della Debolezza a tutto ciò che non sia contemplarla.'),
  ClanDef('Tremere', ['Auspex', 'Dominazione', 'Stregoneria del Sangue'],
      'Sangue Ribelle: dopo la caduta di Vienna la loro vitae non vincola '
      'più i Cainiti. Mortali e ghoul si legano ancora, ma servono sorsi in '
      'più pari alla Gravità della Debolezza.'),
  ClanDef('Tzimisce', ['Animalità', 'Dominazione', 'Proteide'], 'Radicato: '
      'ogni Tzimisce sceglie qualcosa a cui appartenere — un luogo, un '
      'gruppo, qualcosa di più astratto — e deve dormirvi circondato. '
      'Altrimenti al risveglio subisce danni aggravati alla Volontà pari '
      'alla Gravità della Debolezza.'),
  ClanDef('Ventrue', ['Dominazione', 'Robustezza', 'Ascendente'], 'Gusti '
      'Raffinati: si nutrono di una sola preda d\'elezione. Ogni altro sangue '
      'viene rigettato, a meno di spendere Volontà pari alla Gravità della '
      'Debolezza.'),
];

/// Clan della scheda 20° Anniversario.
const v20ClanRules = <ClanDef>[
  ClanDef('Assamiti', ['Velocità', 'Oscurazione', 'Quietus'], 'Sete di vitae: '
      'il sangue dei Cainiti dà dipendenza. Ogni punto sangue vampirico '
      'bevuto infligge un livello di danno letale che non si può assorbire.'),
  ClanDef('Brujah', ['Velocità', 'Potenza', 'Presenza'], 'Sangue caldo: +2 '
      'alla difficoltà di tutti i tiri per resistere alla frenesia.'),
  ClanDef('Caitiff', [], 'Senza clan: nessuna Disciplina di clan e nessuna '
      'debolezza ereditata. Ogni Disciplina si impara come fuori clan, e '
      'nessun Cainita di stirpe li riconosce come pari.'),
  ClanDef('Followers of Set', ['Oscurazione', 'Presenza', 'Serpentis'],
      'Figli della notte: -1 dado a ogni azione svolta in piena luce, e due '
      'livelli di danno in più dal sole.'),
  ClanDef('Gangrel', ['Animalismo', 'Robustezza', 'Protean'], 'Marchio della '
      'Bestia: ogni frenesia lascia un tratto animalesco; ogni cinque tratti '
      'accumulati, uno resta per sempre.'),
  ClanDef('Giovanni', ['Dominazione', 'Necromanzia', 'Potenza'], 'Bacio '
      'dell\'agonia: il loro morso non dà piacere ma dolore, e infligge alla '
      'vittima il doppio dei danni.'),
  ClanDef('Lasombra', ['Dominazione', 'Obtenebrazione', 'Potenza'], 'Nessun '
      'riflesso: specchi, acqua, vetri, fotografie e telecamere non li '
      'mostrano. Il sole infligge loro un livello di danno in più.'),
  ClanDef('Malkavian', ['Auspex', 'Dementazione', 'Oscurazione'], 'Follia: al '
      'momento dell\'Abbraccio si sceglie almeno un\'alienazione. La si può '
      'soffocare con la Volontà, ma non guarire mai del tutto.'),
  ClanDef('Nosferatu', ['Animalismo', 'Oscurazione', 'Potenza'], 'Deformi: '
      'Aspetto 0, e nessun tiro può usare l\'Aspetto se non per spaventare.'),
  ClanDef('Ravnos', ['Animalismo', 'Chimerismo', 'Robustezza'], 'Vizio: ogni '
      'Ravnos ne ha uno caratteristico, e per non cedervi quando se ne '
      'presenta l\'occasione serve un tiro di Autocontrollo.'),
  ClanDef('Salubri', ['Auspex', 'Robustezza', 'Obeah'], 'Il terzo occhio: si '
      'apre quando usano le Discipline e non si può nascondere. Nutrirsi da '
      'una vittima non consenziente costa un punto di Volontà.'),
  ClanDef('Toreador', ['Auspex', 'Velocità', 'Presenza'], 'Rapiti dalla '
      'bellezza: davanti a qualcosa di davvero bello serve un tiro di '
      'Autocontrollo a difficoltà 6 per non restare a contemplarlo.'),
  ClanDef('Tremere', ['Auspex', 'Dominazione', 'Taumaturgia'], 'Sangue '
      'servile: bastano due sorsi del sangue di un altro vampiro per esserne '
      'vincolati, invece dei tre normali.'),
  ClanDef('Tzimisce', ['Animalismo', 'Auspex', 'Vicissitudine'], 'Legati alla '
      'terra: devono riposare avvolti da almeno due manciate della terra del '
      'luogo in cui sono nati.'),
  ClanDef('Ventrue', ['Dominazione', 'Robustezza', 'Presenza'], 'Palato '
      'esigente: si nutrono di un solo tipo di preda; qualunque altro sangue '
      'viene rigettato.'),
];

/// Clan della scheda I Secoli Bui.
///
/// Nel 1230 alcune cose non sono ancora successe: gli Assamiti non sono stati
/// maledetti dai Tremere, i Cappadoci non sono ancora stati divorati dai
/// Giovanni e i Salubri sono ancora un clan. Le debolezze qui sotto tengono
/// conto dell'epoca.
const darkAgesClanRules = <ClanDef>[
  ClanDef('Assamiti', ['Velocità', 'Oscurazione', 'Quietus'], 'Sete di vitae: '
      'assaggiato il sangue di un altro Cainita serve un tiro di '
      'Autocontrollo/Istinto per smettere. In questi secoli la maledizione '
      'dei Tremere non è ancora stata lanciata.'),
  ClanDef('Baali', ['Daimoinon', 'Oscurazione', 'Presenza'], 'Infernalisti: i '
      'veri simboli della fede li respingono e li feriscono più del normale, '
      'e qualunque Cainita scopra cosa sono darà loro la caccia. Sono pensati '
      'come antagonisti, non come personaggi giocanti.'),
  ClanDef('Brujah', ['Velocità', 'Potenza', 'Presenza'], 'Sangue caldo: +2 '
      'alla difficoltà di tutti i tiri per resistere alla frenesia.'),
  ClanDef('Cappadoci', ['Auspex', 'Robustezza', 'Mortis'], 'Aspetto '
      'cadaverico: la loro pelle è quella di un morto e non c\'è trucco che '
      'tenga. +1 alla difficoltà di tutti i tiri sociali.'),
  ClanDef('Followers of Set', ['Oscurazione', 'Presenza', 'Serpentis'],
      'Figli della notte: -1 dado a ogni azione svolta in piena luce, e due '
      'livelli di danno in più dal sole.'),
  ClanDef('Gangrel', ['Animalismo', 'Robustezza', 'Protean'], 'Marchio della '
      'Bestia: ogni frenesia lascia un tratto animalesco; ogni cinque tratti '
      'accumulati, uno resta per sempre.'),
  ClanDef('Lasombra', ['Dominazione', 'Obtenebrazione', 'Potenza'], 'Nessun '
      'riflesso: nessuna superficie lucida li mostra. Il sole infligge loro '
      'un livello di danno in più.'),
  ClanDef('Lhiannan', ['Animalismo', 'Ogham', 'Presenza'], 'Legate alla terra '
      'selvaggia: ogni notte passata lontano da luoghi naturali intatti '
      'aggiunge penalità che si sommano, e lo spirito che portano nel sangue '
      'le rende riconoscibili a chi sa vedere.'),
  ClanDef('Malkavian', ['Auspex', 'Dementazione', 'Oscurazione'], 'Follia: al '
      'momento dell\'Abbraccio si sceglie almeno un\'alienazione. La si può '
      'soffocare con la Volontà, ma non guarire mai del tutto.'),
  ClanDef('Nosferatu', ['Animalismo', 'Oscurazione', 'Potenza'], 'Deformi: '
      'Aspetto 0, e nessun tiro può usare l\'Aspetto se non per spaventare.'),
  ClanDef('Ravnos', ['Animalismo', 'Chimerismo', 'Robustezza'], 'Vizio: ogni '
      'Ravnos ne ha uno caratteristico, e per non cedervi quando se ne '
      'presenta l\'occasione serve un tiro di Autocontrollo.'),
  ClanDef('Salubri', ['Auspex', 'Robustezza', 'Valeren'], 'Il terzo occhio si '
      'apre a ogni potere oltre il primo, e brilla: usarli di nascosto è '
      'quasi impossibile. I guaritori sostituiscono Valeren con Obeah e fanno '
      'voto di non nuocere. Su tutti pesa la caccia dei Tremere.'),
  ClanDef('Toreador', ['Auspex', 'Velocità', 'Presenza'], 'Rapiti dalla '
      'bellezza: davanti a qualcosa di davvero bello serve un tiro di '
      'Autocontrollo a difficoltà 6 per non restare a contemplarlo.'),
  ClanDef('Tremere', ['Auspex', 'Dominazione', 'Taumaturgia'], 'Sangue '
      'servile: bastano due sorsi del sangue di un altro vampiro per esserne '
      'vincolati, invece dei tre normali. E in questi secoli sono ancora gli '
      'usurpatori: ogni clan li guarda con odio.'),
  ClanDef('Tzimisce', ['Animalismo', 'Auspex', 'Vicissitudine'], 'Legati alla '
      'terra: devono riposare avvolti da almeno due manciate della terra del '
      'luogo in cui sono nati.'),
  ClanDef('Ventrue', ['Dominazione', 'Robustezza', 'Presenza'], 'Palato '
      'esigente: si nutrono di un solo tipo di preda; qualunque altro sangue '
      'viene rigettato.'),
];

/// I nomi dei clan, per il menu a tendina delle schede.
///
/// Sono elenchi a parte perche' gli schemi sono `const` e non possono
/// leggerli dalle tabelle qui sopra; un test verifica che non divergano.
const v5ClanNames = <String>[
  'Brujah',
  'Caitiff',
  'Gangrel',
  'Giovanni',
  'Lasombra',
  'Malkavian',
  'Nosferatu',
  'Ravnos',
  'Sangue Debole',
  'Toreador',
  'Tremere',
  'Tzimisce',
  'Ventrue',
];

const v20ClanNames = <String>[
  'Assamiti',
  'Brujah',
  'Caitiff',
  'Followers of Set',
  'Gangrel',
  'Giovanni',
  'Lasombra',
  'Malkavian',
  'Nosferatu',
  'Ravnos',
  'Salubri',
  'Toreador',
  'Tremere',
  'Tzimisce',
  'Ventrue',
];

const darkAgesClanNames = <String>[
  'Assamiti',
  'Baali',
  'Brujah',
  'Cappadoci',
  'Followers of Set',
  'Gangrel',
  'Lasombra',
  'Lhiannan',
  'Malkavian',
  'Nosferatu',
  'Ravnos',
  'Salubri',
  'Toreador',
  'Tremere',
  'Tzimisce',
  'Ventrue',
];

/// La tabella dei clan dell'edizione richiesta.
List<ClanDef> clanRulesFor(SheetType type) => switch (type) {
  SheetType.v5 => v5ClanRules,
  SheetType.v20 => v20ClanRules,
  SheetType.darkAges => darkAgesClanRules,
};

/// Il clan scelto, se il testo corrisponde a uno di quelli dell'edizione.
/// Chi scrive un clan suo (dal menu si puo') non ottiene precompilazioni.
ClanDef? clanRule(SheetType type, String? name) {
  if (name == null) return null;
  final wanted = name.trim().toLowerCase();
  if (wanted.isEmpty) return null;
  for (final clan in clanRulesFor(type)) {
    if (clan.name.toLowerCase() == wanted) return clan;
  }
  return null;
}

/// Vero se quel testo e' una debolezza scritta dall'app.
///
/// Serve a distinguere il testo che abbiamo messo noi da quello scritto a
/// mano: cambiando clan il primo si puo' sostituire, il secondo no.
bool isGeneratedWeakness(String text) {
  final wanted = text.trim();
  if (wanted.isEmpty) return false;
  for (final table in [v5ClanRules, v20ClanRules, darkAgesClanRules]) {
    for (final clan in table) {
      if (clan.weakness == wanted) return true;
    }
  }
  return false;
}

/// Cosa e' stato scritto davvero sulla scheda scegliendo il clan.
class ClanPrefill {
  const ClanPrefill(this.disciplines, {required this.weaknessWritten});

  /// Le Discipline aggiunte: quelle gia' presenti non vengono duplicate.
  final List<String> disciplines;

  final bool weaknessWritten;

  bool get isEmpty => disciplines.isEmpty && !weaknessWritten;

  /// Il messaggio da mostrare dopo la scelta, o null se non c'e' nulla da
  /// dire (clan senza Discipline proprie e debolezza gia' scritta a mano).
  String? get message {
    if (isEmpty) return null;
    final parts = <String>[];
    if (disciplines.isNotEmpty) {
      parts.add(
        disciplines.length == 1
            ? 'Aggiunta la Disciplina di clan ${disciplines.single}'
            : 'Aggiunte le Discipline di clan: ${disciplines.join(", ")}',
      );
    }
    if (weaknessWritten) {
      parts.add(
        parts.isEmpty ? 'Scritta la debolezza di clan' : 'e la debolezza',
      );
    }
    return '${parts.join(" ")}.';
  }
}

/// Scrive sulla scheda quello che il clan porta con se'.
///
/// Non cancella mai il lavoro di chi gioca: le Discipline gia' scritte
/// restano dove sono (con i loro pallini) e le nuove entrano nelle righe
/// libere; la debolezza viene sovrascritta solo se e' vuota o se l'avevamo
/// scritta noi per un altro clan.
ClanPrefill applyClanTemplate(
  Character character,
  SheetSchema schema,
  ClanDef clan,
) {
  final added = <String>[];

  if (schema.hasList('discipline')) {
    final entries = character.list('discipline');
    for (final discipline in clan.disciplines) {
      final already = entries.any(
        (e) => e.name.trim().toLowerCase() == discipline.toLowerCase(),
      );
      if (already) continue;
      final free = entries.indexWhere(
        (e) => e.name.trim().isEmpty && e.value == 0,
      );
      if (free == -1) {
        entries.add(TraitEntry(name: discipline));
      } else {
        entries[free].name = discipline;
      }
      added.add(discipline);
    }
  }

  var weaknessWritten = false;
  final key = schema.clanWeaknessKey;
  if (key != null) {
    final current = character.text(key);
    if (current.trim().isEmpty || isGeneratedWeakness(current)) {
      character.texts[key] = clan.weakness;
      weaknessWritten = true;
    }
  }

  return ClanPrefill(added, weaknessWritten: weaknessWritten);
}
