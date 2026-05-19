import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../calls/call_controller.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/reaction.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/skeletons.dart';
import 'call_screen.dart';

const _uuid = Uuid();

class ChatPane extends StatefulWidget {
  final Chat chat;
  final VoidCallback? onBack;
  final bool embedded;
  const ChatPane({
    super.key,
    required this.chat,
    this.onBack,
    this.embedded = true,
  });

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _listKey = GlobalKey<AnimatedListState>();
  List<Message> _messages = [];
  Map<String, List<Reaction>> _reactionsByMsg = {};
  bool _loading = true;
  bool _sending = false;
  bool _showEmojiPanel = false;
  bool _hasText = false;
  bool _polling = false;
  Timer? _poll;
  Timer? _presencePoll;
  AppUser? _livePeer;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollNew());
    _refreshPeerPresence();
    _presencePoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPeerPresence(),
    );
  }

  Future<void> _refreshPeerPresence() async {
    if (widget.chat.isGroup) return;
    final me = context.read<AppState>().me;
    if (me == null) return;
    final peer = widget.chat.members.firstWhere(
      (m) => m.id != me.id,
      orElse: () => widget.chat.members.first,
    );
    if (peer.id.isEmpty || peer.id == me.id) return;
    try {
      final fresh = await context.read<AppState>().repo.userById(peer.id);
      if (!mounted || fresh == null) return;
      setState(() => _livePeer = fresh);
    } catch (e) {
      debugPrint('peer presence refresh failed: $e');
    }
  }

  @override
  void didUpdateWidget(ChatPane old) {
    super.didUpdateWidget(old);
    if (old.chat.id != widget.chat.id) {
      _messages = [];
      _reactionsByMsg = {};
      _loading = true;
      _input.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _presencePoll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    try {
      final results = await Future.wait([
        repo.listMessages(widget.chat.id),
        repo.reactionsForChat(widget.chat.id),
      ]);
      if (!mounted) return;
      final loaded = results[0] as List<Message>;
      final reactions = _groupReactions(results[1] as List<Reaction>);

      if (loaded.isNotEmpty) {
        setState(() {
          _messages = [];
          _reactionsByMsg = reactions;
          _loading = false;
        });
        for (final m in loaded) {
          final isVisible = m.kind == 'text';
          if (isVisible) {
            await Future.delayed(const Duration(milliseconds: 30));
            if (!mounted) return;
          }
          setState(() => _messages.add(m));
          if (isVisible) {
            final visibleCount =
                _messages.where((x) => x.kind == 'text').length;
            _listKey.currentState?.insertItem(
              visibleCount,
              duration: const Duration(milliseconds: 350),
            );
          }
        }
      } else {
        setState(() {
          _messages = loaded;
          _reactionsByMsg = reactions;
          _loading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Map<String, List<Reaction>> _groupReactions(List<Reaction> rs) {
    final map = <String, List<Reaction>>{};
    for (final r in rs) {
      map.putIfAbsent(r.messageId, () => []).add(r);
    }
    return map;
  }

  Future<void> _pollNew() async {
    if (_polling) return;
    _polling = true;
    final repo = context.read<AppState>().repo;
    try {
      if (_messages.isNotEmpty) {
        final since = _messages.last.createdAt.subtract(
          const Duration(seconds: 1),
        );
        final fresh = await repo.messagesSince(widget.chat.id, since);
        final seen = _messages.map((m) => m.id).toSet();
        final novel = fresh.where((m) => !seen.contains(m.id)).toList();
        if (novel.isNotEmpty && mounted) {
          for (final m in novel) {
            final isVisible = m.kind == 'text';
            setState(() => _messages.add(m));
            if (isVisible) {
              final visibleCount =
                  _messages.where((x) => x.kind == 'text').length;
              _listKey.currentState?.insertItem(
                visibleCount,
                duration: const Duration(milliseconds: 350),
              );
            }
          }
          _scrollToBottom();
        }
      } else {
        await _load();
        return;
      }
      final reactions = await repo.reactionsForChat(widget.chat.id);
      if (mounted) setState(() => _reactionsByMsg = _groupReactions(reactions));
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final state = context.read<AppState>();
    final me = state.me!;

    final tempId = 'local-${_uuid.v4()}';
    final temp = Message(
      id: tempId,
      chatId: widget.chat.id,
      senderId: me.id,
      kind: 'text',
      body: text,
      createdAt: DateTime.now(),
    );
    _input.clear();
    setState(() {
      _messages.add(temp);
      _hasText = false;
      _sending = true;
    });
    final visibleCount = _messages.where((m) => m.kind == 'text').length;
    _listKey.currentState?.insertItem(
      visibleCount,
      duration: const Duration(milliseconds: 350),
    );
    _scrollToBottom();

    try {
      final m = await state.repo.sendMessage(widget.chat.id, me.id, text);
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((x) => x.id == tempId);
        if (i >= 0) {
          _messages[i] = m;
        } else {
          _messages.add(m);
          final newVisibleCount =
              _messages.where((x) => x.kind == 'text').length;
          _listKey.currentState?.insertItem(
            newVisibleCount,
            duration: const Duration(milliseconds: 350),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      final visible = _messages.where((m) => m.kind == 'text').toList();
      final removeIndex = visible.indexWhere((x) => x.id == tempId);
      if (removeIndex >= 0) {
        _listKey.currentState?.removeItem(
          removeIndex + 1,
          (context, animation) => _buildRemoveAnimation(
            _buildRemovedMessage(context, temp, me),
            animation,
            true,
          ),
          duration: const Duration(milliseconds: 250),
        );
      }
      setState(() => _messages.removeWhere((x) => x.id == tempId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startCall({required bool video}) async {
    final state = context.read<AppState>();
    final me = state.me!;
    final peer = widget.chat.members.firstWhere(
      (m) => m.id != me.id,
      orElse: () => AppUser(id: '', phone: '', name: 'Unknown'),
    );
    if (peer.id.isEmpty) return;
    CallController? ctrl;
    try {
      ctrl = context.read<CallController>();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calls unavailable — signaling not ready.'),
        ),
      );
      return;
    }

    final started = await ctrl.start(
      chatId: widget.chat.id,
      peerUserId: peer.id,
      video: video,
    );
    if (!mounted) return;
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.errorMessage ?? 'Calls unavailable right now.'),
        ),
      );
      return;
    }

    final inviteExpiry = DateTime.now()
        .toUtc()
        .add(const Duration(seconds: 45))
        .toIso8601String();
    final inviteBody = jsonEncode({'video': video, 'expires_at': inviteExpiry});
    try {
      await state.repo.sendControlMessage(
        widget.chat.id,
        me.id,
        'call_invite',
        inviteBody,
      );
    } catch (e) {
      debugPrint('call_invite write failed: $e');
    }
    if (!mounted) return;

    final callId = widget.chat.id;
    final repo = state.repo;
    final selfId = me.id;
    final localCtrl = ctrl;
    Timer(const Duration(seconds: 45), () {
      if (localCtrl.state == CallState.active ||
          localCtrl.state == CallState.idle ||
          localCtrl.state == CallState.ended) {
        return;
      }
      repo
          .sendControlMessage(
            callId,
            selfId,
            'call_reject',
            jsonEncode({'reason': 'no_answer'}),
          )
          .catchError((e) {
            debugPrint('call_reject(no_answer) write failed: $e');
            return Message(
              id: '',
              chatId: callId,
              senderId: selfId,
              kind: 'call_reject',
              createdAt: DateTime.now(),
            );
          });
      localCtrl.end();
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<CallController>.value(
          value: ctrl!,
          child: CallScreen(peerName: peer.name, peerInitials: peer.initials),
        ),
      ),
    );
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
    if (sel.isValid && !sel.isCollapsed) {
      _input.text = text.replaceRange(sel.start, sel.end, emoji);
      _input.selection = TextSelection.collapsed(
        offset: sel.start + emoji.length,
      );
    } else if (sel.isValid) {
      _input.text = text.replaceRange(sel.start, sel.start, emoji);
      _input.selection = TextSelection.collapsed(
        offset: sel.start + emoji.length,
      );
    } else {
      _input.text = text + emoji;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
    setState(() => _hasText = _input.text.trim().isNotEmpty);
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final local = t.toLocal();
    final dayNow = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = dayNow.difference(day).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) {
      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return days[local.weekday - 1];
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  Widget _buildInsertAnimation(Widget child, Animation<double> animation) {
    final scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
    );
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOut),
    );
    final translateAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: fadeAnim.value,
          child: Transform.translate(
            offset: Offset(0, translateAnim.value),
            child: Transform.scale(
              scale: scaleAnim.value,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemoveAnimation(
      Widget child, Animation<double> animation, bool isMine) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeIn);
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: isMine ? const Offset(1.5, 0) : const Offset(-1.5, 0),
        ).animate(curved),
        child: child,
      ),
    );
  }

  Widget _buildRemovedMessage(BuildContext context, Message m, AppUser me) {
    final memberById = {
      for (final member in widget.chat.members) member.id: member
    };
    final isMine = m.senderId == me.id;
    final rs = _reactionsByMsg[m.id] ?? const [];
    return MessageBubble(
      message: m,
      isMine: isMine,
      showSenderName: false,
      senderName: memberById[m.senderId]?.name,
      reactions: rs,
      showTail: false,
      onLongPress: (_) {},
    );
  }

  String? _presenceText(AppUser peer) {
    final seen = peer.lastSeen;
    if (seen == null) return null;
    final now = DateTime.now();
    final diff = now.difference(seen);
    if (diff.inSeconds < 60) return 'online';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes} min ago';
    final local = seen.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final seenDay = DateTime(local.year, local.month, local.day);
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final ampm = h >= 12 ? 'PM' : 'AM';
    final timeStr = '$hh:$m $ampm';
    if (seenDay == today) return 'last seen today at $timeStr';
    if (seenDay == today.subtract(const Duration(days: 1))) {
      return 'last seen yesterday at $timeStr';
    }
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return 'last seen $d/$mo at $timeStr';
  }

  Widget _buildEncryptionBanner() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3C4),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 1,
            ),
          ],
        ),
        child: const Text(
          'Messages are end-to-end encrypted. No one outside of this chat, not even Messagin app, can read or listen to them.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF54656F),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    final memberById = {for (final m in widget.chat.members) m.id: m};
    final body = Column(
      children: [
        Container(
          height: 60,
          color: WAColors.panelLight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: WAColors.mutedLight,
                  ),
                  onPressed: widget.onBack,
                ),
              LoopAvatar(
                initials: widget.chat.displayInitials(me.id),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.chat.displayTitle(me.id),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: WAColors.inkLight,
                      ),
                    ),
                    Builder(builder: (_) {
                      final subtitle = widget.chat.isGroup
                          ? widget.chat.members
                                .map((m) => m.id == me.id ? 'You' : m.name)
                                .join(', ')
                          : _presenceText(
                              _livePeer ??
                                  widget.chat.members.firstWhere(
                                    (m) => m.id != me.id,
                                    orElse: () => widget.chat.members.first,
                                  ),
                            );
                      if (subtitle == null || subtitle.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: WAColors.mutedLight,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (!widget.chat.isGroup) ...[
                IconButton(
                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: WAColors.mutedLight,
                  ),
                  tooltip: 'Video call',
                  onPressed: () => _startCall(video: true),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.call_outlined,
                    color: WAColors.mutedLight,
                  ),
                  tooltip: 'Voice call',
                  onPressed: () => _startCall(video: false),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.search, color: WAColors.mutedLight),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: WAColors.mutedLight),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: WAColors.chatBgLight),
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 60,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (_, i) {
                      final mine = i.isOdd;
                      final widths = [220.0, 160.0, 260.0, 180.0, 200.0, 140.0];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: MessageBubbleSkeleton(
                          isMine: mine,
                          width: widths[i % widths.length],
                        ),
                      );
                    },
                  )
                : Builder(
                    builder: (_) {
                      final visible = _messages
                          .where((m) => m.kind == 'text')
                          .toList();
                      return AnimatedList(
                        key: _listKey,
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 60,
                        ),
                        initialItemCount: visible.length + 1,
                        itemBuilder: (context, i, animation) {
                          if (i == 0) {
                            return _buildEncryptionBanner();
                          }
                          final idx = i - 1;
                          final m = visible[idx];
                          final isMine = m.senderId == me.id;
                          final prev = idx > 0 ? visible[idx - 1] : null;
                          final showName =
                              widget.chat.isGroup &&
                              !isMine &&
                              prev?.senderId != m.senderId;
                          final showTail = prev?.senderId != m.senderId;
                          final showDate =
                              prev == null ||
                              _dateLabel(prev.createdAt) !=
                                  _dateLabel(m.createdAt);
                          final rs = _reactionsByMsg[m.id] ?? const [];
                          return _buildInsertAnimation(
                            Column(
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: WAColors.dateChipLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _dateLabel(m.createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF54656F),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) {
                                    final curved = CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOut,
                                    );
                                    return ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 1.02,
                                        end: 1.0,
                                      ).animate(curved),
                                      child: FadeTransition(
                                        opacity: curved,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: MessageBubble(
                                    key: ValueKey(m.id),
                                    message: m,
                                    isMine: isMine,
                                    showSenderName: showName,
                                    senderName: memberById[m.senderId]?.name,
                                    reactions: rs,
                                    showTail: showTail,
                                    onLongPress: (pos) => _onLongPress(m, pos),
                                  ),
                                ),
                              ],
                            ),
                            animation,
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
        Container(
          color: WAColors.panelLight,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  _showEmojiPanel
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                  color: WAColors.mutedLight,
                  size: 24,
                ),
                onPressed: () =>
                    setState(() => _showEmojiPanel = !_showEmojiPanel),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    onTap: () {
                      if (_showEmojiPanel) {
                        setState(() => _showEmojiPanel = false);
                      }
                    },
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: WAColors.mutedLight),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _hasText ? _send : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      final rotate = Tween<double>(
                        begin: 0.75,
                        end: 1.0,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );
                      return RotationTransition(
                        turns: rotate,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<bool>(_hasText),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hasText
                            ? WAColors.brandDark
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _hasText ? Icons.send : Icons.mic_none,
                        color: _hasText ? Colors.white : WAColors.brandDark,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showEmojiPanel) _EmojiPanel(onTap: _insertEmoji),
      ],
    );

    final faded = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey(widget.chat.id), child: body),
    );

    if (widget.embedded) {
      return Container(color: WAColors.chatBgLight, child: faded);
    }
    return Scaffold(body: faded);
  }
}

class _EmojiPanel extends StatelessWidget {
  final void Function(String) onTap;
  const _EmojiPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: WAColors.panelLight,
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        itemCount: fullEmojiSet.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (_, i) => InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onTap(fullEmojiSet[i]),
          child: Center(
            child: Text(fullEmojiSet[i], style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
