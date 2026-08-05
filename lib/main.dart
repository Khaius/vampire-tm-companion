import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'ui/shell/nav_icons.dart';
import 'ui/shell/root_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VtmColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VtmCompanionApp());
}

class VtmCompanionApp extends StatelessWidget {
  const VtmCompanionApp({super.key, this.state});

  /// Stato preconfezionato, usato dai test per isolare l'archivio su disco.
  final AppState? state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => state ?? (AppState()..init()),
      child: MaterialApp(
        title: 'VtM Companion',
        debugShowCheckedModeBanner: false,
        theme: buildVtmTheme(),
        home: const _Bootstrap(),
      ),
    );
  }
}

/// Schermata di avvio: dura giusto il tempo di leggere schede e documenti
/// dal disco, poi lascia il posto all'app.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AppState, bool>((s) => s.ready);
    if (ready) return const RootShell();
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VtmIcon(VtmIcons.d10, size: 64, color: VtmColors.blood),
            SizedBox(height: 20),
            Text(
              'VTM COMPANION',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 16,
                letterSpacing: 4,
                color: VtmColors.ash,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
