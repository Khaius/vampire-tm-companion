import '../models/sheet_type.dart';
import 'archetypes.dart';
import 'clans.dart';
import 'generations.dart';
import 'sheet_schema.dart';

/// Scheda "Vampiri: I Secoli Bui" della **prima edizione** (1197), nella
/// versione estesa in otto pagine.
///
/// Non va confusa con [darkAgesSchema], che e' l'edizione del 20°
/// Anniversario: stessa ambientazione, regole diverse. Qui le Abilita' sono
/// quelle del 1996 (Recitazione, Schivare, Erboristeria, Musica, Muoversi
/// Silenziosamente, Lingue, Scienza) e i Punti Sangue sono 20 invece di 50.
///
/// I pallini arrivano a 9 come sulla scheda del 20° Anniversario: il cartaceo
/// ne stampa sei, ma le generazioni basse ne concedono di piu' e un valore
/// alto va potuto scrivere. Quelli che la generazione non concede si vedono
/// sbarrati, non spariscono.
///
/// Le chiavi delle Abilita' comuni sono le stesse delle altre schede anche
/// quando il nome italiano cambia (Doti di Comando e' `ab.autorita`,
/// Mestiere e' `ab.manualita`): cosi' una scheda esportata e reimportata
/// conserva i valori, ed e' la stessa regola gia' seguita fra V20 e Secoli
/// Bui 20°.
const darkAges1Schema = SheetSchema(
  type: SheetType.darkAges1,
  clanWeaknessKey: 'debolezza',
  identity: [
    FieldDef('name', 'Nome'),
    FieldDef('nature', 'Natura', options: natureArchetypes, allowCustom: true),
    FieldDef('clan', 'Clan', options: darkAges1ClanNames, allowCustom: true),
    FieldDef('player', 'Giocatore'),
    FieldDef(
      'demeanor',
      'Carattere',
      options: natureArchetypes,
      allowCustom: true,
    ),
    FieldDef('generation', 'Generazione', options: generationRomanOptions),
    FieldDef('chronicle', 'Cronaca'),
    // Sul cartaceo e' "Attiv.Prec.": il mestiere da mortale, non il Concetto.
    FieldDef('attivita_prec', 'Attività Precedente'),
    FieldDef('sire', 'Sire'),
  ],
  attributes: [
    TraitGroup('fisici', 'Fisici', [
      TraitDef('attr.forza', 'Forza', specialtyKey: 'spec.attr.forza'),
      TraitDef(
        'attr.destrezza',
        'Destrezza',
        specialtyKey: 'spec.attr.destrezza',
      ),
      TraitDef(
        'attr.costituzione',
        'Costituzione',
        specialtyKey: 'spec.attr.costituzione',
      ),
    ]),
    TraitGroup('sociali', 'Sociali', [
      TraitDef('attr.carisma', 'Carisma', specialtyKey: 'spec.attr.carisma'),
      TraitDef(
        'attr.persuasione',
        'Persuasione',
        specialtyKey: 'spec.attr.persuasione',
      ),
      TraitDef('attr.aspetto', 'Aspetto', specialtyKey: 'spec.attr.aspetto'),
    ]),
    TraitGroup('mentali', 'Mentali', [
      TraitDef(
        'attr.percezione',
        'Percezione',
        specialtyKey: 'spec.attr.percezione',
      ),
      TraitDef(
        'attr.intelligenza',
        'Intelligenza',
        specialtyKey: 'spec.attr.intelligenza',
      ),
      TraitDef(
        'attr.prontezza',
        'Prontezza di Spirito',
        specialtyKey: 'spec.attr.prontezza',
      ),
    ]),
  ],
  abilityColumnTitles: ['Attitudini', 'Capacità', 'Conoscenze'],
  abilities: [
    TraitGroup('attitudini', 'Attitudini', [
      TraitDef('ab.atletica', 'Atletica', specialtyKey: 'spec.ab.atletica'),
      TraitDef(
        'ab.criminalita',
        'Criminalità',
        specialtyKey: 'spec.ab.criminalita',
      ),
      TraitDef(
        'ab.autorita',
        'Doti di Comando',
        specialtyKey: 'spec.ab.autorita',
      ),
      TraitDef('ab.empatia', 'Empatia', specialtyKey: 'spec.ab.empatia'),
      TraitDef(
        'ab.intimidire',
        'Intimidire',
        specialtyKey: 'spec.ab.intimidire',
      ),
      TraitDef(
        'ab.espressivita',
        'Recitazione',
        specialtyKey: 'spec.ab.espressivita',
      ),
      TraitDef('ab.rissa', 'Rissa', specialtyKey: 'spec.ab.rissa'),
      TraitDef('ab.schivare', 'Schivare', specialtyKey: 'spec.ab.schivare'),
      TraitDef(
        'ab.sestosenso',
        'Sesto Senso',
        specialtyKey: 'spec.ab.sestosenso',
      ),
      TraitDef(
        'ab.sotterfugio',
        'Sotterfugio',
        specialtyKey: 'spec.ab.sotterfugio',
      ),
    ]),
    TraitGroup('capacita', 'Capacità', [
      TraitDef(
        'ab.affinitaanimale',
        'Addestrare Animali',
        specialtyKey: 'spec.ab.affinitaanimale',
      ),
      TraitDef('ab.cavalcare', 'Cavalcare', specialtyKey: 'spec.ab.cavalcare'),
      TraitDef(
        'ab.erboristeria',
        'Erboristeria',
        specialtyKey: 'spec.ab.erboristeria',
      ),
      TraitDef('ab.galateo', 'Galateo', specialtyKey: 'spec.ab.galateo'),
      TraitDef('ab.manualita', 'Mestiere', specialtyKey: 'spec.ab.manualita'),
      TraitDef(
        'ab.armidamischia',
        'Mischia',
        specialtyKey: 'spec.ab.armidamischia',
      ),
      TraitDef(
        'ab.furtivita',
        'Muoversi Silenziosamente',
        specialtyKey: 'spec.ab.furtivita',
      ),
      TraitDef('ab.musica', 'Musica', specialtyKey: 'spec.ab.musica'),
      TraitDef(
        'ab.sopravvivenza',
        'Sopravvivenza',
        specialtyKey: 'spec.ab.sopravvivenza',
      ),
      TraitDef(
        'ab.tiroconlarco',
        'Tiro con l\'Arco',
        specialtyKey: 'spec.ab.tiroconlarco',
      ),
    ]),
    TraitGroup('conoscenze', 'Conoscenze', [
      TraitDef(
        'ab.accademiche',
        'Accademiche',
        specialtyKey: 'spec.ab.accademiche',
      ),
      TraitDef(
        'ab.governodomestico',
        'Governo Domestico',
        specialtyKey: 'spec.ab.governodomestico',
      ),
      TraitDef(
        'ab.investigare',
        'Investigare',
        specialtyKey: 'spec.ab.investigare',
      ),
      TraitDef('ab.legge', 'Legge', specialtyKey: 'spec.ab.legge'),
      TraitDef('ab.lingue', 'Lingue', specialtyKey: 'spec.ab.lingue'),
      TraitDef('ab.medicina', 'Medicina', specialtyKey: 'spec.ab.medicina'),
      TraitDef('ab.occulto', 'Occulto', specialtyKey: 'spec.ab.occulto'),
      TraitDef('ab.politica', 'Politica', specialtyKey: 'spec.ab.politica'),
      TraitDef(
        'ab.saggezzapopolare',
        'Saggezza Popolare',
        specialtyKey: 'spec.ab.saggezzapopolare',
      ),
      TraitDef('ab.scienze', 'Scienza', specialtyKey: 'spec.ab.scienze'),
    ]),
  ],
  // Anche le Virtu' seguono il limite di generazione, come gli altri tratti.
  virtueMax: 9,
  virtues: [
    TraitDef('virtu.coscienza', 'Coscienza/Convinzione'),
    TraitDef('virtu.autocontrollo', 'Self Control/Istinto'),
    TraitDef('virtu.coraggio', 'Coraggio'),
  ],
  lists: [
    ListSection(
      key: 'discipline',
      title: 'Discipline',
      slots: 5,
      hasDots: true,
      limitedByGeneration: true,
      dotMax: 9,
      suggestions: [
        'Animalismo',
        'Auspex',
        'Chimerismo',
        'Daimoinon',
        'Dementazione',
        'Dominazione',
        'Mortis',
        'Obeah',
        'Obtenebrazione',
        'Oscurazione',
        'Potenza',
        'Presenza',
        'Protean',
        'Quietus',
        'Robustezza',
        'Serpentis',
        'Taumaturgia',
        'Velocità',
        'Vicissitudine',
      ],
    ),
    ListSection(
      key: 'background',
      title: 'Background',
      slots: 5,
      hasDots: true,
      limitedByGeneration: true,
      dotMax: 9,
      suggestions: [
        'Alleati',
        'Armento',
        'Contatti',
        'Generazione',
        'Influenza',
        'Mentore',
        'Risorse',
        'Seguaci',
        'Status',
      ],
    ),
    ListSection(
      key: 'altre',
      title: 'Altre Caratteristiche',
      slots: 7,
      hasDots: true,
      limitedByGeneration: true,
      dotMax: 9,
    ),
    // Sul cartaceo Pregi e Difetti stanno in un'unica tabella.
    ListSection(
      key: 'pregidifetti',
      title: 'Pregi e Difetti',
      slots: 9,
      nameLabel: 'Pregio/Difetto',
      columns: [
        ColumnDef('tipo', 'Tipo'),
        ColumnDef('costo', 'Costo', flex: 1),
      ],
    ),
    ListSection(
      key: 'portato',
      title: 'Equipaggiamento Portato',
      slots: 13,
      nameLabel: 'Oggetto',
    ),
    ListSection(
      key: 'posseduto',
      title: 'Equipaggiamento Posseduto',
      slots: 13,
      nameLabel: 'Oggetto',
      columns: [ColumnDef('luogo', 'Luogo')],
    ),
    ListSection(
      key: 'armi_mischia',
      title: 'Armi da Mischia',
      slots: 6,
      nameLabel: 'Arma',
      columns: [
        ColumnDef('diff', 'Diffic.', flex: 1),
        ColumnDef('danno', 'Danno', flex: 1),
        ColumnDef('occult', 'Occult.', flex: 1),
        ColumnDef('forzamin', 'Forza Nec.', flex: 1),
      ],
    ),
    ListSection(
      key: 'armi_lancio',
      title: 'Armi da Lancio',
      slots: 3,
      nameLabel: 'Arma',
      columns: [
        ColumnDef('diff', 'Diffic.', flex: 1),
        ColumnDef('danno', 'Danno', flex: 1),
        ColumnDef('occult', 'Occult.', flex: 1),
        ColumnDef('forzamin', 'Forza Nec.', flex: 1),
        ColumnDef('freq', 'Freq.', flex: 1),
        ColumnDef('gittata', 'Gittata', flex: 1),
      ],
    ),
    ListSection(
      key: 'armatura',
      title: 'Armatura',
      slots: 2,
      nameLabel: 'Armatura',
      columns: [
        ColumnDef('protez', 'Protez.', flex: 1),
        ColumnDef('destr', 'Destr.', flex: 1),
        ColumnDef('perc', 'Perc.', flex: 1),
        ColumnDef('forzamin', 'Forza Nec.', flex: 1),
      ],
    ),
    ListSection(
      key: 'rituali',
      title: 'Rituali',
      slots: 17,
      columns: [ColumnDef('livello', 'Livello', flex: 1)],
    ),
    ListSection(
      key: 'rifugi',
      title: 'Rifugi',
      slots: 9,
      nameLabel: 'Località',
      columns: [ColumnDef('descrizione', 'Descrizione', flex: 3)],
    ),
    ListSection(
      key: 'legami',
      title: 'Legami di Sangue',
      slots: 5,
      nameLabel: 'Vitae bevuta da',
      columns: [ColumnDef('volte', 'Volte', flex: 1)],
    ),
    ListSection(
      key: 'xp_guadagnata',
      title: 'Esperienza Guadagnata',
      slots: 7,
      nameLabel: 'Guadagnata da',
      columns: [ColumnDef('punti', 'Punti', flex: 1)],
    ),
    ListSection(
      key: 'xp_spesa_voci',
      title: 'Esperienza Spesa',
      slots: 7,
      nameLabel: 'Spesa in',
      columns: [ColumnDef('punti', 'Punti', flex: 1)],
    ),
  ],
  tracks: [
    TrackDef(
      key: 'salute',
      title: 'Livelli di Salute',
      kind: TrackKind.damage,
      length: 7,
      perRow: 1,
      maxState: 3,
      rowLabels: [
        'Contusione',
        'Graffio',
        'Ferita Lieve',
        'Ferita Media',
        'Ferita Seria',
        'Ferita Profonda',
        'Ferita Incapacitante',
      ],
      rowPenalties: ['', '-1', '-1', '-2', '-2', '-5', ''],
      stateLegend: ['Contundente /', 'Letale X', 'Aggravato ✱'],
    ),
    TrackDef(
      key: 'volonta',
      title: 'Forza di Volontà',
      kind: TrackKind.dots,
      length: 10,
      note: 'Permanente',
    ),
    TrackDef(
      key: 'volonta_temp',
      title: 'Volontà spesa',
      kind: TrackKind.boxes,
      length: 10,
    ),
    TrackDef(
      key: 'sentiero',
      title: 'Sentiero',
      kind: TrackKind.dots,
      length: 10,
    ),
    // Venti caselle, come sono stampate: la generazione puo' abbassarle.
    TrackDef(
      key: 'sangue',
      title: 'Punti Sangue',
      kind: TrackKind.boxes,
      length: 20,
    ),
  ],
  textSections: [
    TextSection('sentiero_nome', 'Nome del Sentiero', lines: 1),
    TextSection('debolezza', 'Debolezze', lines: 2),
    TextSection('alienazioni', 'Alienazioni Mentali', lines: 9),
    TextSection(
      'esperienza',
      'Esperienza',
      fields: [
        FieldDef('xp_totale', 'Totale'),
        FieldDef('xp_spesa', 'Spesa in Totale'),
      ],
    ),
    TextSection('note', 'Appunti', lines: 13),
    TextSection(
      'descrizione',
      'Dati del Personaggio',
      fields: [
        FieldDef('data_nascita', 'Nascita'),
        FieldDef('abbraccio', 'Abbraccio'),
        FieldDef('eta_apparente', 'Età Apparente'),
        FieldDef('eta', 'Età'),
        FieldDef('nazionalita', 'Nazionalità'),
        FieldDef('sesso', 'Sesso'),
        FieldDef('capelli', 'Capelli'),
        FieldDef('occhi', 'Occhi'),
        FieldDef('altezza', 'Altezza'),
        FieldDef('peso', 'Peso'),
      ],
    ),
    TextSection(
      'storia',
      'Preludio',
      fields: [
        FieldDef('preludio', 'Preludio', multiline: true),
        FieldDef('lingue_conosciute', 'Lingue Conosciute'),
        FieldDef('titolo', 'Titolo'),
        FieldDef('traguardi', 'Traguardi Raggiunti', multiline: true),
      ],
    ),
    TextSection(
      'background_espansi',
      'Sviluppo del Background',
      fields: [
        FieldDef('bg_alleati', 'Alleati', multiline: true),
        FieldDef('bg_gregge', 'Armento', multiline: true),
        FieldDef('bg_contatti', 'Contatti', multiline: true),
        FieldDef('bg_generazione', 'Generazione', multiline: true),
        FieldDef('bg_influenza', 'Influenza', multiline: true),
        FieldDef('bg_mentore', 'Mentore', multiline: true),
        FieldDef('bg_risorse', 'Risorse', multiline: true),
        FieldDef('bg_servitori', 'Seguaci', multiline: true),
        FieldDef('bg_status', 'Status', multiline: true),
      ],
    ),
    // Le cinque caselle guidate della pagina 5 del cartaceo.
    TextSection(
      'guida',
      'Guida allo Sviluppo del Personaggio',
      fields: [
        FieldDef(
          'guida_aspetto',
          'Aspetto',
          multiline: true,
          hint: 'Cosa vedono gli altri quando lo incontrano',
        ),
        FieldDef(
          'guida_specializzazioni',
          'Specializzazioni',
          multiline: true,
          hint: 'Le aree di competenza dei tratti da quattro in su',
        ),
        FieldDef(
          'guida_equipaggiamento',
          'Equipaggiamento',
          multiline: true,
          hint: 'Cosa possiede già, coerente con le Risorse',
        ),
        FieldDef(
          'guida_motivazioni',
          'Motivazioni',
          multiline: true,
          hint: 'Cosa lo muove, cosa teme, cosa spera',
        ),
        FieldDef(
          'guida_identita',
          'Identità da mortale',
          multiline: true,
          hint: 'Che vita conduce quando deve passare per vivo',
        ),
      ],
    ),
    // Le domande delle pagine 6 e 7, una casella per titolo.
    TextSection(
      'questionario',
      'Domande sul Passato',
      fields: [
        FieldDef('dom_eta', 'Quanti anni hai?', multiline: true),
        FieldDef(
          'dom_mortale',
          'Com\'era la tua vita da mortale?',
          multiline: true,
        ),
        FieldDef(
          'dom_primovampiro',
          'Quando hai incontrato un vampiro per la prima volta?',
          multiline: true,
        ),
        FieldDef('dom_sire', 'Chi era il tuo sire?', multiline: true),
        FieldDef('dom_mortali', 'Cosa provi per i mortali?', multiline: true),
        FieldDef(
          'dom_inizio',
          'Come ti consideravi all\'inizio?',
          multiline: true,
        ),
        FieldDef(
          'dom_coterie',
          'Come incontrasti il resto della tua coterie?',
          multiline: true,
        ),
        FieldDef(
          'dom_territorio',
          'Dov\'è il tuo territorio?',
          multiline: true,
        ),
        FieldDef(
          'dom_motivazioni',
          'Quali sono le tue motivazioni?',
          multiline: true,
        ),
      ],
    ),
    TextSection('storia_personaggio', 'Storia del Personaggio', lines: 14),
  ],
  notes: [
    'Attributi: 7/5/3 • Abilità: 13/9/5 • Discipline: 3 • Background: 5 • Virtù: 7 • Punti Liberi: 15',
    'Manovre — Afferrare: iniz. -1, danno Forza • Sfondamento: acc. +1, danno speciale • Blocco: danno 0',
    'Calcio: acc. -1, danno Forza+1 • Pugno: danno Forza • Morso: iniz. -2, acc. +2, danno Forza+1 • Artigliata: danno Forza+2',
  ],
);
