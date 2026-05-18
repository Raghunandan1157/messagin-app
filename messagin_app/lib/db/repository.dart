import 'dart:convert';
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
      WITH my_chats AS (
        SELECT c.id, c.is_group, c.title, c.avatar_url, c.created_at
        FROM chats c
        JOIN chat_members cm ON cm.chat_id = c.id
        WHERE cm.user_id = @uid
      ),
      last_msg AS (
        SELECT DISTINCT ON (m.chat_id) m.chat_id, m.body, m.created_at AS last_at, m.sender_id
        FROM messages m
        WHERE m.chat_id IN (SELECT id FROM my_chats)
        ORDER BY m.chat_id, m.created_at DESC
      ),
      members AS (
        SELECT cm.chat_id,
          json_agg(json_build_object(
            'id', u.id, 'phone', u.phone, 'name', u.name,
            'avatar_url', u.avatar_url, 'about', u.about,
            'emp_id', u.emp_id, 'role', u.role, 'location', u.location
          )) AS member_json
        FROM chat_members cm
        JOIN users u ON u.id = cm.user_id
        WHERE cm.chat_id IN (SELECT id FROM my_chats)
        GROUP BY cm.chat_id
      )
      SELECT c.*, lm.body AS last_body, lm.last_at, lm.sender_id AS last_sender, m.member_json
      FROM my_chats c
      LEFT JOIN last_msg lm ON lm.chat_id = c.id
      LEFT JOIN members m ON m.chat_id = c.id
      ORDER BY lm.last_at DESC NULLS LAST, c.created_at DESC
    ''', params: {'uid': userId});

    final chats = <Chat>[];
    for (final row in rows) {
      final raw = row['member_json'];
      List<dynamic> memRows;
      if (raw is String) {
        memRows = jsonDecode(raw) as List;
      } else if (raw is List) {
        memRows = raw;
      } else {
        memRows = const [];
      }
      final members = memRows
          .map((m) => AppUser.fromRow(Map<String, dynamic>.from(m as Map)))
          .toList();
      chats.add(Chat(
        id: row['id'].toString(),
        isGroup: row['is_group'] as bool,
        title: row['title'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        createdAt: _parseDate(row['created_at']),
        members: members,
        lastMessageBody: row['last_body'] as String?,
        lastMessageAt: row['last_at'] == null ? null : _parseDate(row['last_at']),
        lastMessageSenderId: row['last_sender']?.toString(),
      ));
    }
    return chats;
  }

  DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw Exception('Bad date: $v');
  }

  Future<Chat> createDirectChat(String userId, String otherUserId, {AppUser? me, AppUser? other}) async {
    // Single round-trip: find-or-create the direct chat. Uses CTEs so we
    // only pay one Neon hop instead of 4.
    final rows = await db.query('''
      WITH existing AS (
        SELECT c.id, c.is_group, c.title, c.avatar_url, c.created_at, false AS just_created
        FROM chats c
        WHERE c.is_group = false
          AND EXISTS (SELECT 1 FROM chat_members WHERE chat_id = c.id AND user_id = @a)
          AND EXISTS (SELECT 1 FROM chat_members WHERE chat_id = c.id AND user_id = @b)
        LIMIT 1
      ),
      new_chat AS (
        INSERT INTO chats (is_group, created_by)
        SELECT false, @a
        WHERE NOT EXISTS (SELECT 1 FROM existing)
        RETURNING id, is_group, title, avatar_url, created_at, true AS just_created
      ),
      new_members AS (
        INSERT INTO chat_members (chat_id, user_id)
        SELECT id, uid FROM new_chat, unnest(ARRAY[@a, @b]::uuid[]) AS uid
        ON CONFLICT DO NOTHING
        RETURNING chat_id
      )
      SELECT * FROM existing
      UNION ALL
      SELECT id, is_group, title, avatar_url, created_at, just_created FROM new_chat
    ''', params: {'a': userId, 'b': otherUserId});

    final row = rows.first;
    final members = (me != null && other != null) ? [me, other] : <AppUser>[];
    return Chat(
      id: row['id'].toString(),
      isGroup: row['is_group'] as bool,
      title: row['title'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: _parseDate(row['created_at']),
      members: members,
    );
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
