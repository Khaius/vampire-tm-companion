import 'package:flutter/material.dart';

/// Le tipologie di scheda supportate, corrispondenti ai PDF da cui l'app e'
/// stata modellata.
///
/// Dei Secoli Bui esistono due schede di edizioni diverse: si distinguono
/// ovunque con il numero di edizione (1ª e 20° Anniversario), mai con il solo
/// nome dell'ambientazione.
enum SheetType {
  v5(
    id: 'v5',
    title: 'Vampire',
    subtitle: 'The Masquerade — 5ª Edizione',
    badge: 'V5',
    description:
        'Scheda Camarilla Italia. Attributi e Skill fino a 5, tracker di '
        'Salute e Volontà a caselle, Fame e Potenza del Sangue.',
    traitMax: 5,
    accent: Color(0xFF8E1B1B),
    parchment: Color(0xFFF3EFE6),
  ),
  v20(
    id: 'v20',
    title: 'Vampiri',
    subtitle: 'La Masquerade — 20° Anniversario',
    badge: 'V20',
    description:
        'Scheda classica su due pagine. Attributi, Abilità, Discipline e '
        'Virtù fino a 5, Punti Sangue e Volontà a caselle.',
    traitMax: 5,
    accent: Color(0xFF6E1414),
    parchment: Color(0xFFF0EDE7),
  ),
  darkAges20(
    id: 'dark_ages',
    title: 'Vampiri',
    subtitle: 'I Secoli Bui — 20° Anniversario',
    badge: 'SB20',
    description:
        'Scheda medievale. I tratti arrivano fino a 9 pallini come da scheda, '
        'Sentiero al posto dell\'Umanità e riserva di sangue fino a 50.',
    traitMax: 9,
    accent: Color(0xFF7E1B10),
    parchment: Color(0xFFF7F1E4),
  ),
  darkAges1(
    id: 'dark_ages_1',
    title: 'Vampiri',
    subtitle: 'I Secoli Bui — 1ª Edizione',
    badge: 'SB1',
    description:
        'Scheda estesa della prima edizione, ambientata nel 1197. Abilità '
        'd\'epoca (Recitazione, Erboristeria, Muoversi Silenziosamente), '
        'tratti fino a 6 pallini come da scheda, Sentiero e 20 Punti Sangue.',
    traitMax: 6,
    accent: Color(0xFF6B2A12),
    parchment: Color(0xFFF4ECDB),
  );

  const SheetType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    required this.traitMax,
    required this.accent,
    required this.parchment,
  });

  /// Identificativo stabile usato nel JSON salvato su disco.
  final String id;
  final String title;
  final String subtitle;

  /// Sigla dell'edizione: sta nel quadratino accanto al nome nella lista e
  /// nel cartellino della scelta del tipo, dove ci sono 44 pixel e basta.
  final String badge;

  final String description;

  /// Valore massimo consentito per i "pallini" dei tratti principali
  /// (Attributi, Abilità, Discipline, Background) su questa scheda.
  final int traitMax;

  final Color accent;
  final Color parchment;

  /// Vero per tutte le schede dei Secoli Bui: decide la cornice medievale e
  /// i colori della pergamena, che le due edizioni condividono.
  bool get isDarkAges => this == darkAges20 || this == darkAges1;

  static SheetType fromId(String? id) {
    return SheetType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => SheetType.v20,
    );
  }
}
