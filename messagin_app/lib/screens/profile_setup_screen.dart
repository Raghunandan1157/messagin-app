import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

const _bgLight = Color(0xFFFAFAF7);
const _ink = Color(0xFF0A1310);
const _inkMuted = Color(0xFF5C6660);
const _border = Color(0xFFD8D6D0);

class ProfileSetupScreen extends StatefulWidget {
  final String phone;
  const ProfileSetupScreen({super.key, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;
  String? _err;
  late final AnimationController _enter;
  late final AnimationController _typePulse;
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _typePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _focus.addListener(() => setState(() {}));
    _name.addListener(() {
      final l = _name.text.length;
      if (l != _lastLen) {
        _typePulse.forward(from: 0);
        if (l > _lastLen) HapticFeedback.selectionClick();
        _lastLen = l;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _typePulse.dispose();
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Enter your name to continue');
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      await context.read<AppState>().completeSignIn(widget.phone, name);
      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.text.isEmpty ? '?' : _name.text.trim().substring(0, 1).toUpperCase();
    final canSave = _name.text.trim().isNotEmpty;
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
                const SizedBox(height: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back, color: _ink),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _enter,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text(
                        'Set up your profile',
                        style: TextStyle(color: _ink, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.1),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your name is shown to teammates when you start a chat or join a group.',
                        style: TextStyle(color: _inkMuted, fontSize: 14.5, height: 1.5),
                      ),
                      const SizedBox(height: 36),
                      Row(children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          scale: canSave ? 1 : 0.95,
                          child: LoopAvatar(initials: initials, size: 64),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(canSave ? 'Looks good' : 'Preview',
                                style: const TextStyle(color: _inkMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              canSave ? _name.text.trim() : 'Your name',
                              style: TextStyle(
                                color: canSave ? _ink : _inkMuted.withValues(alpha: 0.55),
                                fontSize: 18, fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(widget.phone,
                                style: const TextStyle(color: _inkMuted, fontSize: 12.5)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      const Text(
                        'YOUR NAME',
                        style: TextStyle(color: _inkMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4),
                      ),
                      const SizedBox(height: 10),
                      _nameField(),
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
                    ]),
                  ),
                ),
                const Spacer(),
                _continueButton(canSave),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _nameField() {
    final focused = _focus.hasFocus;
    return AnimatedBuilder(
      animation: _typePulse,
      builder: (_, _) {
        final pulse = 1 - _typePulse.value;
        final borderColor = focused
            ? Color.lerp(WAColors.brand, WAColors.brandDark, pulse)!
            : _border;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: focused ? 1.6 : 1),
            boxShadow: focused
                ? [BoxShadow(color: WAColors.brand.withValues(alpha: 0.08 + 0.10 * pulse), blurRadius: 16, spreadRadius: 2)]
                : null,
          ),
          child: TextField(
            controller: _name,
            focusNode: _focus,
            autofocus: true,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w500),
            cursorColor: WAColors.brandDark,
            decoration: const InputDecoration(
              hintText: 'Full name',
              hintStyle: TextStyle(color: _inkMuted, fontSize: 15),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSubmitted: (_) => _save(),
          ),
        );
      },
    );
  }

  Widget _continueButton(bool enabled) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: enabled && !_saving ? 1 : 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? _ink : const Color(0xFFB8B5AE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled ? [BoxShadow(color: _ink.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6))] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled && !_saving ? _save : null,
            child: Center(
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
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
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
