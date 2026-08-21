import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/token_model.dart';
import '../../services/solana_service.dart';
import '../../widgets/primary_button.dart';

class SendScreen extends StatefulWidget {
  final TokenAsset? preselectedToken;
  const SendScreen({super.key, this.preselectedToken});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  TokenAsset? _selectedToken;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedToken = widget.preselectedToken;
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (result != null) {
      setState(() => _addressController.text = result);
    }
  }

  Future<void> _review() async {
    final wallet = context.read<WalletProvider>();
    final token = _selectedToken;
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();

    if (!SolanaService.instance.isValidPublicAddress(address)) {
      setState(() => _error = 'Enter a valid Solana address');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ConfirmSheet(
        address: address,
        amount: amount,
        symbol: token?.symbol ?? 'SOL',
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final String sig;
      if (token == null || token.isNative) {
        sig = await wallet.sendSol(toAddress: address, amount: amount);
      } else {
        sig = await wallet.sendToken(toAddress: address, token: token, amount: amount);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction sent — ${sig.substring(0, 8)}…')),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final options = <TokenAsset>[
      TokenAsset(
        mintAddress: 'native-sol',
        symbol: 'SOL',
        name: 'Solana',
        balance: wallet.solBalance,
        decimals: 9,
        priceUsd: wallet.solPriceUsd,
        isNative: true,
      ),
      ...wallet.tokens,
    ];
    _selectedToken ??= options.first;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Send')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asset', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sand),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TokenAsset>(
                    value: options.firstWhere(
                      (o) => o.mintAddress == _selectedToken!.mintAddress,
                      orElse: () => options.first,
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: AppColors.mocha),
                    items: options
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.symbol} — ${t.balance.toStringAsFixed(4)} available'),
                            ))
                        .toList(),
                    onChanged: (t) => setState(() => _selectedToken = t),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Recipient address', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: const TextStyle(fontSize: 14, color: AppColors.espresso),
                decoration: InputDecoration(
                  hintText: 'Solana address',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 20, color: AppColors.mocha),
                    onPressed: _scanQr,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Amount', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14, color: AppColors.espresso),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixIcon: TextButton(
                    onPressed: () => setState(
                      () => _amountController.text = _selectedToken!.balance.toString(),
                    ),
                    child: const Text('MAX'),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.clay, fontSize: 13)),
              ],
              const Spacer(),
              PrimaryButton(label: 'Review transfer', loading: _sending, onPressed: _review),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String address;
  final double amount;
  final String symbol;
  const _ConfirmSheet({required this.address, required this.amount, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm transfer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _row(context, 'Sending', '$amount $symbol'),
            const SizedBox(height: 10),
            _row(context, 'To', address),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(label: 'Confirm & send', onPressed: () => Navigator.pop(context, true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppColors.espresso, fontSize: 13.5)),
        ),
      ],
    );
  }
}

class _QrScannerScreen extends StatelessWidget {
  const _QrScannerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan address'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
