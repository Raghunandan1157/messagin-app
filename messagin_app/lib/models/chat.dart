import 'user.dart';

class Chat {
  final String id;
  final bool isGroup;
  final String? title;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<AppUser> members;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;

  Chat({
    required this.id,
    required this.isGroup,
    this.title,
    this.avatarUrl,
    required this.createdAt,
    this.members = const [],
    this.lastMessageBody,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  String displayTitle(String selfUserId) {
    if (title != null && title!.isNotEmpty) return title!;
    final others = members.where((m) => m.id != selfUserId).toList();
    if (others.isEmpty) return 'You';
    if (isGroup) return others.map((m) => m.name).take(3).join(', ');
    return others.first.name;
  }

  String displayInitials(String selfUserId) {
    if (isGroup) return (title ?? 'G').substring(0, 1).toUpperCase();
    final others = members.where((m) => m.id != selfUserId).toList();
    if (others.isEmpty) return '?';
    return others.first.initials;
  }
}
