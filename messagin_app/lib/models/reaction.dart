class Reaction {
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  Reaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory Reaction.fromRow(Map<String, dynamic> row) => Reaction(
        messageId: row['message_id'].toString(),
        userId: row['user_id'].toString(),
        emoji: row['emoji'] as String,
        createdAt: row['created_at'] as DateTime,
      );
}
