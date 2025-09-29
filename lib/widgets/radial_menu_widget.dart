import 'dart:math' as math;

import 'package:fab_dracailles/theme/colors.dart';
import 'package:flutter/material.dart';

class RadialAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const RadialAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}

// Menu radial générique (icônes)
class RadialMenu extends StatefulWidget {
  final Offset center;
  final double radius;
  final List<RadialAction> items;

  const RadialMenu({
    super.key,
    required this.center,
    required this.radius,
    required this.items,
  });

  @override
  State<RadialMenu> createState() => RadialMenuState();
}

class RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final radius = widget.radius * _anim.value;

        return Stack(
          children: [
            // Point d’ancrage central (invisible)
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _CenterAnchorDelegate(widget.center),
                child: const SizedBox(width: 1, height: 1),
              ),
            ),

            // Items sur le cercle
            ...List.generate(widget.items.length, (i) {
              final angle =
                  (-math.pi / 2) + (2 * math.pi * i / widget.items.length);
              final dx = radius * math.cos(angle);
              final dy = radius * math.sin(angle);

              final left = (widget.center.dx + dx).clamp(0.0, size.width);
              final top = (widget.center.dy + dy).clamp(0.0, size.height);

              return Positioned(
                left: left - 28, // 56/2 pour centrer le bouton
                top: top - 28,
                child: Opacity(
                  opacity: _anim.value,
                  child: Transform.scale(
                    scale: _anim.value,
                    child: _RadialIconButton(
                      icon: widget.items[i].icon,
                      tooltip: widget.items[i].tooltip,
                      onTap: widget.items[i].onTap,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CenterAnchorDelegate extends SingleChildLayoutDelegate {
  final Offset center;
  _CenterAnchorDelegate(this.center);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
        center.dx - childSize.width / 2, center.dy - childSize.height / 2);
  }

  @override
  bool shouldRelayout(_CenterAnchorDelegate oldDelegate) =>
      oldDelegate.center != center;
}

// Bouton circulaire avec icône + ripple + tooltip
class _RadialIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RadialIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: ThemeColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
