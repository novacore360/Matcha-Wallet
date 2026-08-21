import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/token_model.dart';
import '../../widgets/primary_button.dart';
import '../send/send_screen.dart';
import '../receive/receive_screen.dart';

final _usd = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _qty = NumberFormat.decimalPattern();

class TokenDetailScreen extends StatelessWidget {
  final TokenAsset token;
  const TokenDetailScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final isPositive = token.change24hPercent >= 0;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(token.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: AppColors.matchaMist, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  token.symbol.isNotEmpty ? token.symbol[0] : '?',
                  style: const TextStyle(
                    color: AppColors.matchaDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('${_qty.format(token.balance)} ${token.symbol}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    token.priceUsd > 0 ? _usd.format(token.valueUsd) : 'No price data',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (token.priceUsd > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      '${isPositive ? '+' : ''}${token.change24hPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isPositive ? AppColors.moss : AppColors.clay,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Send',
                      icon: Icons.north_east,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SendScreen(preselectedToken: token)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Receive',
                      icon: Icons.south_west,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReceiveScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),
              _InfoRow(label: 'Mint address', value: token.isNative ? 'Native SOL' : token.mintAddress),
              _InfoRow(label: 'Decimals', value: token.decimals.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.espresso, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
