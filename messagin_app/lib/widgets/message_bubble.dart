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
  final List<Reaction> reactions;
  final void Function(Offset globalPosition)? onLongPress;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderName = false,
    this.senderName,
    this.isDark = false,
    this.reactions = const [],
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? (isDark ? LoopColors.bubbleMineDark : LoopColors.bubbleMine)
        : (isDark ? LoopColors.bubbleOtherDark : LoopColors.bubbleOther);
    final fg = isDark ? Colors.white : Colors.black87;
    final accentName = _nameColor(senderName ?? '');

    final grouped = <String, int>{};
    for (final r in reactions) {
      grouped.update(r.emoji, (v) => v + 1, ifAbsent: () => 1);
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPressStart: (d) => onLongPress?.call(d.globalPosition),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMine ? 12 : 2),
                    bottomRight: Radius.circular(isMine ? 2 : 12),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 1, offset: const Offset(0, 1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSenderName && !isMine && senderName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(senderName!,
                            style: TextStyle(color: accentName, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    Text(message.body ?? '', style: TextStyle(color: fg, fontSize: 15, height: 1.3)),
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(DateFormat.jm().format(message.createdAt.toLocal()),
                          style: TextStyle(fontSize: 10.5, color: fg.withValues(alpha: 0.55))),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: fg.withValues(alpha: 0.55)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
            if (grouped.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -8),
                child: Container(
                  margin: EdgeInsets.only(
                      left: isMine ? 0 : 14, right: isMine ? 14 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A3942) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3),
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
      ),
    );
  }

  Color _nameColor(String name) {
    const palette = [
      Color(0xFF0F6B56),
      Color(0xFFC64A30),
      Color(0xFF3A5FD9),
      Color(0xFF7048BF),
      Color(0xFFE8A13A),
      Color(0xFF2DAB6B),
    ];
    final h = name.codeUnits.fold(0, (a, b) => a + b);
    return palette[h % palette.length];
  }
}
