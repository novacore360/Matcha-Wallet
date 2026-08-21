import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction_model.dart';
import '../../services/solana_service.dart';

final _dateFmt = DateFormat('MMM d, h:mm a');

class TransactionHistoryScreen extends StatefulWidget {
  final bool embedded;
  const TransactionHistoryScreen({super.key, this.embedded = false});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final content = RefreshIndicator(
      color: AppColors.matcha,
      onRefresh: () => wallet.refreshAll(),
      child: wallet.transactions.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Text(
                    wallet.isLoading ? 'Loading activity…' : 'No transactions yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: wallet.transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _TxTile(tx: wallet.transactions[i], ownerAddress: wallet.address ?? ''),
            ),
    );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Activity')),
      body: content,
    );
  }
}

class _TxTile extends StatefulWidget {
  final WalletTransaction tx;
  final String ownerAddress;
  const _TxTile({required this.tx, required this.ownerAddress});

  @override
  State<_TxTile> createState() => _TxTileState();
}

class _TxTileState extends State<_TxTile> {
  WalletTransaction? _detail;
  bool _loading = false;

  Future<void> _loadDetail() async {
    if (_detail != null || _loading) return;
    setState(() => _loading = true);
    try {
      final d = await SolanaService.instance.getTransactionDetail(
        widget.tx.signature,
        widget.ownerAddress,
      );
      if (mounted) setState(() => _detail = d);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = _detail ?? widget.tx;
    final isReceived = tx.direction == TxDirection.received;
    final isSent = tx.direction == TxDirection.sent;

    return InkWell(
      onTap: _loadDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isReceived ? AppColors.matchaMist : AppColors.parchment,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sand),
              ),
              alignment: Alignment.center,
              child: Icon(
                isReceived
                    ? Icons.south_west
                    : isSent
                        ? Icons.north_east
                        : Icons.sync_alt,
                size: 16,
                color: isReceived ? AppColors.moss : AppColors.espresso,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReceived ? 'Received' : isSent ? 'Sent' : 'Transaction',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _loading ? 'Loading…' : _dateFmt.format(tx.timestamp),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.amount > 0
                      ? '${isSent ? '-' : '+'}${tx.amount.toStringAsFixed(4)} ${tx.tokenSymbol}'
                      : tx.shortSignature,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: isSent ? AppColors.clay : AppColors.moss,
                  ),
                ),
                if (!tx.success) ...[
                  const SizedBox(height: 2),
                  const Text('Failed', style: TextStyle(color: AppColors.clay, fontSize: 11)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
