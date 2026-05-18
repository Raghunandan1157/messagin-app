import 'dart:math' as math;
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  _Country _country = _countries.first;
  final _phone = TextEditingController();
  String? _err;
  late final AnimationController _float;
  late final AnimationController _enter;
  late final AnimationController _grad;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _grad = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _float.dispose();
    _enter.dispose();
    _grad.dispose();
    _pulse.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('Choose your country',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: WAColors.inkLight)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _countries
                    .map((c) => ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                          title: Text(c.name, style: const TextStyle(color: WAColors.inkLight)),
                          trailing: Text(c.code,
                              style: const TextStyle(color: WAColors.mutedLight, fontWeight: FontWeight.w500)),
                          onTap: () => Navigator.pop(context, c),
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
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, anim, __) => OtpScreen(phone: fullPhone, country: _country.name),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
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
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Stack(children: [
          // Animated gradient backdrop
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
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          // Floating bubbles illustration
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Stack(children: [
              _floatBubble(top: 70, left: 24, delay: 0, text: 'Hey 👋', mine: false),
              _floatBubble(top: 130, right: 30, delay: 0.5, text: 'Lunch at 1?', mine: true),
              _floatBubble(top: 210, left: 36, delay: 0.2, text: 'On my way 🚗', mine: false),
              _floatBubble(top: 270, right: 24, delay: 0.7, text: '🔥', mine: true, small: true),
            ]),
          ),
          // Soft blobs
          Positioned(
            top: -90, right: -90,
            child: _blob(260, Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            bottom: -120, left: -80,
            child: _blob(300, Colors.white.withValues(alpha: 0.06)),
          ),
          SafeArea(
            child: Column(children: [
              const Spacer(),
              FadeTransition(
                opacity: _enter,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOut)),
                  child: Column(children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse ring
                          Container(
                            width: 78 + _pulse.value * 30,
                            height: 78 + _pulse.value * 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25 * (1 - _pulse.value)),
                                width: 2,
                              ),
                            ),
                          ),
                          Container(
                            width: 78 + _pulse.value * 60,
                            height: 78 + _pulse.value * 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12 * (1 - _pulse.value)),
                                width: 1,
                              ),
                            ),
                          ),
                          child!,
                        ],
                      ),
                      child: Container(
                        width: 78, height: 78,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFE0F5EF)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: WAColors.brand.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.all_inclusive, color: WAColors.brandDark, size: 36),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Messagin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat with your whole team.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _enter,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Phone number',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        InkWell(
                          onTap: _pickCountry,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            child: Row(children: [
                              Text(_country.flag, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Text(_country.code,
                                  style: const TextStyle(color: WAColors.inkLight, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, color: WAColors.mutedLight, size: 22),
                            ]),
                          ),
                        ),
                        Container(width: 1, height: 24, color: WAColors.divider),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            autofocus: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            style: const TextStyle(fontSize: 18, color: WAColors.inkLight, letterSpacing: 1.2, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: '00000 00000',
                              hintStyle: TextStyle(color: WAColors.mutedLight, fontSize: 16, letterSpacing: 1.2),
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onSubmitted: (_) => canContinue ? _continue() : null,
                          ),
                        ),
                      ]),
                    ),
                    if (_err != null) ...[
                      const SizedBox(height: 8),
                      Text(_err!, style: const TextStyle(color: Color(0xFFFFC4C4), fontSize: 12)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: canContinue
                                ? const [Colors.white, Color(0xFFE9FFF7)]
                                : [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.35)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: canContinue
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: canContinue ? _continue : null,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: canContinue ? WAColors.brandDark : WAColors.mutedLight,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: canContinue ? WAColors.brandDark : WAColors.mutedLight),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.lock_outline, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text('End-to-end encrypted',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'By continuing you agree to receive a one-time verification SMS. Carrier rates may apply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _floatBubble({
    double? top, double? left, double? right,
    required double delay,
    required String text,
    required bool mine,
    bool small = false,
  }) {
    final v = (math.sin((_float.value + delay) * math.pi * 2) * 6).toDouble();
    final fontSize = small ? 16.0 : 13.0;
    final bg = mine ? const Color(0xFFD9FDD3) : Colors.white;
    final fg = WAColors.inkLight;
    return Positioned(
      top: top == null ? null : top + v,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: mine ? 0.04 : -0.04,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 8 : 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(mine ? 16 : 4),
              topRight: Radius.circular(mine ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(text, style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
