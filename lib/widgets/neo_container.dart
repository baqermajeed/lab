import 'package:flutter/material.dart';
import 'package:farah_new_lab/utils/constants.dart';

class NeoContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final bool inverted;

  const NeoContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(vertical: 10),
    this.radius = 18,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.background;
    final highlight = Colors.white.withOpacity(0.9);
    final shadow = const Color(0xFFB6C3CD);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : base,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // bottom-right shadow
          BoxShadow(
            color: shadow.withOpacity(0.45),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(10, 10),
          ),
          // top-left highlight
          BoxShadow(
            color: highlight.withOpacity(0.9),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(-8, -8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: inverted
              ? [Colors.white, Colors.grey.shade100]
              : [base, Colors.grey.shade100],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
