import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(child: LoopAvatar(initials: me.initials, size: 100)),
          const SizedBox(height: 16),
          Center(child: Text(me.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
          Center(child: Text(me.phone, style: TextStyle(color: Colors.grey.shade700))),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline, color: LoopColors.brand),
            title: const Text('About'),
            subtitle: Text(me.about ?? '—'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: LoopColors.brand),
            title: const Text('Privacy'),
            subtitle: const Text('End-to-end encrypted'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: LoopColors.brand),
            title: const Text('Notifications'),
            subtitle: const Text('Sounds, vibration, previews'),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: LoopColors.brand),
            title: const Text('Storage & data'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AppState>().signOut();
              if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
