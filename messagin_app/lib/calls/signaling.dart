import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'signal_endpoint.dart';

/// Typed signaling message envelope. Matches the wire format implemented by
/// `server/signal.js` (the protocol perf-debugger built for task #6 — itself
/// adapted from the NAVA_DHARSHANA reference).
///
/// Server-assigned `peerId` (random 16-hex per connection) is the routing key;
/// `userId` is an app-level tag carried in `join` so peers can resolve who
/// each peerId represents.
class SignalMessage {
  final String type;

  /// On `welcome` / `room-joined`: our own peerId.
  /// On `peer-joined` / `peer-left` / forwarded offer/answer/ice-candidate:
  /// the originator's peerId.
  final String? peerId;
  final String? userId;
  final String? roomId;
  final List<RoomPeer> peers;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final Map<String, dynamic>? candidate;
  final String? errorMessage;
  final Map<String, dynamic> raw;

  SignalMessage({
    required this.type,
    required this.raw,
    this.peerId,
    this.userId,
    this.roomId,
    this.peers = const [],
    this.offer,
    this.answer,
    this.candidate,
    this.errorMessage,
  });

  factory SignalMessage.fromJson(Map<String, dynamic> j) {
    final rawPeers = j['peers'];
    final peers = <RoomPeer>[];
    if (rawPeers is List) {
      for (final p in rawPeers) {
        if (p is Map) {
          peers.add(
            RoomPeer(
              peerId: p['peerId'] as String? ?? '',
              userId: p['userId'] as String?,
            ),
          );
        }
      }
    }
    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;
    return SignalMessage(
      type: j['type'] as String? ?? 'unknown',
      peerId: j['peerId'] as String?,
      userId: j['userId'] as String?,
      roomId: j['roomId'] as String?,
      peers: peers,
      offer: asMap(j['offer']),
      answer: asMap(j['answer']),
      candidate: asMap(j['candidate']),
      errorMessage: j['message'] as String?,
      raw: j,
    );
  }
}

class RoomPeer {
  final String peerId;
  final String? userId;
  const RoomPeer({required this.peerId, this.userId});
}

/// WebSocket signaling client. Reconnects on drop with exponential backoff.
///
/// Wire format reference:
///   client → server: `{type:'join', roomId, userId}` | `{type:'leave'}`
///                    `{type:'offer'|'answer'|'ice-candidate', targetPeerId, ...}`
///   server → client: `welcome`, `room-joined`, `peer-joined`, `peer-left`,
///                    `left`, `offer`/`answer`/`ice-candidate` (stamped with
///                    originator `peerId`), `error`.
class SignalingClient {
  final String userId;
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  final _messages = StreamController<SignalMessage>.broadcast();
  final _connected = ValueNotifier<bool>(false);
  final _selfPeerId = ValueNotifier<String?>(null);

  bool _closed = false;
  int _retryAttempt = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeat;
  Future<void>? _connectFuture;

  SignalingClient(this.userId);

  Stream<SignalMessage> get messages => _messages.stream;
  ValueListenable<bool> get connected => _connected;
  ValueListenable<String?> get selfPeerId => _selfPeerId;

  Future<String?> _resolveUrl() async {
    // 1. Native: prefer the ngrok override file the signaling-server task writes.
    if (!kIsWeb) {
      final wss = await localOverrideWss();
      if (wss != null && wss.isNotEmpty) return wss;
    }
    // 2. Web (or native fallback): ask the Vercel proxy. Relative
    // API_ENDPOINT values like `/api/sql` resolve against the deployed origin.
    try {
      final wss = await publishedSignalWss();
      if (wss != null && wss.isNotEmpty) return wss;
    } catch (e) {
      debugPrint('signal-url remote fetch failed: $e');
    }
    // 3. Explicit env override, then native localhost fallback. Web should not
    // try localhost from HTTPS unless SIGNAL_WSS_URL deliberately says so.
    final fromEnv = configuredSignalWss();
    if (fromEnv != null) return fromEnv;
    return kIsWeb ? null : 'ws://localhost:8787';
  }

  Future<void> connect() async {
    if (_closed || _connected.value) return;
    final pending = _connectFuture;
    if (pending != null) return pending;
    _connectFuture = _connect();
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connect() async {
    if (_closed) return;
    final url = await _resolveUrl();
    if (url == null || url.isEmpty) {
      debugPrint('signal connect skipped: no signal URL available');
      _scheduleReconnect();
      return;
    }
    try {
      final uri = Uri.parse(url);
      _ch = WebSocketChannel.connect(uri);
      await _ch!.ready;
      _connected.value = true;
      _retryAttempt = 0;

      _sub = _ch!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            if (decoded is Map) {
              final msg = SignalMessage.fromJson(
                Map<String, dynamic>.from(decoded),
              );
              // Capture our server-assigned peerId from `welcome`.
              if (msg.type == 'welcome' && msg.peerId != null) {
                _selfPeerId.value = msg.peerId;
              }
              _messages.add(msg);
            }
          } catch (e) {
            debugPrint('signal decode failed: $e raw=$data');
          }
        },
        onError: (e) {
          debugPrint('signal stream error: $e');
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );

      // App-level heartbeat — the server has its own WS ping every 30s, this
      // is a no-op safeguard for sleepy NATs.
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) {
        // The server doesn't recognize `ping` as a JSON type; sending a
        // protocol-level WS pong/ping isn't accessible from web_socket_channel
        // directly, so we just rely on the server's heartbeat. Intentionally
        // empty.
      });
    } catch (e) {
      debugPrint('signal connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _connected.value = false;
    _selfPeerId.value = null;
    _heartbeat?.cancel();
    _sub?.cancel();
    _sub = null;
    if (_closed) return;
    _retryAttempt = (_retryAttempt + 1).clamp(0, 6);
    final backoffMs = 500 * (1 << (_retryAttempt - 1));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: backoffMs), connect);
  }

  void _send(Map<String, dynamic> msg) {
    final ch = _ch;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('signal send failed: $e');
    }
  }

  void joinRoom(String roomId) =>
      _send({'type': 'join', 'roomId': roomId, 'userId': userId});

  void leaveRoom() => _send({'type': 'leave'});

  // Chat-channel pub/sub (typing indicators). Separate from call rooms.
  void chatSubscribe(String chatId) =>
      _send({'type': 'chat-subscribe', 'chatId': chatId});

  void chatUnsubscribe(String chatId) =>
      _send({'type': 'chat-unsubscribe', 'chatId': chatId});

  void sendTyping(String chatId, bool isTyping) =>
      _send({'type': 'chat-typing', 'chatId': chatId, 'isTyping': isTyping});

  void sendOffer(String targetPeerId, Map<String, dynamic> offer) =>
      _send({'type': 'offer', 'targetPeerId': targetPeerId, 'offer': offer});

  void sendAnswer(String targetPeerId, Map<String, dynamic> answer) =>
      _send({'type': 'answer', 'targetPeerId': targetPeerId, 'answer': answer});

  void sendIceCandidate(String targetPeerId, Map<String, dynamic> candidate) =>
      _send({
        'type': 'ice-candidate',
        'targetPeerId': targetPeerId,
        'candidate': candidate,
      });

  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    await _sub?.cancel();
    await _ch?.sink.close();
    _ch = null;
    _connected.value = false;
    _selfPeerId.value = null;
    await _messages.close();
  }
}
