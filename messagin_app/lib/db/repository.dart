import '../models/chat.dart';
import '../models/message.dart';
import '../models/reaction.dart';
import '../models/user.dart';
import 'neon_client.dart';

class Repository {
  final NeonClient db;
  Repository(this.db);

  Future<List<AppUser>> listUsers() async {
    final rows = await db.query('SELECT * FROM users ORDER BY name');
    return rows.map(AppUser.fromRow).toList();
  }

  Future<AppUser?> userByPhone(String phone) async {
    final rows = await db.query(
      'SELECT * FROM users WHERE phone = @phone',
      params: {'phone': phone},
    );
    if (rows.isEmpty) return null;
    return AppUser.fromRow(rows.first);
  }

  Future<AppUser> upsertUser(String phone, String name) async {
    final rows = await db.query(
      '''INSERT INTO users (phone, name) VALUES (@phone, @name)
         ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name
         RETURNING *''',
      params: {'phone': phone, 'name': name},
    );
    return AppUser.fromRow(rows.first);
  }

  Future<List<Chat>> listChatsFor(String userId) async {
    final rows = await db.query('''
      SELECT c.*,
        (SELECT m.body FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_body,
        (SELECT m.created_at FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_at,
        (SELECT m.sender_id FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_sender
      FROM chats c
      JOIN chat_members cm ON cm.chat_id = c.id
      WHERE cm.user_id = @uid
      ORDER BY last_at DESC NULLS LAST, c.created_at DESC
    ''', params: {'uid': userId});

    final chats = <Chat>[];
    for (final row in rows) {
      final memRows = await db.query('''
        SELECT u.* FROM users u
        JOIN chat_members cm ON cm.user_id = u.id
        WHERE cm.chat_id = @cid
      ''', params: {'cid': row['id']});
      final members = memRows.map(AppUser.fromRow).toList();
      chats.add(Chat(
        id: row['id'].toString(),
        isGroup: row['is_group'] as bool,
        title: row['title'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        createdAt: row['created_at'] as DateTime,
        members: members,
        lastMessageBody: row['last_body'] as String?,
        lastMessageAt: row['last_at'] as DateTime?,
        lastMessageSenderId: row['last_sender']?.toString(),
      ));
    }
    return chats;
  }

  Future<Chat> createDirectChat(String userId, String otherUserId) async {
    final existing = await db.query('''
      SELECT c.id FROM chats c
      WHERE c.is_group = false
        AND EXISTS (SELECT 1 FROM chat_members WHERE chat_id = c.id AND user_id = @a)
        AND EXISTS (SELECT 1 FROM chat_members WHERE chat_id = c.id AND user_id = @b)
      LIMIT 1
    ''', params: {'a': userId, 'b': otherUserId});
    String chatId;
    if (existing.isNotEmpty) {
      chatId = existing.first['id'].toString();
    } else {
      final c = await db.query(
        'INSERT INTO chats (is_group, created_by) VALUES (false, @u) RETURNING id',
        params: {'u': userId},
      );
      chatId = c.first['id'].toString();
      await db.query(
        'INSERT INTO chat_members (chat_id, user_id) VALUES (@c, @a)',
        params: {'c': chatId, 'a': userId},
      );
      await db.query(
        'INSERT INTO chat_members (chat_id, user_id) VALUES (@c, @b) ON CONFLICT DO NOTHING',
        params: {'c': chatId, 'b': otherUserId},
      );
    }
    final chats = await listChatsFor(userId);
    return chats.firstWhere((c) => c.id == chatId);
  }

  Future<Chat> createGroupChat(String userId, String title, List<String> memberIds) async {
    final c = await db.query(
      'INSERT INTO chats (is_group, title, created_by) VALUES (true, @t, @u) RETURNING id',
      params: {'t': title, 'u': userId},
    );
    final chatId = c.first['id'].toString();
    final all = <String>{userId, ...memberIds}.toList();
    for (final uid in all) {
      await db.query(
        'INSERT INTO chat_members (chat_id, user_id, role) VALUES (@c, @u, @r) ON CONFLICT DO NOTHING',
        params: {'c': chatId, 'u': uid, 'r': uid == userId ? 'admin' : 'member'},
      );
    }
    final chats = await listChatsFor(userId);
    return chats.firstWhere((cc) => cc.id == chatId);
  }

  Future<List<Message>> listMessages(String chatId, {int limit = 200}) async {
    final rows = await db.query(
      'SELECT * FROM messages WHERE chat_id = @c ORDER BY created_at ASC LIMIT @l',
      params: {'c': chatId, 'l': limit},
    );
    return rows.map(Message.fromRow).toList();
  }

  Future<Message> sendMessage(String chatId, String senderId, String body) async {
    final rows = await db.query(
      '''INSERT INTO messages (chat_id, sender_id, body, kind)
         VALUES (@c, @s, @b, 'text') RETURNING *''',
      params: {'c': chatId, 's': senderId, 'b': body},
    );
    return Message.fromRow(rows.first);
  }

  Future<List<Message>> messagesSince(String chatId, DateTime since) async {
    final rows = await db.query(
      'SELECT * FROM messages WHERE chat_id = @c AND created_at > @t ORDER BY created_at ASC',
      params: {'c': chatId, 't': since},
    );
    return rows.map(Message.fromRow).toList();
  }

  Future<List<Reaction>> reactionsForChat(String chatId) async {
    final rows = await db.query('''
      SELECT mr.* FROM message_reactions mr
      JOIN messages m ON m.id = mr.message_id
      WHERE m.chat_id = @c
    ''', params: {'c': chatId});
    return rows.map(Reaction.fromRow).toList();
  }

  Future<void> toggleReaction(String messageId, String userId, String emoji) async {
    final existing = await db.query(
      'SELECT emoji FROM message_reactions WHERE message_id = @m AND user_id = @u',
      params: {'m': messageId, 'u': userId},
    );
    if (existing.isEmpty) {
      await db.query(
        'INSERT INTO message_reactions (message_id, user_id, emoji) VALUES (@m, @u, @e)',
        params: {'m': messageId, 'u': userId, 'e': emoji},
      );
    } else if (existing.first['emoji'] == emoji) {
      await db.query(
        'DELETE FROM message_reactions WHERE message_id = @m AND user_id = @u',
        params: {'m': messageId, 'u': userId},
      );
    } else {
      await db.query(
        'UPDATE message_reactions SET emoji = @e, created_at = now() WHERE message_id = @m AND user_id = @u',
        params: {'m': messageId, 'u': userId, 'e': emoji},
      );
    }
  }
}
