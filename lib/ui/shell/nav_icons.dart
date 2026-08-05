import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Le tre icone del menu: papiro (schede), d10 (dadi), libro aperto con
/// stelline (documenti). Sono asset vettoriali, quindi nitide a ogni densità.
class VtmIcons {
  static const scroll = 'assets/icons/scroll.svg';
  static const d10 = 'assets/icons/d10.svg';
  static const book = 'assets/icons/book.svg';
  static const d10Large = 'assets/icons/d10_large.svg';
}

class VtmIcon extends StatelessWidget {
  const VtmIcon(this.asset, {super.key, this.size = 26, required this.color});

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
