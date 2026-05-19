import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../db/repository.dart';
import 'call_controller.dart';

/// Polls Neon for `call_invite` / `call_reject` control messages and feeds
/// them into the live [CallController].
///
/// This bridges the gap between the WebSocket signaling server (which has no
/// invite/ring concept — joining a room IS the call) and the IncomingCallScreen
/// UX. The caller writes a control message in the chat; we poll for it on the
/// callee; on accept the callee joins the room and WebRTC negotiation completes.
///
/// Latency = poll interval (default 4s). Tighter when ringing is "live" would
/// reduce that; left as a follow-up.
class CallInviteWatcher {
  final Repository repo;
  final CallController controller;
  final String selfUserId;
  final Duration interval;
  final Duration inviteTtl;

  Timer? _timer;
  bool _polling = false;
  DateTime _lastSeen;
  final Set<String> _handledIds = {};

  CallInviteWatcher({
    required this.repo,
    required this.controller,
    required this.selfUserId,
    this.interval = const Duration(seconds: 4),
    this.inviteTtl = const Duration(seconds: 45),
  }) : _lastSeen = DateTime.now().toUtc().subtract(const Duration(seconds: 5));

  void start() {
    _timer?.cancel();
    // Tick once immediately so foregrounding gives an instant pickup.
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_polling) return;
    _polling = true;
    try {
      final fresh = await repo.recentCallControlMessages(selfUserId, _lastSeen);
      for (final m in fresh) {
        if (_handledIds.contains(m.id)) continue;
        _handledIds.add(m.id);

        // Bump the high-water mark so we never re-pull this row.
        if (m.createdAt.isAfter(_lastSeen)) _lastSeen = m.createdAt;

        switch (m.kind) {
          case 'call_invite':
            _onInvite(m.chatId, m.senderId, m.body, m.createdAt);
            break;
          case 'call_reject':
            _onReject(m.chatId, m.senderId);
            break;
        }
      }
      // Cap the handled-id set so it doesn't grow unbounded.
      if (_handledIds.length > 500) {
        // Drop the oldest entries by rebuilding from the trailing portion.
        final keep = _handledIds.toList().reversed.take(200).toSet();
        _handledIds
          ..clear()
          ..addAll(keep);
      }
    } catch (e) {
      debugPrint('CallInviteWatcher tick failed: $e');
    } finally {
      _polling = false;
    }
  }

  void _onInvite(String chatId, String callerId, String? body, DateTime createdAt) {
    // Discard stale invites that arrived after the caller already gave up.
    final age = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (age > inviteTtl) {
      debugPrint('call_invite stale (age=$age), ignoring');
      return;
    }
    var video = false;
    try {
      if (body != null && body.isNotEmpty) {
        final j = jsonDecode(body);
        if (j is Map && j['video'] is bool) video = j['video'] as bool;
      }
    } catch (_) {}
    controller.setIncoming(
      chatId: chatId,
      callerUserId: callerId,
      video: video,
    );
  }

  void _onReject(String chatId, String senderId) {
    // If the reject targets the current call we're dialing/ringing, tear it
    // down locally. Otherwise ignore.
    if (controller.chatId == chatId &&
        (controller.state == CallState.dialing ||
            controller.state == CallState.ringing ||
            controller.state == CallState.connecting)) {
      controller.end(notifyRemote: false);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
