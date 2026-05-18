import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'profile_setup_screen.dart';

const _bgLight = Color(0xFFFAFAF7);
const _ink = Color(0xFF0A1310);
const _inkMuted = Color(0xFF5C6660);
const _border = Color(0xFFD8D6D0);

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
  late final AnimationController _successAnim;
  late final AnimationController _errorPulse;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _errorPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    for (final n in _nodes) {
      n.addListener(() => setState(() {}));
    }
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
    _successAnim.dispose();
    _errorPulse.dispose();
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
        _errorPulse.forward(from: 0);
        HapticFeedback.mediumImpact();
        setState(() {
          _err = 'That code did not match. Try again.';
          _verifying = false;
        });
        for (final c in _ctrls) {
          c.clear();
        }
        _nodes[0].requestFocus();
        return;
      }
      HapticFeedback.selectionClick();
      setState(() => _success = true);
      _successAnim.forward();
      await Future<void>.delayed(const Duration(milliseconds: 850));

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
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, anim, _) => ProfileSetupScreen(phone: widget.phone),
            transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
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
    return AnimatedBuilder(
      animation: _errorPulse,
      builder: (_, _) {
        final errFlash = _errorPulse.value;
        final borderColor = _err != null
            ? Color.lerp(_border, const Color(0xFFB42318), errFlash)!
            : _success
                ? WAColors.brand
                : focused
                    ? WAColors.brandDark
                    : filled
                        ? _ink
                        : _border;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 62,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: focused || filled ? 1.6 : 1),
            boxShadow: focused
                ? [BoxShadow(color: WAColors.brand.withValues(alpha: 0.10), blurRadius: 12, spreadRadius: 1)]
                : null,
          ),
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            showCursor: false,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: _ink),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) {
              setState(() {});
              if (v.isNotEmpty) HapticFeedback.selectionClick();
              if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
              if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
              if (_code.length == 4) _verify();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back, color: _ink),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: _success ? _successView() : _entryView(),
                ),
                const Spacer(),
                if (!_success)
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Resend code', style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                        ),
                        Container(width: 1, height: 14, color: _border),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Call instead', style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _successView() {
    return Column(
      key: const ValueKey('s'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: CurvedAnimation(parent: _successAnim, curve: Curves.easeOutBack),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WAColors.brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: WAColors.brand.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_rounded, color: WAColors.brandDark, size: 28),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Verified.',
          style: TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Loading your workspace...',
          style: TextStyle(color: _inkMuted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _entryView() {
    return Column(
      key: const ValueKey('e'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify your number',
          style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'A 4-digit code was sent to '),
            TextSpan(text: widget.phone, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
            const TextSpan(text: '.'),
          ]),
          style: const TextStyle(color: _inkMuted, fontSize: 14.5, height: 1.5),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, _digitBox),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _verifying
              ? Row(key: const ValueKey('v'), children: const [
                  SizedBox(
                    width: 13, height: 13,
                    child: CircularProgressIndicator(strokeWidth: 1.6, color: WAColors.brandDark),
                  ),
                  SizedBox(width: 8),
                  Text('Verifying', style: TextStyle(color: _inkMuted, fontSize: 13)),
                ])
              : _err != null
                  ? Row(key: const ValueKey('er'), children: [
                      const Icon(Icons.error_outline, size: 14, color: Color(0xFFB42318)),
                      const SizedBox(width: 6),
                      Text(_err!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12.5)),
                    ])
                  : const SizedBox(key: ValueKey('n'), height: 14),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9D88E)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF7A5E00)),
            const SizedBox(width: 6),
            Text('Demo: use code 1234',
                style: TextStyle(color: const Color(0xFF7A5E00).withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ],
    );
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
