import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import 'avatar.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final String selfUserId;
  final VoidCallback onTap;
  const ChatTile({super.key, required this.chat, required this.selfUserId, required this.onTap});

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final local = t.toLocal();
    if (now.year == local.year && now.month == local.month && now.day == local.day) {
      return DateFormat.jm().format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat.E().format(local);
    }
    return DateFormat('dd/MM/yy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final last = chat.lastMessageBody;
    final t = chat.lastMessageAt;
    final isMine = chat.lastMessageSenderId == selfUserId;
    return ListTile(
      onTap: onTap,
      leading: LoopAvatar(initials: chat.displayInitials(selfUserId), size: 48),
      title: Text(
        chat.displayTitle(selfUserId),
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: last == null
          ? Text(chat.isGroup ? 'Group · ${chat.members.length} members' : 'Tap to chat',
              style: TextStyle(color: Colors.grey.shade600))
          : Row(children: [
              if (isMine) ...[
                Icon(Icons.done_all, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700))),
            ]),
      trailing: t == null
          ? null
          : Text(_formatTime(t), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    );
  }
}
