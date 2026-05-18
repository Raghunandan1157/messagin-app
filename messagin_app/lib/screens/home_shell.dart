import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'chat_pane.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  List<Chat> _chats = [];
  Chat? _selected;
  bool _loading = true;
  String? _err;
  Timer? _poll;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchCtrl.dispose();
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
        if (_selected != null) {
          _selected = chats.where((c) => c.id == _selected!.id).firstOrNull ?? _selected;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  List<Chat> get _filteredChats {
    final me = context.read<AppState>().me!;
    final q = _searchCtrl.text.trim().toLowerCase();
    Iterable<Chat> base = _chats;
    if (_filter == 'Unread') base = base.where((_) => false);
    if (_filter == 'Groups') base = base.where((c) => c.isGroup);
    if (q.isNotEmpty) {
      base = base.where((c) => c.displayTitle(me.id).toLowerCase().contains(q));
    }
    return base.toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth >= 900;
      if (wide) return _buildWide();
      return _buildNarrow();
    });
  }

  Widget _buildWide() {
    return Scaffold(
      backgroundColor: WAColors.panelLight,
      body: Stack(children: [
        Container(color: WAColors.brandDark, height: 130, width: double.infinity),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 420,
              child: _sidebar(),
            ),
            const VerticalDivider(width: 1, color: WAColors.divider),
            Expanded(
              child: _selected == null
                  ? const _EmptyChatPane()
                  : ChatPane(chat: _selected!, onBack: () => setState(() => _selected = null)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildNarrow() {
    return Scaffold(
      backgroundColor: WAColors.sidebarLight,
      body: _sidebar(narrow: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
          _load();
        },
        backgroundColor: WAColors.brand,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _sidebar({bool narrow = false}) {
    final me = context.watch<AppState>().me!;
    return Container(
      color: WAColors.sidebarLight,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header strip
        Container(
          height: 60,
          color: WAColors.panelLight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: LoopAvatar(initials: me.initials, size: 40),
            ),
            const Spacer(),
            _iconBtn(Icons.groups_2_outlined, 'Communities'),
            _iconBtn(Icons.donut_large_outlined, 'Status'),
            _iconBtn(Icons.chat_outlined, 'New chat', onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
              _load();
            }),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: WAColors.mutedLight),
              onSelected: (v) async {
                if (v == 'profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                } else if (v == 'refresh') {
                  _load();
                } else if (v == 'signout') {
                  await context.read<AppState>().signOut();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'profile', child: Text('Profile')),
                PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                PopupMenuItem(value: 'signout', child: Text('Log out')),
              ],
            ),
          ]),
        ),
        // Search row
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: WAColors.sidebarLight,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: WAColors.panelLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              const Icon(Icons.search, size: 18, color: WAColors.mutedLight),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    hintText: 'Search or start a new chat',
                    hintStyle: TextStyle(color: WAColors.mutedLight, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['All', 'Unread', 'Groups']
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: const Color(0xFFD9FDD3),
                        backgroundColor: WAColors.panelLight,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: _filter == f ? WAColors.brandDark : WAColors.inkLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1, color: WAColors.divider),
        Expanded(child: _chatListBody(narrow: narrow)),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, String tip, {VoidCallback? onTap}) {
    return IconButton(
      icon: Icon(icon, size: 22, color: WAColors.mutedLight),
      tooltip: tip,
      onPressed: onTap ?? () {},
    );
  }

  Widget _chatListBody({required bool narrow}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text("Can't reach Neon", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_err!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: WAColors.mutedLight)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    final me = context.watch<AppState>().me!;
    final list = _filteredChats;
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.forum_outlined, size: 48, color: WAColors.mutedLight),
          SizedBox(height: 8),
          Text('No chats yet', style: TextStyle(color: WAColors.mutedLight)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final c = list[i];
          final selected = !narrow && _selected?.id == c.id;
          return _ChatRow(
            chat: c,
            selfUserId: me.id,
            selected: selected,
            onTap: () {
              if (narrow) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: c))).then((_) => _load());
              } else {
                setState(() => _selected = c);
              }
            },
          );
        },
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final Chat chat;
  final String selfUserId;
  final VoidCallback onTap;
  final bool selected;
  const _ChatRow({required this.chat, required this.selfUserId, required this.onTap, required this.selected});

  String _time(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final local = t.toLocal();
    if (now.year == local.year && now.month == local.month && now.day == local.day) {
      final hh = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      return '$hh:${local.minute.toString().padLeft(2, '0')} $ampm';
    }
    final diff = now.difference(local).inDays;
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }
    return '${local.day}/${local.month}/${local.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMine = chat.lastMessageSenderId == selfUserId;
    final last = chat.lastMessageBody;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFFF0F2F5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          LoopAvatar(initials: chat.displayInitials(selfUserId), size: 49),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    chat.displayTitle(selfUserId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: WAColors.inkLight, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                Text(_time(chat.lastMessageAt),
                    style: const TextStyle(fontSize: 12, color: WAColors.mutedLight)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (isMine && last != null) ...[
                  const Icon(Icons.done_all, size: 16, color: WAColors.mutedLight),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    last ?? (chat.isGroup ? 'Group · ${chat.members.length} members' : 'Tap to chat'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: WAColors.mutedLight),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmptyChatPane extends StatelessWidget {
  const _EmptyChatPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.panelLight,
      child: Stack(children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(height: 6, color: WAColors.brand),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF7F7F7), Color(0xFFEAEAEA)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline, size: 80, color: Color(0xFFB3B3B3)),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Messagin app for Web',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: WAColors.inkLight)),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Send and receive messages without keeping your phone online.\nUse Messagin app on up to 4 linked devices and 1 phone at the same time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: WAColors.mutedLight, height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.lock, size: 14, color: WAColors.mutedLight),
                SizedBox(width: 6),
                Text('Your personal messages are end-to-end encrypted',
                    style: TextStyle(fontSize: 13, color: WAColors.mutedLight)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
