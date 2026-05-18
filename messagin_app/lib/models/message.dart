class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? body;
  final String kind;
  final String? replyTo;
  final DateTime createdAt;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.kind,
    required this.createdAt,
    this.body,
    this.replyTo,
    this.editedAt,
  });

  factory Message.fromRow(Map<String, dynamic> row) => Message(
        id: row['id'].toString(),
        chatId: row['chat_id'].toString(),
        senderId: row['sender_id'].toString(),
        body: row['body'] as String?,
        kind: row['kind'] as String,
        replyTo: row['reply_to']?.toString(),
        createdAt: row['created_at'] as DateTime,
        editedAt: row['edited_at'] as DateTime?,
      );
}
