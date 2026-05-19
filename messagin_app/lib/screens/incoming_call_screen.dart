import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../calls/call_controller.dart';
import '../models/user.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'call_screen.dart';

/// Full-screen incoming call ring UI. Pushed when CallController transitions
/// to [CallState.ringing] (the signaling layer received an `invite`).
class IncomingCallScreen extends StatefulWidget {
  final AppUser caller;
  const IncomingCallScreen({super.key, required this.caller});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  CallController? _ctrl;

  @override
  void dispose() {
    _ctrl?.removeListener(_onCtrl);
    super.dispose();
  }

  void _onCtrl() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null) return;
    // Once the user accepts, the controller leaves the `ringing` state.
    // Swap this screen for the in-call screen.
    if (c.state == CallState.connecting || c.state == CallState.active) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CallScreen(
          peerName: widget.caller.name,
          peerInitials: widget.caller.initials,
        ),
      ));
    } else if (c.state == CallState.idle || c.state == CallState.ended) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CallController>();
    if (_ctrl != ctrl) {
      _ctrl?.removeListener(_onCtrl);
      _ctrl = ctrl;
      ctrl.addListener(_onCtrl);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1414),
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 48),
            Text(
              ctrl.isVideo ? 'Incoming video call' : 'Incoming voice call',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            LoopAvatar(initials: widget.caller.initials, size: 140),
            const SizedBox(height: 24),
            Text(widget.caller.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 6),
            Text(widget.caller.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: () => ctrl.reject(),
                  ),
                  _circleBtn(
                    icon: ctrl.isVideo ? Icons.videocam : Icons.call,
                    color: WAColors.brand,
                    label: 'Accept',
                    onTap: () => ctrl.accept(),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }
}
