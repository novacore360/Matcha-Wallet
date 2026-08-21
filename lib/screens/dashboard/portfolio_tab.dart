import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/token_model.dart';
import '../../widgets/asset_tile.dart';
import '../send/send_screen.dart';
import '../receive/receive_screen.dart';
import 'token_detail_screen.dart';

final _usd = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

class PortfolioTab extends StatefulWidget {
  const PortfolioTab({super.key});

  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    final solAsset = TokenAsset(
      mintAddress: 'native-sol',
      symbol: 'SOL',
      name: 'Solana',
      balance: wallet.solBalance,
      decimals: 9,
      priceUsd: wallet.solPriceUsd,
      change24hPercent: wallet.solChange24h,
      isNative: true,
    );
    final allAssets = [solAsset, ...wallet.tokens];

    return RefreshIndicator(
      color: AppColors.matcha,
      onRefresh: () => wallet.refreshAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Portfolio', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  _AddressPill(address: wallet.address ?? ''),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Total value', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            _usd.format(wallet.totalPortfolioUsd),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          if (wallet.mode == WalletMode.watchOnly) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 14, color: AppColors.latte),
                const SizedBox(width: 6),
                Text('Watch-only wallet', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Send',
                  icon: Icons.north_east,
                  onTap: wallet.mode == WalletMode.full
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SendScreen()),
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Receive',
                  icon: Icons.south_west,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReceiveScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (allAssets.where((a) => a.valueUsd > 0).length > 1) ...[
            _AllocationChart(assets: allAssets),
            const SizedBox(height: 28),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assets', style: Theme.of(context).textTheme.titleMedium),
              if (wallet.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.matcha),
                ),
            ],
          ),
          const Divider(height: 20),
          for (final asset in allAssets)
            AssetTile(
              token: asset,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TokenDetailScreen(token: asset)),
              ),
            ),
          if (allAssets.length == 1 && wallet.solBalance == 0 && !wallet.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No assets yet. Receive SOL to get started.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (wallet.lastError != null) ...[
            const SizedBox(height: 12),
            Text(wallet.lastError!, style: const TextStyle(color: AppColors.clay, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  final String address;
  const _AddressPill({required this.address});

  @override
  Widget build(BuildContext context) {
    final short = address.length > 8
        ? '${address.substring(0, 4)}…${address.substring(address.length - 4)}'
        : address;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 13, color: AppColors.mocha),
          const SizedBox(width: 6),
          Text(short, style: const TextStyle(fontSize: 12, color: AppColors.mocha)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? AppColors.parchment : AppColors.espresso,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: disabled ? AppColors.latte : AppColors.cream),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: disabled ? AppColors.latte : AppColors.cream,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationChart extends StatelessWidget {
  final List<TokenAsset> assets;
  const _AllocationChart({required this.assets});

  static const _palette = [
    AppColors.matcha,
    AppColors.mocha,
    AppColors.clay,
    AppColors.latte,
    AppColors.matchaDeep,
  ];

  @override
  Widget build(BuildContext context) {
    final valued = assets.where((a) => a.valueUsd > 0).toList()
      ..sort((a, b) => b.valueUsd.compareTo(a.valueUsd));
    final total = valued.fold<double>(0, (s, a) => s + a.valueUsd);
    if (total == 0) return const SizedBox.shrink();

    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (int i = 0; i < valued.length; i++)
                  PieChartSectionData(
                    value: valued[i].valueUsd,
                    color: _palette[i % _palette.length],
                    radius: 20,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < (valued.length > 4 ? 4 : valued.length); i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          valued[i].symbol,
                          style: const TextStyle(fontSize: 13, color: AppColors.espresso),
                        ),
                      ),
                      Text(
                        '${(valued[i].valueUsd / total * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.mocha),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
