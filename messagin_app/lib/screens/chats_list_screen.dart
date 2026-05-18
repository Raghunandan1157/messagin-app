import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../state/app_state.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Chat> _chats = [];
  bool _loading = true;
  String? _err;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final state = context.read<AppState>();
    final me = state.me;
    if (me == null) return;
    try {
      final chats = await state.repo.listChatsFor(me.id);
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _loading = false;
        _err = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagin'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (v == 'signout') {
                await context.read<AppState>().signOut();
              } else if (v == 'refresh') {
                _load();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'CALLS'),
            Tab(text: 'STATUS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildChats(me.id),
          const _PlaceholderTab(icon: Icons.call, label: 'No recent calls'),
          const _PlaceholderTab(icon: Icons.donut_large, label: 'Status updates coming soon'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
          _load();
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChats(String meId) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Can\'t reach Neon', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_err!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    if (_chats.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No chats yet'),
          const SizedBox(height: 4),
          Text('Tap the chat button to start one', style: TextStyle(color: Colors.grey.shade600)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _chats.length,
        separatorBuilder: (_, i) => Divider(height: 1, indent: 76, color: Colors.grey.shade200),
        itemBuilder: (_, i) => ChatTile(
          chat: _chats[i],
          selfUserId: meId,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: _chats[i])));
            _load();
          },
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }
}
