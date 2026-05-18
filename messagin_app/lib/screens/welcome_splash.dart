import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

const _bgLight = Color(0xFFFAFAF7);
const _ink = Color(0xFF0A1310);
const _inkMuted = Color(0xFF5C6660);
const _border = Color(0xFFD8D6D0);

class WelcomeSplash extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomeSplash({super.key, required this.onDone});

  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _bar;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _bar = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..forward();
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _bar.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Welcome back';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Welcome back';
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
    final sameRole = me.role == null ? 0 : contacts.where((u) => u.role == me.role).length;
    final locations = contacts.map((u) => u.location).whereType<String>().toSet().length;

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24),
              // Wordmark
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: WAColors.brandDark, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.all_inclusive, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('Messagin',
                    style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
              ]),
              const Spacer(),
              FadeTransition(
                opacity: _enter,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    LoopAvatar(initials: me.initials, size: 64),
                    const SizedBox(height: 20),
                    Text('${_greeting()},',
                        style: const TextStyle(color: _inkMuted, fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      _firstName(me.name),
                      style: const TextStyle(color: _ink, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.1),
                    ),
                    if (me.role != null || me.location != null) ...[
                      const SizedBox(height: 10),
                      Text(me.tagline,
                          style: const TextStyle(color: _inkMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                    if (me.empId != null) ...[
                      const SizedBox(height: 4),
                      Text(me.empId!,
                          style: const TextStyle(color: _inkMuted, fontSize: 12, letterSpacing: 1.2, fontFamily: 'monospace')),
                    ],
                    const SizedBox(height: 32),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 20),
                    if (contacts.isNotEmpty)
                      Row(
                        children: [
                          _stat(contacts.length, 'directory'),
                          _statDivider(),
                          _stat(locations, 'locations'),
                          if (me.role != null) ...[
                            _statDivider(),
                            _stat(sameRole, 'same role'),
                          ],
                        ],
                      )
                    else
                      const Text('Loading directory...',
                          style: TextStyle(color: _inkMuted, fontSize: 13)),
                  ]),
                ),
              ),
              const Spacer(),
              // Progress bar
              AnimatedBuilder(
                animation: _bar,
                builder: (_, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Preparing your workspace',
                        style: TextStyle(color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                    const Spacer(),
                    Text('${(_bar.value * 100).toInt()}%',
                        style: const TextStyle(
                          color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(3)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _bar.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: WAColors.brandDark,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              // Tap-to-skip Continue
              FadeTransition(
                opacity: _enter,
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onDone,
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Continue', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: _ink),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(int n, String label) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: n.toDouble()),
          builder: (_, v, _) => Text(
            v.toInt().toString(),
            style: const TextStyle(
              color: _ink, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: _inkMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6)),
      ]),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 38, color: _border, margin: const EdgeInsets.symmetric(horizontal: 12));
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _border.withValues(alpha: 0.55);
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
