import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/primary_button.dart';
import '../auth/pin_setup_screen.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  String? _mnemonic;
  bool _revealed = false;
  bool _confirmedSaved = false;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final phrase = await context.read<WalletProvider>().createNewWallet();
      setState(() => _mnemonic = phrase);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t create wallet: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = _mnemonic?.split(' ') ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Your recovery phrase')),
      body: _loading || _mnemonic == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.matcha))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.matchaMist,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.matchaDeep, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Write these 12 words down and store them offline. Anyone with this phrase can access your funds.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.matchaDeep, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Stack(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 3.4,
                            ),
                            itemCount: words.length,
                            itemBuilder: (context, i) => Container(
                              decoration: BoxDecoration(
                                color: AppColors.parchment,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.sand),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${i + 1}  ',
                                      style: const TextStyle(color: AppColors.latte, fontSize: 12),
                                    ),
                                    TextSpan(
                                      text: words[i],
                                      style: const TextStyle(
                                        color: AppColors.espresso,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!_revealed)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: BackdropFilterBlur(
                                  onTap: () => setState(() => _revealed = true),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _confirmedSaved,
                          activeColor: AppColors.matcha,
                          onChanged: _revealed
                              ? (v) => setState(() => _confirmedSaved = v ?? false)
                              : null,
                        ),
                        const Expanded(
                          child: Text(
                            'I\'ve written down my recovery phrase',
                            style: TextStyle(fontSize: 13.5, color: AppColors.mocha),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: _confirmedSaved ? _continue : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class BackdropFilterBlur extends StatelessWidget {
  final VoidCallback onTap;
  const BackdropFilterBlur({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.cream.withOpacity(0.92),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.visibility_off_outlined, color: AppColors.mocha, size: 22),
            SizedBox(height: 8),
            Text('Tap to reveal', style: TextStyle(color: AppColors.mocha, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
