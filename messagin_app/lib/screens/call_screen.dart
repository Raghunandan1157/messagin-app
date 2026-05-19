import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../calls/call_controller.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

/// Full-screen in-call UI.
///
/// - Audio call: large avatar + name + state, bottom control bar.
/// - Video call: remote video full-bleed, local PiP top-right.
class CallScreen extends StatefulWidget {
  final String peerName;
  final String peerInitials;
  const CallScreen({
    super.key,
    required this.peerName,
    required this.peerInitials,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  CallController? _ctrl;
  MediaStream? _boundLocal;
  MediaStream? _boundRemote;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) setState(() {});
  }

  void _attachStreams(CallController c) {
    if (c.localStream != _boundLocal) {
      _localRenderer.srcObject = c.localStream;
      _boundLocal = c.localStream;
    }
    if (c.remoteStream != _boundRemote) {
      _remoteRenderer.srcObject = c.remoteStream;
      _boundRemote = c.remoteStream;
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onCtrl);
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _onCtrl() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null) return;
    _attachStreams(c);
    // Bounce out of call UI when controller returns to idle.
    if (c.state == CallState.idle) {
      Navigator.of(context).maybePop();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CallController>();
    if (_ctrl != ctrl) {
      _ctrl?.removeListener(_onCtrl);
      _ctrl = ctrl;
      ctrl.addListener(_onCtrl);
    }
    _attachStreams(ctrl);

    final isVideo = ctrl.isVideo;
    final stateLabel = switch (ctrl.state) {
      CallState.dialing => 'Calling…',
      CallState.ringing => 'Incoming…',
      CallState.connecting => 'Connecting…',
      CallState.active => 'In call',
      CallState.ended => 'Call ended',
      CallState.idle => '',
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: [
            // Remote feed (video) or avatar (audio).
            if (isVideo && ctrl.remoteStream != null)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoopAvatar(initials: widget.peerInitials, size: 140),
                    const SizedBox(height: 24),
                    Text(widget.peerName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 8),
                    Text(stateLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16)),
                    if (ctrl.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(ctrl.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),

            // Local PiP for video calls.
            if (isVideo && ctrl.localStream != null)
              Positioned(
                top: 16,
                right: 16,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black,
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: ctrl.isFrontCamera,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Top status bar (video calls — overlay over the feed).
            if (isVideo)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${widget.peerName} · $stateLabel',
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),

            // Bottom control bar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _ControlBar(
                isVideo: isVideo,
                micEnabled: ctrl.micEnabled,
                camEnabled: ctrl.camEnabled,
                speakerOn: ctrl.speakerOn,
                onMic: ctrl.toggleMic,
                onCam: isVideo ? ctrl.toggleCam : null,
                onSwitchCam: isVideo ? ctrl.switchCam : null,
                onSpeaker: ctrl.toggleSpeaker,
                onEnd: () => ctrl.end(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final bool isVideo;
  final bool micEnabled;
  final bool camEnabled;
  final bool speakerOn;
  final VoidCallback onMic;
  final VoidCallback? onCam;
  final VoidCallback? onSwitchCam;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;

  const _ControlBar({
    required this.isVideo,
    required this.micEnabled,
    required this.camEnabled,
    required this.speakerOn,
    required this.onMic,
    required this.onCam,
    required this.onSwitchCam,
    required this.onSpeaker,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(
            icon: micEnabled ? Icons.mic : Icons.mic_off,
            label: micEnabled ? 'Mute' : 'Unmute',
            onTap: onMic,
            background: micEnabled ? Colors.white24 : Colors.white,
            iconColor: micEnabled ? Colors.white : Colors.black,
          ),
          if (onCam != null) ...[
            const SizedBox(width: 12),
            _btn(
              icon: camEnabled ? Icons.videocam : Icons.videocam_off,
              label: camEnabled ? 'Hide' : 'Show',
              onTap: onCam!,
              background: camEnabled ? Colors.white24 : Colors.white,
              iconColor: camEnabled ? Colors.white : Colors.black,
            ),
          ],
          if (onSwitchCam != null) ...[
            const SizedBox(width: 12),
            _btn(
              icon: Icons.cameraswitch,
              label: 'Flip',
              onTap: onSwitchCam!,
              background: Colors.white24,
              iconColor: Colors.white,
            ),
          ],
          const SizedBox(width: 12),
          _btn(
            icon: speakerOn ? Icons.volume_up : Icons.volume_down,
            label: speakerOn ? 'Speaker' : 'Earpiece',
            onTap: onSpeaker,
            background: speakerOn ? Colors.white : Colors.white24,
            iconColor: speakerOn ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 18),
          _btn(
            icon: Icons.call_end,
            label: 'End',
            onTap: onEnd,
            background: WAColors.brand,
            iconColor: Colors.white,
            big: true,
          ),
        ]),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color background,
    required Color iconColor,
    bool big = false,
  }) {
    final size = big ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: big ? 30 : 24),
      ),
    );
  }
}
