import 'package:flutter/material.dart';

const reactionEmojis = ['❤️', '😂', '😮', '😢', '🙏', '👍'];

Future<String?> showReactionPicker(BuildContext context, Offset globalPosition) {
  final screen = MediaQuery.of(context).size;
  final left = (globalPosition.dx - 160).clamp(8.0, screen.width - 320);
  final top = (globalPosition.dy - 60).clamp(40.0, screen.height - 80);
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black26,
    barrierDismissible: true,
    builder: (_) => Stack(children: [
      Positioned(
        left: left.toDouble(),
        top: top.toDouble(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...reactionEmojis.map((e) => InkWell(
                      onTap: () => Navigator.pop(context, e),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    )),
                InkWell(
                  onTap: () => Navigator.pop(context, '+'),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add_circle_outline, size: 28, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ]),
  );
}

const fullEmojiSet = [
  '❤️','😂','😮','😢','🙏','👍','🔥','🎉','😍','😭','😡','👏',
  '🥰','😎','🤔','🙄','😴','🤣','💯','✨','💔','💪','🤝','🫡',
  '🥳','😅','😬','😱','🙌','👀','🤯','🤗','😋','🫶','🤩','😊',
];

Future<String?> showFullEmojiSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: fullEmojiSet.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8),
          itemBuilder: (_, i) => InkWell(
            onTap: () => Navigator.pop(context, fullEmojiSet[i]),
            child: Center(child: Text(fullEmojiSet[i], style: const TextStyle(fontSize: 28))),
          ),
        ),
      ),
    ),
  );
}
