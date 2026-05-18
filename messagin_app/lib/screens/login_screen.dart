import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'otp_screen.dart';

class _Country {
  final String name;
  final String code;
  final String flag;
  const _Country(this.flag, this.name, this.code);
}

const _countries = <_Country>[
  _Country('🇮🇳', 'India', '+91'),
  _Country('🇺🇸', 'United States', '+1'),
  _Country('🇬🇧', 'United Kingdom', '+44'),
  _Country('🇦🇪', 'United Arab Emirates', '+971'),
  _Country('🇸🇬', 'Singapore', '+65'),
  _Country('🇩🇪', 'Germany', '+49'),
  _Country('🇫🇷', 'France', '+33'),
  _Country('🇯🇵', 'Japan', '+81'),
  _Country('🇦🇺', 'Australia', '+61'),
  _Country('🇨🇦', 'Canada', '+1'),
];

const _bgLight = Color(0xFFFAFAF7);
const _ink = Color(0xFF0A1310);
const _inkMuted = Color(0xFF5C6660);
const _border = Color(0xFFD8D6D0);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  _Country _country = _countries.first;
  final _phone = TextEditingController();
  final _focus = FocusNode();
  String? _err;
  late final AnimationController _enter;
  late final AnimationController _typePulse;
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _typePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _phone.addListener(_onTextChanged);
    _focus.addListener(() => setState(() {}));
  }

  void _onTextChanged() {
    final l = _phone.text.length;
    if (l != _lastLen) {
      _typePulse.forward(from: 0);
      if (l > _lastLen) HapticFeedback.selectionClick();
      _lastLen = l;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _enter.dispose();
    _typePulse.dispose();
    _phone.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: _bgLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Country', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _inkMuted, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _countries
                    .map((c) => InkWell(
                          onTap: () => Navigator.pop(context, c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(children: [
                              Text(c.flag, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 14),
                              Expanded(child: Text(c.name, style: const TextStyle(color: _ink, fontSize: 15))),
                              Text(c.code, style: const TextStyle(color: _inkMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ]),
        ),
      ),
    );
    if (picked != null) setState(() => _country = picked);
  }

  void _continue() {
    final digits = _phone.text.trim();
    if (digits.length < 6) {
      setState(() => _err = 'Enter a valid phone number');
      return;
    }
    final fullPhone = '${_country.code}$digits';
    setState(() => _err = null);
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, anim, _) => OtpScreen(phone: fullPhone, country: _country.name),
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _phone.text.trim().length >= 6;
    return Scaffold(
      backgroundColor: _bgLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Stack(children: [
          // Subtle dot grid backdrop
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 28),
                // wordmark
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: WAColors.brandDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.all_inclusive, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Messagin',
                    style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                  ),
                ]),
                const Spacer(),
                FadeTransition(
                  opacity: _enter,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text(
                        'Sign in',
                        style: TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter your work number to access the company directory and team conversations.',
                        style: const TextStyle(color: _inkMuted, fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'PHONE NUMBER',
                        style: TextStyle(color: _inkMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 10),
                      _phoneField(),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _err != null
                            ? Padding(
                                key: const ValueKey('err'),
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 14),
                                  const SizedBox(width: 6),
                                  Text(_err!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12.5)),
                                ]),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 28),
                      _continueButton(canContinue),
                    ]),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _enter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.shield_outlined, size: 14, color: _inkMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your number is verified through a one-time SMS. All conversations are end-to-end encrypted.',
                          style: TextStyle(color: _inkMuted.withValues(alpha: 0.85), fontSize: 11.5, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _phoneField() {
    final focused = _focus.hasFocus;
    return AnimatedBuilder(
      animation: _typePulse,
      builder: (_, _) {
        final pulse = (1 - _typePulse.value);
        final borderColor = focused
            ? Color.lerp(WAColors.brand, WAColors.brandDark, pulse)!
            : _border;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: WAColors.brand.withValues(alpha: 0.08 + 0.10 * pulse),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(children: [
            InkWell(
              onTap: _pickCountry,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(_country.code,
                      style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more, size: 18, color: _inkMuted),
                ]),
              ),
            ),
            Container(width: 1, height: 24, color: _border),
            Expanded(
              child: TextField(
                controller: _phone,
                focusNode: _focus,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                style: const TextStyle(color: _ink, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w500),
                cursorColor: WAColors.brandDark,
                decoration: const InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: TextStyle(color: _inkMuted, fontSize: 15),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                ),
                onSubmitted: (_) => _continue(),
              ),
            ),
            // Char count indicator
            if (_phone.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${_phone.text.length}',
                  style: const TextStyle(
                    color: _inkMuted, fontSize: 11.5, fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _continueButton(bool enabled) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: enabled ? 1 : 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? _ink : const Color(0xFFB8B5AE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [BoxShadow(color: _ink.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? _continue : null,
            child: const Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Continue',
                    style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _border.withValues(alpha: 0.55);
    const spacing = 24.0;
    const radius = 0.7;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
