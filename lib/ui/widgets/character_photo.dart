import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/character.dart';

/// Il ritratto del personaggio, se ne ha uno.
///
/// La foto sta su disco e non in memoria: qui si va a cercarla ogni volta,
/// perche' e' un file solo e Flutter tiene comunque la sua cache delle
/// immagini. [version] serve a forzare la rilettura quando la foto cambia.
class CharacterPhoto extends StatelessWidget {
  const CharacterPhoto({
    super.key,
    required this.state,
    required this.character,
    this.size = 96,
    this.radius = 10,
    this.version = 0,
    this.placeholder,
  });

  final AppState state;
  final Character character;
  final double size;
  final double radius;
  final int version;

  /// Cosa mostrare quando la foto non c'e'.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // la chiave lega il futuro alla foto corrente: cambiandola si rilegge
      key: ValueKey('${character.id}_${character.photoFile}_$version'),
      future: state.characterRepository.photoPath(character),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return placeholder ?? const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            // il file cambia ma il percorso no: senza questo si vedrebbe
            // ancora la foto di prima
            key: ValueKey('$path#$version'),
            errorBuilder: (_, _, _) => placeholder ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Chiede una foto alla galleria del telefono e la mette nella scheda.
///
/// Passa dal selettore di sistema, quindi non serve nessun permesso: l'app
/// riceve il singolo file che l'utente ha scelto e nient'altro.
/// Restituisce true se la scheda e' cambiata.
Future<bool> pickCharacterPhoto(AppState state, Character character) async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Immagini',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        mimeTypes: ['image/*'],
        uniformTypeIdentifiers: ['public.image'],
      ),
    ],
  );
  if (file == null) return false;
  await state.setPhoto(character, file.path);
  return true;
}

/// Il riquadro della foto con i comandi, usato nell'editor.
class PhotoField extends StatefulWidget {
  const PhotoField({
    super.key,
    required this.state,
    required this.character,
    required this.onChanged,
  });

  final AppState state;
  final Character character;
  final VoidCallback onChanged;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  int _version = 0;
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final changed = await pickCharacterPhoto(widget.state, widget.character);
      if (changed) {
        _version++;
        widget.onChanged();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await widget.state.removePhoto(widget.character);
    if (!mounted) return;
    setState(() => _version++);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.character.photoFile != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _busy ? null : _pick,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: VtmColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3A2C2E)),
              ),
              child: _busy
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : CharacterPhoto(
                      state: widget.state,
                      character: widget.character,
                      size: 92,
                      version: _version,
                      placeholder: const Icon(
                        Icons.person_outline,
                        size: 40,
                        color: VtmColors.ash,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? 'Foto del personaggio' : 'Nessuna foto',
                  style: const TextStyle(color: VtmColors.bone, fontSize: 15),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Presa dalla memoria del telefono e copiata nella scheda.',
                  style: TextStyle(color: VtmColors.ash, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(hasPhoto ? 'Cambia' : 'Scegli'),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        onPressed: _busy ? null : _remove,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Togli'),
                        style: TextButton.styleFrom(
                          foregroundColor: VtmColors.ash,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
