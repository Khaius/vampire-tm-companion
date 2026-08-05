import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/sheet_schema.dart';

/// Disegna il segno dentro una casella del tracker.
class _BoxMarkPainter extends CustomPainter {
  const _BoxMarkPainter({
    required this.state,
    required this.color,
    required this.filledFirst,
  });

  final int state;
  final Color color;
  final bool filledFirst;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final inset = size.width * 0.18;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );

    if (state == 1 && filledFirst) {
      canvas.drawRect(rect, Paint()..color = color);
      return;
    }
    if (state >= 1) {
      // barra: danno superficiale / contundente
      canvas.drawLine(rect.bottomLeft, rect.topRight, stroke);
    }
    if (state >= 2) {
      // croce: danno aggravato o letale
      canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
    }
    if (state >= 3) {
      // asterisco: aggravato sulla scheda 20°
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        stroke,
      );
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_BoxMarkPainter old) =>
      old.state != state || old.color != color;
}

/// Una singola casella toccabile di un tracker.
class TrackBox extends StatelessWidget {
  const TrackBox({
    super.key,
    required this.state,
    required this.maxState,
    required this.onChanged,
    this.size = 17,
    this.color = VtmColors.ink,
    this.filledFirst = false,
  });

  final int state;
  final int maxState;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color color;
  final bool filledFirst;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!((state + 1) % (maxState + 1));
            },
      onLongPress: onChanged == null ? null : () => onChanged!(0),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.2),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: CustomPaint(
            painter: _BoxMarkPainter(
              state: state,
              color: color,
              filledFirst: filledFirst,
            ),
          ),
        ),
      ),
    );
  }
}

/// Griglia di caselle: Punti Sangue, Volontà spesa, Salute della V5...
class BoxTrack extends StatelessWidget {
  const BoxTrack({
    super.key,
    required this.states,
    required this.maxState,
    required this.onChanged,
    this.perRow = 10,
    this.boxSize = 17,
    this.color = VtmColors.ink,
    this.filledFirst = false,
    this.alignment = WrapAlignment.center,
  });

  final List<int> states;
  final int maxState;
  final void Function(int index, int state)? onChanged;
  final int perRow;
  final double boxSize;
  final Color color;
  final bool filledFirst;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < states.length; start += perRow) {
      final end = (start + perRow).clamp(0, states.length);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = start; i < end; i++)
              TrackBox(
                state: states[i],
                maxState: maxState,
                size: boxSize,
                color: color,
                filledFirst: filledFirst,
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(i, value),
              ),
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// I sette livelli di Salute delle schede 20°, con etichetta e penalità.
class HealthLevels extends StatelessWidget {
  const HealthLevels({
    super.key,
    required this.track,
    required this.states,
    required this.onChanged,
    this.color = VtmColors.ink,
    this.labelStyle,
  });

  final TrackDef track;
  final List<int> states;
  final void Function(int index, int state)? onChanged;
  final Color color;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final style = labelStyle ?? SheetTextStyles.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < track.length; i++)
          Row(
            children: [
              Expanded(
                child: Text(
                  i < track.rowLabels.length ? track.rowLabels[i] : '',
                  style: style,
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  i < track.rowPenalties.length ? track.rowPenalties[i] : '',
                  style: style,
                  textAlign: TextAlign.center,
                ),
              ),
              TrackBox(
                state: i < states.length ? states[i] : 0,
                maxState: track.maxState,
                color: color,
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(i, value),
              ),
            ],
          ),
      ],
    );
  }
}
