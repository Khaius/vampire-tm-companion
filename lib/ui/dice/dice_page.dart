import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/dice.dart';
import '../shell/nav_icons.dart';
import '../widgets/dots.dart';

/// Il tavolo da gioco: si sceglie quanti d10 tirare, con che difficoltà, e si
/// leggono i risultati con i colori delle regole.
class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  DiceRoll? _result;
  String? _quickLabel;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _roll() {
    final state = context.read<AppState>();
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0);
    setState(() {
      _result = state.roll(label: _quickLabel);
      _quickLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Un tratto toccato sulla scheda arriva qui con i dadi gia' impostati.
    final quick = state.quickRoll;
    if (quick != null) {
      _quickLabel = quick.label;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppState>().consumeQuickRoll();
      });
    }

    final height = MediaQuery.sizeOf(context).height;
    final dieSize = math.min(height * 0.34, 260.0);

    return Scaffold(
      appBar: AppBar(title: const Text('DADI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          SizedBox(
            height: dieSize + 16,
            child: Center(
              child: _AnimatedDie(
                size: dieSize,
                controller: _shake,
                total: _result?.total,
              ),
            ),
          ),
          if (_quickLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: VtmColors.blood.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: VtmColors.blood.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'Tiro rapido · ${_quickLabel!}',
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 12.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          _PoolCounter(
            value: state.dicePool,
            onChanged: state.setDicePool,
          ),
          const SizedBox(height: 18),
          _DifficultyPicker(
            value: state.difficulty,
            onChanged: state.setDifficulty,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: VtmColors.blood,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _roll,
              child: const Text(
                'TIRA I DADI',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultPanel(roll: _result!),
          ],
          if (state.rollHistory.length > 1) ...[
            const SizedBox(height: 24),
            _HistoryPanel(
              rolls: state.rollHistory.skip(1).toList(),
              onClear: state.clearHistory,
            ),
          ],
        ],
      ),
    );
  }
}

/// Il d10 in cima alla pagina, che sussulta a ogni tiro.
class _AnimatedDie extends StatelessWidget {
  const _AnimatedDie({
    required this.size,
    required this.controller,
    required this.total,
  });

  final double size;
  final AnimationController controller;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        // oscillazione che si smorza, come un dado che si ferma
        final angle = math.sin(t * math.pi * 6) * 0.28 * (1 - t);
        final scale = 1 + math.sin(t * math.pi) * 0.06;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              VtmIcons.d10Large,
              width: size,
              height: size,
            ),
            if (total != null)
              Padding(
                // il numero va sulla faccia frontale, non al centro geometrico
                padding: EdgeInsets.only(bottom: size * 0.10),
                child: Text(
                  '$total',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.26,
                    color: total! > 0
                        ? VtmColors.successBright
                        : total! < 0
                        ? VtmColors.failureBright
                        : VtmColors.bone,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Contatore dei dadi: "-" a sinistra, "+" a destra, numero digitabile.
class _PoolCounter extends StatelessWidget {
  const _PoolCounter({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'NUMERO DI DADI',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 12,
            letterSpacing: 2,
            color: VtmColors.ash,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(
              icon: Icons.remove,
              // il minimo e' un dado: sotto non si scende
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            GestureDetector(
              onTap: () async {
                final result = await promptForNumber(
                  context,
                  title: 'Quanti dadi?',
                  initial: value,
                  min: 1,
                  max: 99,
                );
                if (result != null) onChanged(result);
              },
              child: Container(
                width: 108,
                height: 74,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VtmColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4A3234)),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            _RoundButton(
              icon: Icons.add,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Tocca il numero per scriverlo',
          style: TextStyle(color: VtmColors.ash, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? VtmColors.surfaceHigh : VtmColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            icon,
            size: 28,
            color: enabled ? VtmColors.bone : const Color(0xFF4A3E40),
          ),
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'DIFFICOLTÀ  $value',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 12,
            letterSpacing: 2,
            color: VtmColors.ash,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var d = 2; d <= 10; d++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DifficultyChip(
                    value: d,
                    selected: d == value,
                    onTap: () => onChanged(d),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VtmColors.blood : VtmColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? VtmColors.bloodBright : const Color(0xFF3A2C2E),
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 17,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? VtmColors.bone : VtmColors.ash,
            ),
          ),
        ),
      ),
    );
  }
}

/// I risultati su fondo chiaro, cosi' verde, rosso e nero si leggono tutti.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.roll});

  final DiceRoll roll;

  @override
  Widget build(BuildContext context) {
    final total = roll.total;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C8177)),
      ),
      child: Column(
        children: [
          Text(
            '${roll.pool} dadi · difficoltà ${roll.difficulty}'
            '${roll.label == null ? '' : ' · ${roll.label}'}',
            style: SheetTextStyles.small,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [for (final die in roll.results) _DieChip(die: die)],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFB6ADA1), height: 1),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Tally(
                label: 'Successi',
                value: '${roll.successes}',
                color: VtmColors.success,
              ),
              const SizedBox(width: 8),
              const Text('−', style: TextStyle(fontSize: 22, color: VtmColors.ink)),
              const SizedBox(width: 8),
              _Tally(
                label: 'Uno',
                value: '${roll.ones}',
                color: VtmColors.failure,
              ),
              const SizedBox(width: 14),
              Container(width: 1, height: 42, color: const Color(0xFFB6ADA1)),
              const SizedBox(width: 14),
              Column(
                children: [
                  const Text('TOTALE', style: SheetTextStyles.small),
                  Text(
                    total > 0 ? '+$total' : '$total',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: total > 0
                          ? VtmColors.success
                          : total < 0
                          ? VtmColors.failure
                          : VtmColors.neutralInk,
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

class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: SheetTextStyles.small),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Un singolo risultato: verde se raggiunge la difficoltà, rosso se e' un 1,
/// nero in tutti gli altri casi.
class _DieChip extends StatelessWidget {
  const _DieChip({required this.die});

  final DieResult die;

  @override
  Widget build(BuildContext context) {
    final color = switch (die.outcome) {
      DieOutcome.success => VtmColors.success,
      DieOutcome.one => VtmColors.failure,
      DieOutcome.neutral => VtmColors.neutralInk,
    };
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Text(
        '${die.value}',
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.rolls, required this.onClear});

  final List<DiceRoll> rolls;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TIRI PRECEDENTI',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                letterSpacing: 2,
                color: VtmColors.ash,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: onClear, child: const Text('Svuota')),
          ],
        ),
        for (final roll in rolls)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: VtmColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3A2C2E)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    roll.total > 0 ? '+${roll.total}' : '${roll.total}',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: roll.total > 0
                          ? VtmColors.successBright
                          : roll.total < 0
                          ? VtmColors.failureBright
                          : VtmColors.ash,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roll.values.join('  '),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${roll.pool}d10 · diff ${roll.difficulty}'
                        '${roll.label == null ? '' : ' · ${roll.label}'}',
                        style: const TextStyle(
                          color: VtmColors.ash,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
