import 'package:flutter/material.dart';
import '../theme.dart';

class LoopAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? color;
  const LoopAvatar({super.key, required this.initials, this.size = 44, this.color});

  @override
  Widget build(BuildContext context) {
    final hash = initials.codeUnits.fold(0, (a, b) => a + b);
    final palette = [
      const Color(0xFF0F6B56),
      const Color(0xFFE8A13A),
      const Color(0xFF3A5FD9),
      const Color(0xFF7048BF),
      const Color(0xFFC64A30),
      const Color(0xFF2DAB6B),
    ];
    final bg = color ?? palette[hash % palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

class LoopLogo extends StatelessWidget {
  final double size;
  const LoopLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: LoopColors.brand,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: const Icon(Icons.all_inclusive, color: Colors.white, size: 20),
    );
  }
}
