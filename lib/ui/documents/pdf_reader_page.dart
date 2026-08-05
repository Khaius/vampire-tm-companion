import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/document_repository.dart';

/// Lettore PDF offline con zoom a pizzico e ripresa dall'ultima pagina letta.
class PdfReaderPage extends StatefulWidget {
  const PdfReaderPage({super.key, required this.document});

  final LocalDocument document;

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  PdfControllerPinch? _controller;
  String? _error;
  int _page = 1;
  int _pages = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final path = await context.read<AppState>().documentRepository.pathOf(
        widget.document,
      );
      final controller = PdfControllerPinch(
        document: PdfDocument.openFile(path),
        initialPage: widget.document.lastPage,
      );
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _page = widget.document.lastPage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0809),
      appBar: AppBar(
        title: Text(
          widget.document.title.toUpperCase(),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _pages == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Pagina $_page di $_pages',
                    style: const TextStyle(
                      color: VtmColors.ash,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: VtmColors.blood),
              const SizedBox(height: 16),
              const Text(
                'Impossibile aprire il documento',
                style: TextStyle(fontFamily: 'Cinzel', fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: VtmColors.ash, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: VtmColors.blood),
      );
    }

    return PdfViewPinch(
      controller: controller,
      onDocumentLoaded: (document) {
        if (!mounted) return;
        setState(() => _pages = document.pagesCount);
      },
      onPageChanged: (page) {
        if (!mounted) return;
        setState(() => _page = page);
        context.read<AppState>().rememberPage(widget.document, page);
      },
      onDocumentError: (error) {
        if (!mounted) return;
        setState(() => _error = '$error');
      },
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(color: VtmColors.blood)),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(color: VtmColors.blood)),
      ),
    );
  }
}
