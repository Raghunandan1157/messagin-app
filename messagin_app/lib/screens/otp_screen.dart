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

class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());
  bool _verifying = false;
  String? _err;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
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
        setState(() {
          _err = 'Wrong code. Try 1234 (demo).';
          _verifying = false;
        });
        return;
      }
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
          MaterialPageRoute(builder: (_) => ProfileSetupScreen(phone: widget.phone)),
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
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: LoopColors.brand, width: 1.5)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: LoopColors.brand, width: 2)),
        ),
        onChanged: (v) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoopColors.inkDark,
        title: const Text('Verifying your number',
            style: TextStyle(color: LoopColors.inkDark, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Waiting to automatically detect an SMS sent to '),
                TextSpan(
                  text: widget.phone,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: LoopColors.inkDark),
                ),
                const TextSpan(text: '. '),
                TextSpan(
                  text: 'Wrong number?',
                  style: const TextStyle(color: LoopColors.brand, fontWeight: FontWeight.w600),
                ),
              ]),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 36),
            const Text('Enter 4-digit code', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, _digitBox),
            ),
            const SizedBox(height: 16),
            if (_verifying) const LinearProgressIndicator(color: LoopColors.brand),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6C8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                'Demo mode — use OTP 1234',
                style: TextStyle(fontSize: 12, color: Color(0xFF5A4A2A)),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message_outlined, color: LoopColors.brand),
              label: const Text('Resend SMS', style: TextStyle(color: LoopColors.brand)),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined, color: LoopColors.brand),
              label: const Text('Call me', style: TextStyle(color: LoopColors.brand)),
            ),
          ],
        ),
      ),
    );
  }
}
