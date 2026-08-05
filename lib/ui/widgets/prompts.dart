import 'package:flutter/material.dart';

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
