import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Scelta fra valori prestabiliti, per i campi che non si scrivono a mano
/// come la Generazione.
Future<String?> promptForChoice(
  BuildContext context, {
  required String title,
  required String initial,
  required List<String> options,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final option in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, option),
            child: Row(
              children: [
                Icon(
                  option == initial
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: option == initial
                      ? VtmColors.bloodBright
                      : VtmColors.ash,
                ),
                const SizedBox(width: 12),
                Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    fontWeight: option == initial
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text(
                  'Svuota',
                  style: TextStyle(color: VtmColors.ash),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Piccolo dialogo per inserire o correggere un testo della scheda.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  required String initial,
  bool multiline = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: multiline ? 4 : 1,
        maxLines: multiline ? 12 : 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Lascia vuoto per pulire'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Conferma'),
        ),
      ],
    ),
  );
}
