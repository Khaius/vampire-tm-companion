import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/document_repository.dart';
import '../shell/nav_icons.dart';
import '../widgets/prompts.dart';
import 'pdf_reader_page.dart';

/// La libreria dei manuali: PDF scelti dall'utente e copiati nel telefono,
/// consultabili anche senza connessione.
class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  bool _importing = false;

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      const pdfGroup = XTypeGroup(
        label: 'PDF',
        extensions: <String>['pdf'],
        mimeTypes: <String>['application/pdf'],
        uniformTypeIdentifiers: <String>['com.adobe.pdf'],
      );
      final picked = await openFile(acceptedTypeGroups: const [pdfGroup]);
      if (picked == null || !mounted) return;

      final path = picked.path;
      final suggested = picked.name.replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      final title = await promptForText(
        context,
        title: 'Titolo del documento',
        initial: suggested,
      );
      if (!mounted) return;

      await context.read<AppState>().importDocument(
        sourcePath: path,
        title: (title == null || title.trim().isEmpty) ? suggested : title.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento salvato sul dispositivo')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile importare il PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.select<AppState, List<LocalDocument>>(
      (s) => s.documents,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('DOCUMENTI')),
      floatingActionButton: FloatingActionButton(
        onPressed: _importing ? null : _import,
        tooltip: 'Aggiungi un PDF',
        child: _importing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: VtmColors.bone,
                ),
              )
            : const Icon(Icons.add, size: 30),
      ),
      body: documents.isEmpty
          ? const _EmptyDocuments()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
              itemCount: documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _DocumentCard(document: documents[index]),
            ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VtmIcon(VtmIcons.book, size: 64, color: Color(0xFF4A3B3D)),
            const SizedBox(height: 22),
            Text(
              'Nessun documento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Usa il "+" in basso a destra per caricare un PDF: resta salvato '
              'nel telefono e si consulta anche offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VtmColors.ash, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final LocalDocument document;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PdfReaderPage(document: document)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VtmColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: VtmColors.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: const VtmIcon(
                  VtmIcons.book,
                  size: 24,
                  color: VtmColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.lastPage > 1
                          ? '${document.readableSize} · ripresa a pag. ${document.lastPage}'
                          : document.readableSize,
                      style: const TextStyle(
                        color: VtmColors.ash,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'rename') {
                    final title = await promptForText(
                      context,
                      title: 'Rinomina documento',
                      initial: document.title,
                    );
                    if (title != null && title.trim().isNotEmpty) {
                      await state.renameDocument(document, title.trim());
                    }
                  } else if (value == 'delete') {
                    if (!context.mounted) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminare il documento?'),
                        content: Text(
                          '"${document.title}" verrà rimosso dal dispositivo.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: VtmColors.blood,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await state.deleteDocument(document);
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rinomina')),
                  PopupMenuItem(value: 'delete', child: Text('Elimina')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
