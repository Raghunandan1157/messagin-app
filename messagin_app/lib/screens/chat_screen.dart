import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/reaction.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/reaction_picker.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  Map<String, List<Reaction>> _reactionsByMsg = {};
  bool _loading = true;
  bool _sending = false;
  bool _showEmojiPanel = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollNew());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    final msgs = await repo.listMessages(widget.chat.id);
    final reactions = await repo.reactionsForChat(widget.chat.id);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _reactionsByMsg = _groupReactions(reactions);
      _loading = false;
    });
    _scrollToBottom();
  }

  Map<String, List<Reaction>> _groupReactions(List<Reaction> rs) {
    final map = <String, List<Reaction>>{};
    for (final r in rs) {
      map.putIfAbsent(r.messageId, () => []).add(r);
    }
    return map;
  }

  Future<void> _pollNew() async {
    final repo = context.read<AppState>().repo;
    try {
      if (_messages.isNotEmpty) {
        final since = _messages.last.createdAt.subtract(const Duration(seconds: 1));
        final fresh = await repo.messagesSince(widget.chat.id, since);
        final seen = _messages.map((m) => m.id).toSet();
        final novel = fresh.where((m) => !seen.contains(m.id)).toList();
        if (novel.isNotEmpty && mounted) {
          setState(() => _messages.addAll(novel));
          _scrollToBottom();
        }
      }
      final reactions = await repo.reactionsForChat(widget.chat.id);
      if (mounted) setState(() => _reactionsByMsg = _groupReactions(reactions));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final state = context.read<AppState>();
    try {
      final m = await state.repo.sendMessage(widget.chat.id, state.me!.id, text);
      _input.clear();
      if (!mounted) return;
      setState(() => _messages.add(m));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onLongPress(Message m, Offset pos) async {
    final picked = await showReactionPicker(context, pos);
    if (picked == null) return;
    String? emoji = picked;
    if (emoji == '+') {
      if (!mounted) return;
      emoji = await showFullEmojiSheet(context);
      if (emoji == null) return;
    }
    if (!mounted) return;
    final state = context.read<AppState>();
    await state.repo.toggleReaction(m.id, state.me!.id, emoji);
    await _pollNew();
  }

  void _insertEmoji(String emoji) {
    final sel = _input.selection;
    final text = _input.text;
    if (sel.isValid) {
      final newText = text.replaceRange(sel.start, sel.end, emoji);
      _input.text = newText;
      _input.selection = TextSelection.collapsed(offset: sel.start + emoji.length);
    } else {
      _input.text = text + emoji;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    final memberById = {for (final m in widget.chat.members) m.id: m};
    return Scaffold(
      backgroundColor: LoopColors.chatBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          LoopAvatar(initials: widget.chat.displayInitials(me.id), size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.displayTitle(me.id),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  widget.chat.isGroup
                      ? '${widget.chat.members.length} members'
                      : 'online',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ]),
      ),
      body: PopScope(
        canPop: !_showEmojiPanel,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _showEmojiPanel) {
            setState(() => _showEmojiPanel = false);
          }
        },
        child: Column(children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6C8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Messages are end-to-end encrypted.\nSay hi to start.',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final isMine = m.senderId == me.id;
                          final prev = i > 0 ? _messages[i - 1] : null;
                          final showName = widget.chat.isGroup && !isMine && prev?.senderId != m.senderId;
                          final rs = _reactionsByMsg[m.id] ?? const [];
                          return MessageBubble(
                            message: m,
                            isMine: isMine,
                            showSenderName: showName,
                            senderName: memberById[m.senderId]?.name,
                            reactions: rs,
                            onLongPress: (pos) => _onLongPress(m, pos),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(children: [
                Expanded(
                  child: Material(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        InkWell(
                          onTap: () => setState(() => _showEmojiPanel = !_showEmojiPanel),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 5,
                            onTap: () {
                              if (_showEmojiPanel) setState(() => _showEmojiPanel = false);
                            },
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: LoopColors.brand,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _send,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          if (_showEmojiPanel) _EmojiPanel(onTap: _insertEmoji),
        ]),
      ),
    );
  }
}

class _EmojiPanel extends StatelessWidget {
  final void Function(String) onTap;
  const _EmojiPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      color: const Color(0xFFF2F2F2),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: fullEmojiSet.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemBuilder: (_, i) => InkWell(
          onTap: () => onTap(fullEmojiSet[i]),
          child: Center(child: Text(fullEmojiSet[i], style: const TextStyle(fontSize: 24))),
        ),
      ),
    );
  }
}
