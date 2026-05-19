import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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
          peers.add(RoomPeer(
            peerId: p['peerId'] as String? ?? '',
            userId: p['userId'] as String?,
          ));
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

  SignalingClient(this.userId);

  Stream<SignalMessage> get messages => _messages.stream;
  ValueListenable<bool> get connected => _connected;
  ValueListenable<String?> get selfPeerId => _selfPeerId;

  Future<String> _resolveUrl() async {
    // 1. Native: prefer the ngrok override file the signaling-server task writes.
    if (!kIsWeb) {
      try {
        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'];
        if (home != null) {
          final f = File('$home/.messagin-signal.json');
          if (await f.exists()) {
            final j = jsonDecode(await f.readAsString());
            final wss = (j is Map ? j['wss'] : null) as String?;
            if (wss != null && wss.isNotEmpty) return wss;
          }
        }
      } catch (e) {
        debugPrint('signal-url file read failed: $e');
      }
    }
    // 2. Web (or native fallback): ask the Vercel proxy. The `call` shortcut
    // publishes the latest ngrok WSS to /api/signal-url.
    try {
      final apiBase = dotenv.env['API_ENDPOINT']
              ?.replaceFirst(RegExp(r'/api/sql$'), '') ??
          '';
      if (apiBase.isNotEmpty) {
        final resp = await http
            .get(Uri.parse('$apiBase/api/signal-url'))
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final j = jsonDecode(resp.body) as Map<String, dynamic>;
          final wss = j['wss'] as String?;
          if (wss != null && wss.isNotEmpty) return wss;
        }
      }
    } catch (e) {
      debugPrint('signal-url remote fetch failed: $e');
    }
    // 3. Final fallback to env / localhost.
    final fromEnv = dotenv.env['SIGNAL_WSS_URL'];
    return fromEnv != null && fromEnv.isNotEmpty
        ? fromEnv
        : 'ws://localhost:8787';
  }

  Future<void> connect() async {
    if (_closed) return;
    final url = await _resolveUrl();
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
              final msg =
                  SignalMessage.fromJson(Map<String, dynamic>.from(decoded));
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
