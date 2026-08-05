import 'package:flutter/material.dart';

/// Le tre tipologie di scheda supportate, corrispondenti ai tre PDF ufficiali
/// da cui l'app e' stata modellata.
enum SheetType {
  v5(
    id: 'v5',
    title: 'Vampire',
    subtitle: 'The Masquerade — 5ª Edizione',
    shortLabel: 'V5',
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
    shortLabel: 'V20',
    description:
        'Scheda classica su due pagine. Attributi, Abilità, Discipline e '
        'Virtù fino a 5, Punti Sangue e Volontà a caselle.',
    traitMax: 5,
    accent: Color(0xFF6E1414),
    parchment: Color(0xFFF0EDE7),
  ),
  darkAges(
    id: 'dark_ages',
    title: 'Vampiri',
    subtitle: 'I Secoli Bui — 20° Anniversario',
    shortLabel: 'Secoli Bui',
    description:
        'Scheda medievale. I tratti arrivano fino a 9 pallini come da scheda, '
        'Sentiero al posto dell\'Umanità e riserva di sangue fino a 50.',
    traitMax: 9,
    accent: Color(0xFF7E1B10),
    parchment: Color(0xFFF7F1E4),
  );

  const SheetType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.shortLabel,
    required this.description,
    required this.traitMax,
    required this.accent,
    required this.parchment,
  });

  /// Identificativo stabile usato nel JSON salvato su disco.
  final String id;
  final String title;
  final String subtitle;
  final String shortLabel;
  final String description;

  /// Valore massimo consentito per i "pallini" dei tratti principali
  /// (Attributi, Abilità, Discipline, Background) su questa scheda.
  final int traitMax;

  final Color accent;
  final Color parchment;

  static SheetType fromId(String? id) {
    return SheetType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => SheetType.v20,
    );
  }
}
