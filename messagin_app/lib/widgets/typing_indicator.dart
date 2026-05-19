import 'package:flutter/material.dart';
import '../theme.dart';

/// A compact typing indicator showing three bouncing dots.
///
/// Mimics the iMessage / WhatsApp typing bubble with staggered,
/// smoothly eased vertical motion.
class TypingIndicator extends StatefulWidget {
  final Color? dotColor;
  final double dotSize;
  final double spacing;

  const TypingIndicator({
    super.key,
    this.dotColor,
    this.dotSize = 6,
    this.spacing = 4,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  static const _durationMs = 450;
  static const _staggerMs = 150;

  late final AnimationController _controller;
  late final Animation<double> _dot1Anim;
  late final Animation<double> _dot2Anim;
  late final Animation<double> _dot3Anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    )..repeat(reverse: true);

    _dot1Anim = _buildDotAnimation(delayMs: 0);
    _dot2Anim = _buildDotAnimation(delayMs: _staggerMs);
    _dot3Anim = _buildDotAnimation(delayMs: _staggerMs * 2);
  }

  Animation<double> _buildDotAnimation({required int delayMs}) {
    final delayFraction = delayMs / _durationMs;
    return Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delayFraction.clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ?? WAColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(animation: _dot1Anim, color: color, size: widget.dotSize),
          SizedBox(width: widget.spacing),
          _Dot(animation: _dot2Anim, color: color, size: widget.dotSize),
          SizedBox(width: widget.spacing),
          _Dot(animation: _dot3Anim, color: color, size: widget.dotSize),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double size;

  const _Dot({
    required this.animation,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A mini message bubble that wraps [TypingIndicator] for use in chat lists.
///
/// Shows the typing dots inside a rounded pill with a subtle background,
/// matching the style of a received message bubble.
class TypingBubble extends StatelessWidget {
  final Color? dotColor;
  final Color? backgroundColor;
  final double dotSize;
  final double spacing;

  const TypingBubble({
    super.key,
    this.dotColor,
    this.backgroundColor,
    this.dotSize = 6,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? WAColors.bubbleRecvDark : WAColors.bubbleRecvLight);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TypingIndicator(
        dotColor: dotColor,
        dotSize: dotSize,
        spacing: spacing,
      ),
    );
  }
}
