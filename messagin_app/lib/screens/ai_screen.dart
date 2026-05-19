import 'package:flutter/material.dart';
import '../theme.dart';

/// Stub screen for the upcoming AI assistant feature.
/// Shows a centered logo with a subtle pulse, a heading + subtext, and a
/// disabled chat-style input pinned to the bottom.
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WAColors.sidebarLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WAColors.brand, WAColors.brandDark],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: _SoonChip(),
              ),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) {
                      final t = _pulse.value;
                      final scale = 1.0 + (t * 0.06);
                      final glow = 14.0 + (t * 16.0);
                      return Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [WAColors.brand, WAColors.brandDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: WAColors.brand.withValues(alpha: 0.25),
                              blurRadius: glow,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Your AI assistant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: WAColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Coming soon. Ask anything when ready.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: WAColors.mutedLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _FeatureRow(icon: Icons.summarize_outlined, label: 'Summarize chats'),
                  const SizedBox(height: 8),
                  const _FeatureRow(icon: Icons.translate, label: 'Translate messages'),
                  const SizedBox(height: 8),
                  const _FeatureRow(icon: Icons.lightbulb_outline, label: 'Draft replies'),
                ],
              ),
            ),
          ),
        ),
        // Disabled composer to suggest where the future input lives.
        const _DisabledComposer(),
      ]),
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'SOON',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: WAColors.brandDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: WAColors.mutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DisabledComposer extends StatelessWidget {
  const _DisabledComposer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WAColors.panelLight,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: SafeArea(
        top: false,
        child: Opacity(
          opacity: 0.55,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Icon(Icons.emoji_emotions_outlined,
                color: WAColors.mutedLight, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: WAColors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Ask me anything…',
                  style: TextStyle(color: WAColors.mutedLight, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: WAColors.mutedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}
