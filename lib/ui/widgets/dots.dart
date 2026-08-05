import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// Fila di "pallini" come sulle schede cartacee.
///
/// Un tocco assegna il valore corrispondente; toccare il pallino gia' pieno
/// piu' a destra toglie un punto, cosi' si sale e si scende senza menu.
class DotRow extends StatelessWidget {
  const DotRow({
    super.key,
    required this.value,
    required this.max,
    this.onChanged,
    this.size = 13,
    this.spacing = 2.4,
    this.color = VtmColors.ink,
    this.filledColor,
    this.alignment = MainAxisAlignment.start,
  });

  final int value;
  final int max;
  final ValueChanged<int>? onChanged;
  final double size;
  final double spacing;
  final Color color;
  final Color? filledColor;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final fill = filledColor ?? color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        for (var i = 1; i <= max; i++)
          Padding(
            padding: EdgeInsets.only(right: i == max ? 0 : spacing),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged!(value == i ? i - 1 : i);
                    },
              child: Padding(
                // area di tocco piu' generosa del pallino disegnato
                padding: EdgeInsets.symmetric(vertical: size * 0.42),
                child: _Dot(
                  filled: i <= value,
                  size: size,
                  color: color,
                  fillColor: fill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.filled,
    required this.size,
    required this.color,
    required this.fillColor,
  });

  final bool filled;
  final double size;
  final Color color;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? fillColor : Colors.transparent,
        border: Border.all(color: color, width: 1.2),
      ),
    );
  }
}

/// Pallini piu' un campo numerico: e' il controllo usato nell'editor, dove il
/// valore si puo' anche digitare. Il numero viene sempre riportato
/// nell'intervallo 0..[max] consentito dalla scheda.
class DotStepper extends StatelessWidget {
  const DotStepper({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.trailing,
    this.dotColor = VtmColors.ash,
    this.labelStyle,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final Widget? trailing;
  final Color dotColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? const TextStyle(fontSize: 15.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
          const SizedBox(width: 8),
          DotRow(
            value: value,
            max: max,
            onChanged: onChanged,
            color: dotColor,
            filledColor: VtmColors.bloodBright,
            size: 12,
          ),
          const SizedBox(width: 8),
          _ValueBadge(value: value, max: max, onChanged: onChanged, label: label),
        ],
      ),
    );
  }
}

/// Il numerino accanto ai pallini: si tocca e si scrive il valore.
class _ValueBadge extends StatelessWidget {
  const _ValueBadge({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.label,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final result = await promptForNumber(
          context,
          title: label,
          initial: value,
          min: 0,
          max: max,
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        width: 34,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: VtmColors.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A2C2E)),
        ),
        child: Text(
          '$value',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Chiede un numero all'utente, tenendolo dentro i limiti della scheda.
Future<int?> promptForNumber(
  BuildContext context, {
  required String title,
  required int initial,
  required int min,
  required int max,
}) {
  final controller = TextEditingController(text: '$initial');
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valore consentito da $min a $max',
              style: const TextStyle(color: VtmColors.ash, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontFamily: 'Cinzel'),
              onSubmitted: (text) {
                final parsed = int.tryParse(text);
                Navigator.pop(context, parsed?.clamp(min, max));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              Navigator.pop(context, parsed?.clamp(min, max));
            },
            child: const Text('Conferma'),
          ),
        ],
      );
    },
  );
}
