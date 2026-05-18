import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  _Country _country = _countries.first;
  final _phone = TextEditingController();
  String? _err;

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _countries
              .map((c) => ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(c.name),
                    trailing: Text(c.code, style: TextStyle(color: Colors.grey.shade700)),
                    onTap: () => Navigator.pop(context, c),
                  ))
              .toList(),
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
      MaterialPageRoute(builder: (_) => OtpScreen(phone: fullPhone, country: _country.name)),
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
        title: const Text('Enter your phone number',
            style: TextStyle(color: LoopColors.inkDark, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const LoopLogo(size: 56),
            const SizedBox(height: 16),
            const Text('Messagin app',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: LoopColors.inkDark)),
            const SizedBox(height: 8),
            Text(
              'Messagin will send an SMS message to verify your phone number. ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: _pickCountry,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: LoopColors.brand, width: 1.5)),
                ),
                child: Row(children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_country.name)),
                  const Icon(Icons.arrow_drop_down, color: LoopColors.brand),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              SizedBox(
                width: 70,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: LoopColors.brand, width: 1.5)),
                  ),
                  child: Text(_country.code, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                  style: const TextStyle(fontSize: 18, letterSpacing: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'phone number',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: LoopColors.brand, width: 1.5),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: LoopColors.brand, width: 2),
                    ),
                  ),
                ),
              ),
            ]),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text('Carrier SMS charges may apply.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const Spacer(),
            SizedBox(
              width: 140,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LoopColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _continue,
                child: const Text('NEXT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
