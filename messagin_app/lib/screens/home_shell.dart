import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/skeletons.dart';
import 'ai_screen.dart';
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
  bool _polling = false;
  String? _err;
  Timer? _poll;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    // 10s (was 5s) + single-flight guard prevents pile-up on slow networks.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_polling) return; // single-flight: drop overlapping polls
    final state = context.read<AppState>();
    final me = state.me;
    if (me == null) return;
    _polling = true;
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
    } finally {
      _polling = false;
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
      final shell = wide ? _buildWide() : _buildNarrow();
      return Material(
        color: WAColors.sidebarLight,
        child: Column(children: [
          const _ServerDownBanner(),
          Expanded(child: shell),
        ]),
      );
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
      floatingActionButton: _AiFab(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiScreen()),
        ),
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
            _AiSidebarBtn(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiScreen()),
              ),
            ),
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
    if (_loading) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (_, i) => const ChatTileSkeleton(),
      );
    }
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

/// Slim banner shown at the very top of HomeShell when the signaling server
/// (calls backend) is unreachable. Tappable dismiss; reappears after 5 min if
/// still down (logic lives in AppState.showServerDownBanner).
class _ServerDownBanner extends StatelessWidget {
  const _ServerDownBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.showServerDownBanner) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFFFF3C4),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            const Icon(Icons.cloud_off, size: 18, color: Color(0xFF54656F)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Calls offline — server not running. '
                'Type `call` in terminal to start.',
                style: TextStyle(fontSize: 13, color: Color(0xFF54656F)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF54656F)),
              tooltip: 'Dismiss',
              onPressed: () => state.dismissServerDownBanner(),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
      ),
    );
  }
}

/// Brand-gradient FAB shown on the narrow home screen. Tapping opens AiScreen.
class _AiFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AiFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WAColors.brand, WAColors.brandDark],
            ),
            boxShadow: [
              BoxShadow(
                color: WAColors.brand.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// Compact gradient AI button for the sidebar header (used in wide layout
/// where there is no FAB).
class _AiSidebarBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AiSidebarBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: 'AI Assistant',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [WAColors.brand, WAColors.brandDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: WAColors.brand.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
