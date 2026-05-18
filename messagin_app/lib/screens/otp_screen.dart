import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'profile_setup_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String country;
  const OtpScreen({super.key, required this.phone, required this.country});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());
  bool _verifying = false;
  bool _success = false;
  String? _err;
  late final AnimationController _grad;
  late final AnimationController _successAnim;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _grad = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    WidgetsBinding.instance.addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _grad.dispose();
    _successAnim.dispose();
    _shake.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _err = null;
    });
    final state = context.read<AppState>();
    try {
      if (!state.verifyOtp(_code)) {
        _shake.forward(from: 0);
        HapticFeedback.heavyImpact();
        setState(() {
          _err = 'Wrong code. Try 1234.';
          _verifying = false;
        });
        for (final c in _ctrls) {
          c.clear();
        }
        _nodes[0].requestFocus();
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() => _success = true);
      _successAnim.forward();
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final existing = await state.lookupUserByPhone(widget.phone);
      if (existing != null) {
        await state.resumeExisting(existing);
      }
      if (!mounted) return;
      if (existing != null) {
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, anim, __) => ProfileSetupScreen(phone: widget.phone),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _err = e.toString();
        _verifying = false;
      });
    }
  }

  Widget _digitBox(int i) {
    final filled = _ctrls[i].text.isNotEmpty;
    final focused = _nodes[i].hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 60,
      height: 72,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _success
              ? const Color(0xFF06CF9C)
              : focused
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
          width: focused ? 2.5 : 1.5,
        ),
        boxShadow: filled
            ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
              ]
            : null,
      ),
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        showCursor: false,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: filled ? WAColors.brandDark : Colors.white,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
          if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
          if (_code.length == 4) _verify();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(children: [
          AnimatedBuilder(
            animation: _grad,
            builder: (_, __) {
              final t = _grad.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + t * 0.4, -1 + t * 0.3),
                    end: Alignment(1 - t * 0.3, 1 - t * 0.4),
                    colors: [
                      Color.lerp(const Color(0xFF064E3B), const Color(0xFF033D2C), t)!,
                      Color.lerp(WAColors.brandDark, const Color(0xFF0B7A5F), t)!,
                      Color.lerp(WAColors.brand, const Color(0xFF14A085), t)!,
                      Color.lerp(const Color(0xFF06CF9C), const Color(0xFF2DEFBC), t)!,
                    ],
                  ),
                ),
              );
            },
          ),
          // Blobs
          Positioned(top: -100, left: -60, child: _blob(280, Colors.white.withValues(alpha: 0.06))),
          Positioned(bottom: -80, right: -50, child: _blob(220, Colors.white.withValues(alpha: 0.07))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _success
                      ? Column(key: const ValueKey('s'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ScaleTransition(
                            scale: CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "You're in.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading your conversations...',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                          ),
                        ])
                      : Column(key: const ValueKey('e'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text(
                            'Almost there.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'We sent a 4-digit code to '),
                              TextSpan(
                                text: widget.phone,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: '. Enter it below.'),
                            ]),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (_, child) {
                              final dx = (_shake.value < 1 ? (_shake.value * 8 * (0.5 - (_shake.value % 0.2)).abs() * 4) : 0).toDouble();
                              return Transform.translate(offset: Offset(dx - 4, 0), child: child);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, _digitBox),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedOpacity(
                            opacity: _verifying ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Row(children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text('Verifying...',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                            ]),
                          ),
                          if (_err != null) ...[
                            const SizedBox(height: 4),
                            Text(_err!, style: const TextStyle(color: Color(0xFFFFC4C4), fontSize: 13)),
                          ],
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.bolt_outlined, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Demo mode · OTP is 1234',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                              ),
                            ]),
                          ),
                        ]),
                ),
                const Spacer(),
                if (!_success)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.9), size: 18),
                      label: Text('Resend SMS', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                    ),
                    Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.25)),
                    TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.phone_callback_outlined, color: Colors.white.withValues(alpha: 0.9), size: 18),
                      label: Text('Call me', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                    ),
                  ]),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _blob(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
