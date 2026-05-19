import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../models/reaction.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showSenderName;
  final String? senderName;
  final bool isDark;
  final bool showTail;
  final List<Reaction> reactions;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onDoubleTap;
  final Animation<double>? animation;
  final Message? repliedMessage;
  final String? repliedSenderName;
  final bool peerRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderName = false,
    this.senderName,
    this.isDark = false,
    this.showTail = true,
    this.reactions = const [],
    this.onLongPress,
    this.onDoubleTap,
    this.animation,
    this.repliedMessage,
    this.repliedSenderName,
    this.peerRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? (isDark ? WAColors.bubbleSentDark : WAColors.bubbleSentLight)
        : (isDark ? WAColors.bubbleRecvDark : WAColors.bubbleRecvLight);
    final fg = isDark ? Colors.white : WAColors.inkLight;
    final senderColor = _nameColor(senderName ?? '');

    final grouped = <String, int>{};
    for (final r in reactions) {
      grouped.update(r.emoji, (v) => v + 1, ifAbsent: () => 1);
    }

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? 7.5 : (showTail ? 0 : 7.5)),
      topRight: Radius.circular(isMine ? (showTail ? 0 : 7.5) : 7.5),
      bottomLeft: const Radius.circular(7.5),
      bottomRight: const Radius.circular(7.5),
    );

    final screenW = MediaQuery.of(context).size.width;
    final bubbleMaxWidth = (screenW * 0.65).clamp(140.0, 520.0);
    final bubble = GestureDetector(
      onLongPressStart: (d) => onLongPress?.call(d.globalPosition),
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        margin: EdgeInsets.only(
          top: 1,
          bottom: 1,
          left: isMine ? 60 : (showTail ? 8 : 16),
          right: isMine ? (showTail ? 8 : 16) : 60,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 0.5, offset: const Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSenderName && !isMine && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(senderName!,
                    style: TextStyle(color: senderColor, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            if (repliedMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: const Border(
                      left: BorderSide(color: WAColors.brand, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        repliedSenderName ?? 'Reply',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WAColors.brand,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        repliedMessage!.body ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _bubbleContent(fg),
          ],
        ),
      ),
    );

    Widget rowChild = bubble;
    if (showTail) {
      rowChild = Stack(clipBehavior: Clip.none, children: [
        bubble,
        Positioned(
          top: 0,
          left: isMine ? null : 8,
          right: isMine ? 8 : null,
          child: CustomPaint(
            painter: _TailPainter(color: bg, leftSide: !isMine),
            size: const Size(10, 12),
          ),
        ),
      ]);
    }

    Widget result = Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          rowChild,
          if (grouped.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                margin: EdgeInsets.only(left: isMine ? 0 : 24, right: isMine ? 24 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: grouped.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              e.value > 1 ? '${e.key} ${e.value}' : e.key,
                              style: TextStyle(fontSize: 13, color: fg),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );

    if (animation != null) {
      final scaleAnimation = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation!, curve: Curves.easeOutBack));

      final slideAnimation = Tween<Offset>(
        begin: isMine ? const Offset(0.3, 0.15) : const Offset(-0.3, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation!, curve: Curves.easeOutCubic));

      result = FadeTransition(
        opacity: animation!,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: result,
          ),
        ),
      );
    }

    return result;
  }

  Widget _bubbleContent(Color fg) {
    final body = message.body ?? '';
    final timeText = DateFormat.jm().format(message.createdAt.toLocal());

    final time = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(timeText, style: TextStyle(fontSize: 11, color: WAColors.mutedLight)),
      if (isMine) ...[
        const SizedBox(width: 3),
        Icon(
          Icons.done_all,
          size: 15,
          color: peerRead ? WAColors.tickBlue : WAColors.mutedLight,
        ),
      ],
    ]);

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        _buildLinkifiedText(body, fg),
        const SizedBox(width: 8),
        Padding(padding: const EdgeInsets.only(top: 2), child: time),
      ],
    );
  }

  Widget _buildLinkifiedText(String body, Color fg) {
    final urlRe = RegExp(
      r'((https?://|www\.)[^\s]+)',
      caseSensitive: false,
    );
    final matches = urlRe.allMatches(body).toList();
    if (matches.isEmpty) {
      return Text(body, style: TextStyle(color: fg, fontSize: 14.5, height: 1.35));
    }
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: body.substring(cursor, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(
          color: Color(0xFF027EB5),
          decoration: TextDecoration.underline,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < body.length) {
      spans.add(TextSpan(text: body.substring(cursor)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: fg, fontSize: 14.5, height: 1.35),
        children: spans,
      ),
    );
  }

  Color _nameColor(String name) {
    const palette = [
      Color(0xFF1F7AEC),
      Color(0xFFE542A3),
      Color(0xFF8C6BB1),
      Color(0xFFD8624C),
      Color(0xFF00897B),
      Color(0xFF5C6BC0),
      Color(0xFF7E57C2),
      Color(0xFFEC407A),
    ];
    final h = name.codeUnits.fold(0, (a, b) => a + b);
    return palette[h % palette.length];
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  final bool leftSide;
  _TailPainter({required this.color, required this.leftSide});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();
    if (leftSide) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.6, size.height * 0.4, 0, size.height);
      path.close();
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color || old.leftSide != leftSide;
}

/// Wraps a [MessageBubble] with an entrance animation driven by an [Animation<double>]
/// (typically provided by an [AnimatedList]).
///
/// Animates:
/// - Scale 0.85 → 1.0
/// - Opacity 0.0 → 1.0
/// - Translate X: ±30px → 0 (toward the edge based on [MessageBubble.isMine])
/// - Curve: [Curves.elasticOut]
class AnimatedMessageBubble extends StatefulWidget {
  final MessageBubble child;
  final Animation<double> animation;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble> {
  late Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(parent: widget.animation, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(covariant AnimatedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved = CurvedAnimation(parent: widget.animation, curve: Curves.elasticOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        final value = _curved.value;
        final translateX = widget.child.isMine
            ? 30.0 * (1 - value)
            : -30.0 * (1 - value);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * value,
            child: Transform.translate(
              offset: Offset(translateX, 0),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience widget for [AnimatedList] item builder.
///
/// Accepts the same parameters as [MessageBubble] plus an [animation]
/// and returns the bubble wrapped in [AnimatedMessageBubble].
class SlideInBubble extends StatelessWidget {
  final Animation<double> animation;
  final Message message;
  final bool isMine;
  final bool showSenderName;
  final String? senderName;
  final bool isDark;
  final bool showTail;
  final List<Reaction> reactions;
  final void Function(Offset globalPosition)? onLongPress;
  final VoidCallback? onDoubleTap;

  const SlideInBubble({
    super.key,
    required this.animation,
    required this.message,
    required this.isMine,
    this.showSenderName = false,
    this.senderName,
    this.isDark = false,
    this.showTail = true,
    this.reactions = const [],
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedMessageBubble(
      animation: animation,
      child: MessageBubble(
        message: message,
        isMine: isMine,
        showSenderName: showSenderName,
        senderName: senderName,
        isDark: isDark,
        showTail: showTail,
        reactions: reactions,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}
