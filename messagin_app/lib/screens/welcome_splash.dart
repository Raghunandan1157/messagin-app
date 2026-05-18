import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

class WelcomeSplash extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomeSplash({super.key, required this.onDone});

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> with TickerProviderStateMixin {
  late final AnimationController _avatar;
  late final AnimationController _text;

  @override
  void initState() {
    super.initState();
    _avatar = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _text = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _text.forward();
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _avatar.dispose();
    _text.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Hey night owl';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  String _firstName(String full) {
    final t = full.trim();
    if (t.isEmpty) return 'there';
    return t.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    if (me == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }
    final contacts = state.contacts;
    final sameRole = me.role == null
        ? 0
        : contacts.where((u) => u.role == me.role).length;
    final sameLoc = me.location == null
        ? 0
        : contacts.where((u) => u.location == me.location).length;
    final locations = contacts.map((u) => u.location).whereType<String>().toSet().length;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WAColors.brandDark, WAColors.brand, Color(0xFF06CF9C)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            // soft circles bg
            Positioned(
              top: -80,
              right: -60,
              child: _circle(220, Colors.white.withValues(alpha: 0.06)),
            ),
            Positioned(
              bottom: -100,
              left: -40,
              child: _circle(260, Colors.white.withValues(alpha: 0.05)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _avatar, curve: Curves.elasticOut),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
                      ),
                      child: LoopAvatar(initials: me.initials, size: 120),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _text,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _text, curve: Curves.easeOut)),
                      child: Column(children: [
                        Text('${_greeting()},',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            )),
                        const SizedBox(height: 6),
                        Text(
                          _firstName(me.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (me.role != null || me.location != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              me.tagline,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (me.empId != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            me.empId!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (contacts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _statBlock(contacts.length.toString(), 'colleagues'),
                                _statDivider(),
                                _statBlock(locations.toString(), 'locations'),
                                if (me.role != null) ...[
                                  _statDivider(),
                                  _statBlock(sameRole.toString(), 'same role'),
                                ],
                                if (me.location != null && me.role == null) ...[
                                  _statDivider(),
                                  _statBlock(sameLoc.toString(), 'in ${me.location}'),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Text(
                            'End-to-end encrypted',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: FadeTransition(
                opacity: _text,
                child: Center(
                  child: TextButton(
                    onPressed: widget.onDone,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Continue →', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _statBlock(String value, String label) {
    final n = int.tryParse(value) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: n.toDouble()),
          builder: (_, v, __) => Text(
            v.toInt().toString(),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

