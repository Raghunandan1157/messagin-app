import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';

/// Local SQLite cache that mirrors a subset of Neon for instant boot.
///
/// - On android/ios/macos, sqflite ships native bindings out-of-the-box.
/// - On web (kIsWeb), all calls are no-ops; UI must fall back to remote.
/// - On desktop linux/windows, if sqflite is unavailable at runtime, init
///   fails gracefully and the cache disables itself (no-op fallbacks).
///
/// All DB calls are async — sqflite runs queries off the main isolate.
class LocalCache {
  Database? _db;
  bool _disabled = false;
  Future<void>? _initFuture;

  bool get isEnabled => !_disabled && !kIsWeb;

  Future<void> init() async {
    if (kIsWeb) {
      _disabled = true;
      return;
    }
    if (_db != null || _disabled) return;
    _initFuture ??= _openDb();
    await _initFuture;
  }

  Future<void> _openDb() async {
    try {
      // sqflite ships native bindings for Android, iOS, macOS only. For
      // desktop Linux/Windows we'd need sqflite_common_ffi — disable
      // gracefully there until that's wired in.
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
        _disabled = true;
        return;
      }
      final docs = await getApplicationDocumentsDirectory();
      final sep = docs.path.endsWith('/') ? '' : '/';
      final dbPath = '${docs.path}${sep}messagin.db';
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      );
    } catch (e, st) {
      // sqflite not registered on this platform — fall back to no-op cache.
      debugPrint('LocalCache disabled: $e\n$st');
      _disabled = true;
      _db = null;
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        name TEXT NOT NULL,
        avatar_url TEXT,
        about TEXT,
        emp_id TEXT,
        role TEXT,
        location TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_users_name ON users(name)');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        is_group INTEGER NOT NULL,
        title TEXT,
        avatar_url TEXT,
        created_at INTEGER NOT NULL,
        last_body TEXT,
        last_at INTEGER,
        last_sender TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_chats_last_at ON chats(last_at DESC)');

    await db.execute('''
      CREATE TABLE chat_members (
        chat_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        PRIMARY KEY (chat_id, user_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_chat_members_chat ON chat_members(chat_id)');
    await db.execute('CREATE INDEX idx_chat_members_user ON chat_members(user_id)');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        body TEXT,
        kind TEXT NOT NULL,
        reply_to TEXT,
        created_at INTEGER NOT NULL,
        edited_at INTEGER,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_messages_chat_created ON messages(chat_id, created_at ASC)');
  }

  Future<Database?> _ensure() async {
    if (kIsWeb || _disabled) return null;
    if (_db == null) await init();
    return _db;
  }

  // ---------- Users ----------

  Future<void> upsertUsers(List<AppUser> users) async {
    final db = await _ensure();
    if (db == null || users.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final u in users) {
      batch.insert(
        'users',
        {
          'id': u.id,
          'phone': u.phone,
          'name': u.name,
          'avatar_url': u.avatarUrl,
          'about': u.about,
          'emp_id': u.empId,
          'role': u.role,
          'location': u.location,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AppUser>> allUsers() async {
    final db = await _ensure();
    if (db == null) return const [];
    final rows = await db.query('users', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(_userFromRow).toList();
  }

  AppUser _userFromRow(Map<String, Object?> r) => AppUser(
        id: r['id'] as String,
        phone: r['phone'] as String,
        name: r['name'] as String,
        avatarUrl: r['avatar_url'] as String?,
        about: r['about'] as String?,
        empId: r['emp_id'] as String?,
        role: r['role'] as String?,
        location: r['location'] as String?,
      );

  // ---------- Chats ----------

  Future<void> upsertChats(List<Chat> chats) async {
    final db = await _ensure();
    if (db == null || chats.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final c in chats) {
      batch.insert(
        'chats',
        {
          'id': c.id,
          'is_group': c.isGroup ? 1 : 0,
          'title': c.title,
          'avatar_url': c.avatarUrl,
          'created_at': c.createdAt.millisecondsSinceEpoch,
          'last_body': c.lastMessageBody,
          'last_at': c.lastMessageAt?.millisecondsSinceEpoch,
          'last_sender': c.lastMessageSenderId,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Reset members for this chat and re-insert.
      batch.delete('chat_members', where: 'chat_id = ?', whereArgs: [c.id]);
      for (final m in c.members) {
        batch.insert(
          'chat_members',
          {'chat_id': c.id, 'user_id': m.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Also upsert the member as a user so we have their profile cached.
        batch.insert(
          'users',
          {
            'id': m.id,
            'phone': m.phone,
            'name': m.name,
            'avatar_url': m.avatarUrl,
            'about': m.about,
            'emp_id': m.empId,
            'role': m.role,
            'location': m.location,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  /// Returns chats that include [selfId] as a member, newest activity first.
  Future<List<Chat>> allChats(String selfId) async {
    final db = await _ensure();
    if (db == null) return const [];
    final chatRows = await db.rawQuery('''
      SELECT c.* FROM chats c
      JOIN chat_members cm ON cm.chat_id = c.id
      WHERE cm.user_id = ?
      ORDER BY (CASE WHEN c.last_at IS NULL THEN 0 ELSE c.last_at END) DESC,
               c.created_at DESC
    ''', [selfId]);
    if (chatRows.isEmpty) return const [];

    final chatIds = chatRows.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(chatIds.length, '?').join(',');
    final memberRows = await db.rawQuery('''
      SELECT cm.chat_id, u.*
      FROM chat_members cm
      JOIN users u ON u.id = cm.user_id
      WHERE cm.chat_id IN ($placeholders)
    ''', chatIds);

    final byChat = <String, List<AppUser>>{};
    for (final mr in memberRows) {
      final cid = mr['chat_id'] as String;
      byChat.putIfAbsent(cid, () => []).add(_userFromRow(mr));
    }

    return chatRows.map((r) {
      final id = r['id'] as String;
      return Chat(
        id: id,
        isGroup: (r['is_group'] as int) == 1,
        title: r['title'] as String?,
        avatarUrl: r['avatar_url'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        members: byChat[id] ?? const [],
        lastMessageBody: r['last_body'] as String?,
        lastMessageAt: r['last_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['last_at'] as int),
        lastMessageSenderId: r['last_sender'] as String?,
      );
    }).toList();
  }

  // ---------- Messages ----------

  Future<void> upsertMessages(List<Message> messages) async {
    final db = await _ensure();
    if (db == null || messages.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final m in messages) {
      batch.insert(
        'messages',
        {
          'id': m.id,
          'chat_id': m.chatId,
          'sender_id': m.senderId,
          'body': m.body,
          'kind': m.kind,
          'reply_to': m.replyTo,
          'created_at': m.createdAt.millisecondsSinceEpoch,
          'edited_at': m.editedAt?.millisecondsSinceEpoch,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Message>> messagesFor(String chatId, {int limit = 200}) async {
    final db = await _ensure();
    if (db == null) return const [];
    final rows = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map((r) => Message(
          id: r['id'] as String,
          chatId: r['chat_id'] as String,
          senderId: r['sender_id'] as String,
          body: r['body'] as String?,
          kind: r['kind'] as String,
          replyTo: r['reply_to'] as String?,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          editedAt: r['edited_at'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(r['edited_at'] as int),
        )).toList();
  }

  // ---------- Lifecycle ----------

  Future<void> clear() async {
    final db = await _ensure();
    if (db == null) return;
    final batch = db.batch();
    batch.delete('messages');
    batch.delete('chat_members');
    batch.delete('chats');
    batch.delete('users');
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _initFuture = null;
  }
}
