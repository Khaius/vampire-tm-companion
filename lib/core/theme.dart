import 'package:flutter/material.dart';

/// Palette gotica dell'app: notte, cenere e sangue.
class VtmColors {
  static const night = Color(0xFF0D0A0B);
  static const surface = Color(0xFF171113);
  static const surfaceHigh = Color(0xFF211719);
  static const blood = Color(0xFF9B1B1B);
  static const bloodBright = Color(0xFFC42E28);
  static const ash = Color(0xFFB9AFA6);
  static const bone = Color(0xFFE8E0D4);
  static const gold = Color(0xFFB99A5B);

  /// Colori dei risultati del tiro, come richiesto: successi verdi, uno rossi,
  /// il resto nero (su pergamena) o osso (su fondo scuro).
  static const success = Color(0xFF1E7A3C);
  static const successBright = Color(0xFF35C46A);
  static const failure = Color(0xFFB01515);
  static const failureBright = Color(0xFFE8483F);
  static const neutralInk = Color(0xFF14100F);

  /// Inchiostro e righe delle schede renderizzate.
  static const ink = Color(0xFF1A1512);
  static const inkSoft = Color(0xFF4A423B);
  static const rule = Color(0xFF8C8177);
}

ThemeData buildVtmTheme() {
  const scheme = ColorScheme.dark(
    primary: VtmColors.bloodBright,
    onPrimary: VtmColors.bone,
    secondary: VtmColors.gold,
    onSecondary: VtmColors.night,
    surface: VtmColors.surface,
    onSurface: VtmColors.bone,
    error: VtmColors.failureBright,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: VtmColors.night,
    fontFamily: 'EBGaramond',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: VtmColors.night,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: VtmColors.ash),
      titleTextStyle: TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: VtmColors.bone,
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: VtmColors.bone, displayColor: VtmColors.bone)
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 1.4,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
          // La famiglia va ripetuta: copyWith sostituisce lo stile intero e
          // perderebbe il font ereditato da ThemeData.fontFamily.
          bodyLarge: const TextStyle(
            fontFamily: 'EBGaramond',
            fontSize: 17,
            height: 1.35,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'EBGaramond',
            fontSize: 16,
            height: 1.35,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'EBGaramond',
            fontSize: 14,
            color: VtmColors.ash,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'EBGaramond',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
    cardTheme: CardThemeData(
      color: VtmColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3A2C2E)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF33262A),
      space: 1,
      thickness: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: VtmColors.blood,
      foregroundColor: VtmColors.bone,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: VtmColors.surfaceHigh,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A2C2E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A2C2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VtmColors.blood, width: 1.6),
      ),
      labelStyle: const TextStyle(color: VtmColors.ash),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: VtmColors.surfaceHigh,
      contentTextStyle: TextStyle(color: VtmColors.bone, fontSize: 15),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: VtmColors.ash,
      textColor: VtmColors.bone,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: VtmColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF3A2C2E)),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: VtmColors.bone,
      ),
    ),
  );
}

/// Stili tipografici usati dentro le schede renderizzate (fondo pergamena).
class SheetTextStyles {
  static const heading = TextStyle(
    fontFamily: 'Cinzel',
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: 2.2,
    color: VtmColors.ink,
  );
  static const subheading = TextStyle(
    fontFamily: 'Cinzel',
    fontWeight: FontWeight.w700,
    fontSize: 13,
    letterSpacing: 1.4,
    color: VtmColors.ink,
  );
  static const label = TextStyle(
    fontFamily: 'EBGaramond',
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    color: VtmColors.ink,
  );
  static const value = TextStyle(
    fontFamily: 'EBGaramond',
    fontSize: 14.5,
    color: VtmColors.ink,
  );
  static const small = TextStyle(
    fontFamily: 'EBGaramond',
    fontSize: 12,
    color: VtmColors.inkSoft,
  );
}
