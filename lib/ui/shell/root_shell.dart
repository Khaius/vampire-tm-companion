import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../characters/character_list_page.dart';
import '../characters/sheet_page.dart';
import '../dice/dice_page.dart';
import '../documents/documents_page.dart';
import 'bottom_menu.dart';

/// Tiene il conto di quante rotte ci sono nello stack di una scheda del menu,
/// per capire se la scheda personaggio e' gia' aperta.
class _DepthObserver extends NavigatorObserver {
  int depth = 0;

  @override
  void didPush(Route route, Route? previousRoute) => depth++;

  @override
  void didPop(Route route, Route? previousRoute) => depth--;

  @override
  void didRemove(Route route, Route? previousRoute) => depth--;

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {}
}

/// La struttura dell'app: tre sezioni con il proprio stack di navigazione e
/// il menu sempre visibile in basso.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _navKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());
  final _observers = List.generate(3, (_) => _DepthObserver());
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (identical(state, _state)) return;
    _state?.tabRequest.removeListener(_onTabRequested);
    _state = state;
    state.tabRequest.addListener(_onTabRequested);
  }

  /// Il tiro rapido partito da una scheda chiede di passare ai dadi.
  void _onTabRequested() {
    final requested = _state?.tabRequest.value;
    if (requested == null) return;
    _state?.tabRequest.value = null;
    if (!mounted || requested == _index) return;
    setState(() => _index = requested);
  }

  @override
  void dispose() {
    _state?.tabRequest.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onMenuTap(int index) {
    final previous = _index;
    if (previous != index) {
      setState(() => _index = index);
    } else {
      // Secondo tocco sulla stessa voce: si torna in cima alla sezione,
      // tranne per le schede dove la scheda aperta ha la precedenza.
      if (index != 0) {
        _navKeys[index].currentState?.popUntil((r) => r.isFirst);
      }
    }
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSheet());
    }
  }

  /// Se una scheda e' stata selezionata e non e' stata chiusa a mano, tornando
  /// sulla sezione Schede si riapre quella, non la lista.
  void _restoreSheet() {
    if (!mounted) return;
    final state = context.read<AppState>();
    final id = state.selectedCharacterId;
    if (id == null) return;
    if (state.characterById(id) == null) return;
    // Si ripristina solo se siamo fermi sulla lista: non si scavalca un
    // editor o un'altra pagina che l'utente ha aperto apposta.
    if (_observers[0].depth > 1) return;
    _navKeys[0].currentState?.push(sheetPageRoute(id));
  }

  Future<bool> _handleBack() async {
    final navigator = _navKeys[_index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Il tasto indietro percorre prima lo stack della sezione, poi torna
        // alle schede; solo da li' esce davvero dall'app.
        if (await _handleBack()) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _TabNavigator(
              navigatorKey: _navKeys[0],
              observer: _observers[0],
              child: const CharacterListPage(),
            ),
            _TabNavigator(
              navigatorKey: _navKeys[1],
              observer: _observers[1],
              child: const DicePage(),
            ),
            _TabNavigator(
              navigatorKey: _navKeys[2],
              observer: _observers[2],
              child: const DocumentsPage(),
            ),
          ],
        ),
        bottomNavigationBar: BottomMenu(
          currentIndex: _index,
          onTap: _onMenuTap,
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.observer,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final NavigatorObserver observer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [observer],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => child, settings: settings),
    );
  }
}
