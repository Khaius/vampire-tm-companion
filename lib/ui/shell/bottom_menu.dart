import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'nav_icons.dart';

class MenuEntry {
  const MenuEntry(this.asset, this.label);
  final String asset;
  final String label;
}

const menuEntries = [
  MenuEntry(VtmIcons.scroll, 'Schede'),
  MenuEntry(VtmIcons.d10, 'Dadi'),
  MenuEntry(VtmIcons.book, 'Documenti'),
];

/// Il menu sempre presente in fondo allo schermo.
class BottomMenu extends StatelessWidget {
  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VtmColors.surface,
        border: Border(top: BorderSide(color: Color(0xFF3A2C2E))),
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < menuEntries.length; i++)
                Expanded(
                  child: _MenuButton(
                    entry: menuEntries[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final MenuEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? VtmColors.bloodBright : VtmColors.ash;
    return Semantics(
      button: true,
      selected: selected,
      label: entry.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selected ? 26 : 0,
              decoration: BoxDecoration(
                color: VtmColors.bloodBright,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 7),
            VtmIcon(entry.asset, color: color, size: selected ? 27 : 25),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 10.5,
                letterSpacing: 0.8,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
