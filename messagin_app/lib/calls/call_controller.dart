import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling.dart';

enum CallState { idle, dialing, ringing, connecting, active, ended }

/// 1:1 call orchestrator on top of the NAVA-style room signaling protocol.
///
/// Wire-level: each chat becomes a room (`roomId = chatId`). When two clients
/// `join` the same room, the *second* joiner (per NAVA contract) creates an
/// offer to every existing peer. For 1:1 that's exactly one offer. The first
/// joiner waits and answers.
///
/// In our app:
/// - The caller taps the call button → CallController.start(chatId, peerUserId)
///   → joins the room. CallState = dialing. Waits for `peer-joined`.
/// - The callee (in a future invite flow, or by tapping the call button on
///   the same chat) → CallController.accept() or start() → joins the same
///   room. CallState transitions through connecting → active.
///
/// NOTE: The signaling server (per task #6) does NOT carry a higher-level
/// "invite" event — joining a room IS the call action. A ring UI for the
/// receiver therefore needs an app-layer notification (chat message, push,
/// or a small server extension). That's tracked as a follow-up; today the
/// CallController is ready to handle a manual accept once that channel
/// exists.
class CallController extends ChangeNotifier {
  final SignalingClient signaling;

  /// The signed-in user's id. Carried in `join` so the remote side can
  /// resolve `targetPeerId` ↔ `userId` from `peer-joined`/`room-joined`.
  final String selfUserId;

  CallController({required this.signaling, required this.selfUserId}) {
    _sigSub = signaling.messages.listen(_onSignal);
  }

  CallState state = CallState.idle;
  String? peerUserId;
  String? peerPeerId; // server-assigned id of the remote peer
  String? chatId; // == roomId
  bool isVideo = false;
  bool micEnabled = true;
  bool camEnabled = true;
  bool speakerOn = true;
  bool isFrontCamera = true;
  String? errorMessage;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription? _sigSub;

  // Buffer ICE candidates that arrive before setRemoteDescription is called
  // (mirrors NAVA's flushIceCandidates pattern).
  final List<Map<String, dynamic>> _pendingIce = [];
  bool _remoteSet = false;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get incomingFromUserId => peerUserId;
  bool get incomingVideo => isVideo;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<void> _onSignal(SignalMessage m) async {
    switch (m.type) {
      case 'welcome':
        // self peerId now stamped on signaling.selfPeerId; nothing to do here.
        break;
      case 'room-joined':
        // We just joined. If there are existing peers, we are the newcomer
        // and per NAVA we create offers to them. For 1:1 only one peer.
        await _ensurePeerConnection();
        for (final p in m.peers) {
          // Match by userId if the existing peer registered one; else accept
          // the only peer present.
          if (peerUserId != null &&
              p.userId != null &&
              p.userId != peerUserId) {
            continue;
          }
          peerPeerId = p.peerId;
          peerUserId ??= p.userId;
          await _createAndSendOffer();
          state = CallState.connecting;
          notifyListeners();
        }
        break;
      case 'peer-joined':
        // Another peer joined. If we were the first joiner, this is the
        // callee. Per NAVA the *newcomer* offers, so we just record their id
        // and wait for their offer.
        if (peerUserId == null || peerUserId == m.userId) {
          peerPeerId = m.peerId;
          peerUserId ??= m.userId;
          // Stay in dialing until we receive offer or active.
        }
        notifyListeners();
        break;
      case 'offer':
        await _ensurePeerConnection();
        peerPeerId = m.peerId;
        if (m.offer != null) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(
              m.offer!['sdp'] as String?,
              m.offer!['type'] as String?,
            ),
          );
          _remoteSet = true;
          await _flushPendingIce();
          final answer = await _pc!.createAnswer({
            'offerToReceiveAudio': true,
            'offerToReceiveVideo': isVideo,
          });
          await _pc!.setLocalDescription(answer);
          signaling.sendAnswer(peerPeerId!, {
            'sdp': answer.sdp,
            'type': answer.type,
          });
          state = CallState.connecting;
          notifyListeners();
        }
        break;
      case 'answer':
        if (_pc != null && m.answer != null) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(
              m.answer!['sdp'] as String?,
              m.answer!['type'] as String?,
            ),
          );
          _remoteSet = true;
          await _flushPendingIce();
          state = CallState.connecting;
          notifyListeners();
        }
        break;
      case 'ice-candidate':
        final cand = m.candidate;
        if (cand == null) break;
        if (_pc != null && _remoteSet) {
          await _pc!.addCandidate(
            RTCIceCandidate(
              cand['candidate'] as String?,
              cand['sdpMid'] as String?,
              cand['sdpMLineIndex'] as int?,
            ),
          );
        } else {
          _pendingIce.add(cand);
        }
        break;
      case 'peer-left':
        if (m.peerId == peerPeerId) {
          await end(notifyRemote: false);
        }
        break;
      case 'error':
        errorMessage = 'Signal error: ${m.errorMessage}';
        debugPrint(errorMessage);
        notifyListeners();
        break;
    }
  }

  Future<void> _flushPendingIce() async {
    if (_pc == null) return;
    for (final cand in _pendingIce) {
      try {
        await _pc!.addCandidate(
          RTCIceCandidate(
            cand['candidate'] as String?,
            cand['sdpMid'] as String?,
            cand['sdpMLineIndex'] as int?,
          ),
        );
      } catch (e) {
        debugPrint('flushIce failed: $e');
      }
    }
    _pendingIce.clear();
  }

  Future<void> _ensurePeerConnection() async {
    if (_pc != null) return;
    _pc = await createPeerConnection(_iceServers, {});
    _pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      final target = peerPeerId;
      if (target == null) return;
      signaling.sendIceCandidate(target, {
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      });
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        notifyListeners();
      }
    };
    _pc!.onConnectionState = (s) {
      debugPrint('pc state: $s');
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        state = CallState.active;
        notifyListeners();
      } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        end(notifyRemote: false);
      }
    };

    // Acquire local media now so tracks are present before we offer/answer.
    if (_localStream == null) {
      final constraints = <String, dynamic>{
        'audio': true,
        'video': isVideo ? {'facingMode': 'user'} : false,
      };
      try {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        for (final t in _localStream!.getTracks()) {
          await _pc!.addTrack(t, _localStream!);
        }
      } catch (e) {
        errorMessage = 'Mic/cam access denied or unavailable: $e';
        debugPrint(errorMessage);
        notifyListeners();
      }
    } else {
      for (final t in _localStream!.getTracks()) {
        await _pc!.addTrack(t, _localStream!);
      }
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_pc == null || peerPeerId == null) return;
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);
    signaling.sendOffer(peerPeerId!, {'sdp': offer.sdp, 'type': offer.type});
  }

  /// Mark this controller as having an incoming invite from [callerUserId]
  /// for chat [chatId]. Driven by the app-level CallInviteWatcher (which polls
  /// Neon for `call_invite` control messages). After this, the navigator
  /// observer in main.dart pushes IncomingCallScreen.
  void setIncoming({
    required String chatId,
    required String callerUserId,
    required bool video,
  }) {
    // Don't preempt an active call with an unrelated ring.
    if (state != CallState.idle && state != CallState.ended) return;
    this.chatId = chatId;
    peerUserId = callerUserId;
    isVideo = video;
    state = CallState.ringing;
    notifyListeners();
  }

  /// Start (or accept) a 1:1 call by joining the room `chatId`. The first
  /// joiner waits; the second joiner offers (per NAVA contract).
  Future<bool> start({
    required String chatId,
    required String peerUserId,
    bool video = false,
  }) async {
    if (state != CallState.idle && state != CallState.ended) return false;
    if (!signaling.connected.value) {
      await signaling.connect();
    }
    if (!signaling.connected.value) {
      errorMessage = 'Call relay unavailable. Try again shortly.';
      notifyListeners();
      return false;
    }
    this.chatId = chatId;
    this.peerUserId = peerUserId;
    isVideo = video;
    state = CallState.dialing;
    errorMessage = null;
    notifyListeners();

    // Acquire media up-front so PiP renders even while waiting.
    await _ensurePeerConnection();
    signaling.joinRoom(chatId);
    return true;
  }

  /// Accept a pending incoming call (only meaningful once an app-level invite
  /// channel feeds CallController into [CallState.ringing]). For now this
  /// behaves the same as start(), joining the room.
  Future<void> accept() async {
    if (state != CallState.ringing) return;
    final id = chatId;
    if (id == null) return;
    if (!signaling.connected.value) {
      await signaling.connect();
    }
    if (!signaling.connected.value) {
      errorMessage = 'Call relay unavailable. Try again shortly.';
      notifyListeners();
      return;
    }
    state = CallState.connecting;
    notifyListeners();
    await _ensurePeerConnection();
    signaling.joinRoom(id);
  }

  Future<void> reject() async {
    // No invite to nack at the signaling layer (the server has no invite
    // concept). Just transition back to idle locally.
    chatId = null;
    peerUserId = null;
    peerPeerId = null;
    state = CallState.ended;
    notifyListeners();
    state = CallState.idle;
    notifyListeners();
  }

  Future<void> end({bool notifyRemote = true}) async {
    if (notifyRemote) {
      signaling.leaveRoom();
    }
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      for (final t in _localStream?.getTracks() ?? const []) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;
    _pendingIce.clear();
    _remoteSet = false;
    peerUserId = null;
    peerPeerId = null;
    chatId = null;
    isVideo = false;
    micEnabled = true;
    camEnabled = true;
    state = CallState.ended;
    notifyListeners();
    state = CallState.idle;
    notifyListeners();
  }

  void toggleMic() {
    final tracks = _localStream?.getAudioTracks() ?? const [];
    if (tracks.isEmpty) return;
    micEnabled = !micEnabled;
    for (final t in tracks) {
      t.enabled = micEnabled;
    }
    notifyListeners();
  }

  void toggleCam() {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    camEnabled = !camEnabled;
    for (final t in tracks) {
      t.enabled = camEnabled;
    }
    notifyListeners();
  }

  Future<void> switchCam() async {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    try {
      await Helper.switchCamera(tracks.first);
      isFrontCamera = !isFrontCamera;
      notifyListeners();
    } catch (e) {
      debugPrint('switchCamera failed: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    try {
      await Helper.setSpeakerphoneOn(speakerOn);
    } catch (e) {
      debugPrint('setSpeakerphoneOn failed: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sigSub?.cancel();
    _pc?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    super.dispose();
  }
}
