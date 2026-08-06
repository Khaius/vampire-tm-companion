import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/sheet_type.dart';

/// Stile della cornice: le schede V5/V20 hanno la cancellata in ferro
/// battuto, quella dei Secoli Bui una doppia riga rossa.
enum FrameStyle { iron, medieval }

FrameStyle frameStyleFor(SheetType type) =>
    type.isDarkAges ? FrameStyle.medieval : FrameStyle.iron;

/// Disegna la cornice della scheda: bordo doppio, cancellata o fregi.
class _FramePainter extends CustomPainter {
  const _FramePainter({required this.style, required this.accent});

  final FrameStyle style;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = VtmColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (style == FrameStyle.medieval) {
      final outer = Paint()
        ..color = const Color(0xFF2A1112)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      final inner = Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawRect(
        Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
        outer,
      );
      canvas.drawRect(
        Rect.fromLTWH(9, 9, size.width - 18, size.height - 18),
        inner,
      );
      // rombi negli angoli
      final diamond = Paint()..color = accent;
      for (final corner in [
        const Offset(9, 9),
        Offset(size.width - 9, 9),
        Offset(9, size.height - 9),
        Offset(size.width - 9, size.height - 9),
      ]) {
        final path = Path()
          ..moveTo(corner.dx, corner.dy - 5)
          ..lineTo(corner.dx + 5, corner.dy)
          ..lineTo(corner.dx, corner.dy + 5)
          ..lineTo(corner.dx - 5, corner.dy)
          ..close();
        canvas.drawPath(path, diamond);
      }
      return;
    }

    // Cancellata: rotaia orizzontale e sbarre con punta di lancia.
    const railTop = 16.0;
    final railBottom = size.height - 16;
    final fill = Paint()..color = VtmColors.ink;

    canvas.drawRect(Rect.fromLTWH(6, railTop, size.width - 12, 3), fill);
    canvas.drawRect(Rect.fromLTWH(6, railBottom - 3, size.width - 12, 3), fill);

    const spacing = 22.0;
    for (var x = 14.0; x < size.width - 12; x += spacing) {
      _spike(canvas, fill, x, railTop + 3, up: true);
      _spike(canvas, fill, x, railBottom - 3, up: false);
    }

    // Riquadro interno della pagina.
    canvas.drawRect(
      Rect.fromLTWH(
        10,
        railTop + 12,
        size.width - 20,
        railBottom - railTop - 24,
      ),
      ink,
    );
  }

  void _spike(
    Canvas canvas,
    Paint paint,
    double x,
    double y, {
    required bool up,
  }) {
    const height = 13.0;
    const width = 3.0;
    final dir = up ? -1 : 1;
    canvas.drawRect(
      Rect.fromLTWH(x - width / 2, up ? y - height : y, width, height),
      paint,
    );
    final tipY = y + dir * (height + 5);
    final path = Path()
      ..moveTo(x - 3.4, y + dir * height)
      ..lineTo(x + 3.4, y + dir * height)
      ..lineTo(x, tipY)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.style != style || old.accent != accent;
}

/// Sfondo pergamena: tinta piatta con una leggera vignettatura, cosi' la
/// scheda si legge come carta anche su schermo.
class SheetPaper extends StatelessWidget {
  const SheetPaper({
    super.key,
    required this.type,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 34, 20, 34),
  });

  final SheetType type;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = frameStyleFor(type);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.35,
          colors: [
            type.parchment,
            Color.lerp(type.parchment, const Color(0xFFCFC4B0), 0.45)!,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FramePainter(style: style, accent: type.accent),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Il titolo in cima alla scheda ("VAMPIRE — THE MASQUERADE").
class SheetMasthead extends StatelessWidget {
  const SheetMasthead({super.key, required this.type});

  final SheetType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          type.title.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            height: 1,
            letterSpacing: 3,
            color: type.isDarkAges ? const Color(0xFF3A1416) : VtmColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          type.subtitle.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 9.5,
            letterSpacing: 3.2,
            color: VtmColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// L'intestazione di sezione con i losanghi ai lati, come sulle schede.
class SheetBanner extends StatelessWidget {
  const SheetBanner(
    this.title, {
    super.key,
    required this.type,
    this.collapsed = false,
    this.onToggle,
  });

  final String title;
  final SheetType type;

  /// Se la sezione sotto e' chiusa: cambia solo il segno accanto al titolo.
  final bool collapsed;

  /// Toccando la fascia si apre e si chiude la sezione.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final medieval = type.isDarkAges;
    final color = medieval ? type.accent : VtmColors.ink;
    final ink = medieval ? const Color(0xFF3A1416) : VtmColors.ink;
    final banner = Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _Rule(color: color, medieval: medieval, left: true),
          ),
          // I titoli lunghi si restringono invece di sfondare la riga.
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: SheetTextStyles.heading.copyWith(color: ink),
                    ),
                    if (onToggle != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          collapsed ? Icons.expand_more : Icons.expand_less,
                          size: 18,
                          color: ink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _Rule(color: color, medieval: medieval, left: false),
          ),
        ],
      ),
    );
    if (onToggle == null) return banner;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: banner,
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({
    required this.color,
    required this.medieval,
    required this.left,
  });

  final Color color;
  final bool medieval;
  final bool left;

  @override
  Widget build(BuildContext context) {
    if (medieval) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 2, color: color),
          const SizedBox(height: 2),
          Container(height: 1, color: color.withValues(alpha: 0.7)),
        ],
      );
    }
    return SizedBox(
      height: 12,
      child: CustomPaint(
        painter: _ArrowRulePainter(color: color, left: left),
      ),
    );
  }
}

class _ArrowRulePainter extends CustomPainter {
  const _ArrowRulePainter({required this.color, required this.left});

  final Color color;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final midY = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(0, midY - 1.4, size.width, 2.8), paint);

    // losanga all'estremita' esterna, punta verso il testo
    final tipX = left ? 0.0 : size.width;
    final dir = left ? 1.0 : -1.0;
    final path = Path()
      ..moveTo(tipX, midY)
      ..lineTo(tipX + dir * 7, midY - 5.5)
      ..lineTo(tipX + dir * 14, midY)
      ..lineTo(tipX + dir * 7, midY + 5.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowRulePainter old) => old.color != color;
}

/// Titoletto di colonna ("Fisici", "Attitudini", "Virtù").
class SheetColumnTitle extends StatelessWidget {
  const SheetColumnTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: SheetTextStyles.subheading,
      ),
    );
  }
}

/// Riga con etichetta e valore su riga puntinata: toccandola si modifica.
class RuledValue extends StatelessWidget {
  const RuledValue({
    super.key,
    this.label,
    required this.value,
    this.onTap,
    this.labelWidth,
    this.placeholder = '',
    this.dense = false,
    this.align = TextAlign.left,
  });

  final String? label;
  final String value;
  final VoidCallback? onTap;
  final double? labelWidth;
  final String placeholder;
  final bool dense;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final field = InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: dense ? 20 : 24),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VtmColors.rule, width: 0.9)),
        ),
        child: Text(
          value.isEmpty ? placeholder : value,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: value.isEmpty
              ? SheetTextStyles.small.copyWith(
                  color: VtmColors.rule,
                  fontStyle: FontStyle.italic,
                )
              : SheetTextStyles.value,
        ),
      ),
    );

    if (label == null) return field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            child: Text(label!, style: SheetTextStyles.label),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }
}

/// Blocco di testo libero incorniciato (Biografia, Debolezza, Note...).
class RuledBlock extends StatelessWidget {
  const RuledBlock({
    super.key,
    required this.value,
    required this.lines,
    this.onTap,
    this.placeholder = 'Tocca per scrivere',
  });

  final String value;
  final int lines;
  final VoidCallback? onTap;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: math.max(1, lines) * 20),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: VtmColors.rule, width: 0.9),
          color: Colors.white.withValues(alpha: 0.25),
        ),
        child: Text(
          value.isEmpty ? placeholder : value,
          style: value.isEmpty
              ? SheetTextStyles.small.copyWith(
                  color: VtmColors.rule,
                  fontStyle: FontStyle.italic,
                )
              : SheetTextStyles.value,
        ),
      ),
    );
  }
}
