import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared shimmer controller widget. Provides an animation value that
/// pulses a base color between [baseColor] and [highlightColor].
/// Uses an [AnimatedBuilder] + repeating [AnimationController] so no
/// extra dependency is required.
class _Shimmer extends StatefulWidget {
  final Widget Function(BuildContext context, Color color) builder;
  const _Shimmer({required this.builder});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _base = Color(0xFFE6E6E6);
  static const _highlight = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final color = Color.lerp(_base, _highlight, _ctrl.value)!;
        return widget.builder(ctx, color);
      },
    );
  }
}

/// A single grey rectangle that shimmers.
class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      builder: (_, color) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      ),
    );
  }
}

/// A single grey circle that shimmers.
class _ShimmerCircle extends StatelessWidget {
  final double size;
  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      builder: (_, color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Skeleton row matching the chat tile layout used in HomeShell._ChatRow:
/// avatar circle (49) + title line + subtitle line.
class ChatTileSkeleton extends StatelessWidget {
  const ChatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const _ShimmerCircle(size: 49),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: _ShimmerBox(height: 14)),
                const SizedBox(width: 12),
                _ShimmerBox(
                  width: 36,
                  height: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
              const SizedBox(height: 10),
              const _ShimmerBox(width: 180, height: 12),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Skeleton placeholder bubble matching MessageBubble layout.
class MessageBubbleSkeleton extends StatelessWidget {
  final bool isMine;
  final double width;
  const MessageBubbleSkeleton({
    super.key,
    required this.isMine,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? WAColors.bubbleSentLight : WAColors.bubbleRecvLight;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(7.5),
      topRight: const Radius.circular(7.5),
      bottomLeft: const Radius.circular(7.5),
      bottomRight: const Radius.circular(7.5),
    );
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMine ? 60 : 16,
          right: isMine ? 16 : 60,
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 0.5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              child: const _ShimmerBox(height: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: width * 0.7,
              child: const _ShimmerBox(height: 12),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.bottomRight,
              child: _ShimmerBox(width: 36, height: 8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton row for contact lists (new chat screen).
class ContactTileSkeleton extends StatelessWidget {
  const ContactTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const _ShimmerCircle(size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShimmerBox(width: 140, height: 14),
              SizedBox(height: 8),
              _ShimmerBox(width: 200, height: 11),
            ],
          ),
        ),
      ]),
    );
  }
}
