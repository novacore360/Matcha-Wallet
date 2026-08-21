import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/primary_button.dart';
import '../auth/pin_setup_screen.dart';

enum _ImportMode { phrase, privateKey, watchOnly }

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  _ImportMode _mode = _ImportMode.phrase;
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final wallet = context.read<WalletProvider>();
    try {
      final value = _controller.text.trim();
      switch (_mode) {
        case _ImportMode.phrase:
          await wallet.importFromMnemonic(value);
          break;
        case _ImportMode.privateKey:
          await wallet.importFromPrivateKey(value);
          break;
        case _ImportMode.watchOnly:
          await wallet.importWatchOnly(value);
          break;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _modeChip(_ImportMode mode, String label) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = mode;
          _controller.clear();
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.espresso : AppColors.parchment,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.espresso : AppColors.sand),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.cream : AppColors.mocha,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String get _hint {
    switch (_mode) {
      case _ImportMode.phrase:
        return 'Enter your 12 or 24-word recovery phrase, separated by spaces';
      case _ImportMode.privateKey:
        return 'Paste your base58-encoded private key';
      case _ImportMode.watchOnly:
        return 'Paste a Solana wallet address to track it read-only';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Import wallet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _modeChip(_ImportMode.phrase, 'Recovery phrase'),
                  _modeChip(_ImportMode.privateKey, 'Private key'),
                  _modeChip(_ImportMode.watchOnly, 'Watch only'),
                ],
              ),
              const SizedBox(height: 24),
              Text(_hint, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: _mode == _ImportMode.phrase ? 3 : 1,
                obscureText: _mode == _ImportMode.privateKey && _obscure,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.espresso, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: _mode == _ImportMode.phrase
                      ? 'wagon dolphin ember ...'
                      : _mode == _ImportMode.privateKey
                          ? 'Private key'
                          : 'Wallet address',
                  suffixIcon: _mode == _ImportMode.privateKey
                      ? IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.mocha,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )
                      : null,
                ),
              ),
              if (_mode == _ImportMode.watchOnly) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.matchaMist,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Watch-only wallets can view balances and history but cannot send funds.',
                    style: TextStyle(fontSize: 12, color: AppColors.matchaDeep),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.clay, fontSize: 13)),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Import wallet',
                loading: _loading,
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
