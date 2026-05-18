import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phone;
  const ProfileSetupScreen({super.key, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _err;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Please enter your name');
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoopColors.inkDark,
        title: const Text('Profile info',
            style: TextStyle(color: LoopColors.inkDark, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Please provide your name and an optional profile photo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
            const SizedBox(height: 28),
            Stack(children: [
              LoopAvatar(initials: initials, size: 120),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: LoopColors.brand, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            TextField(
              controller: _name,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Type your name here',
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: LoopColors.brand, width: 1.5)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: LoopColors.brand, width: 2)),
              ),
              style: const TextStyle(fontSize: 17),
            ),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const Spacer(),
            SizedBox(
              width: 140,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LoopColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('NEXT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
