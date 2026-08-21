import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/token_model.dart';

final _usd = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _qty = NumberFormat.decimalPattern();

class AssetTile extends StatelessWidget {
  final TokenAsset token;
  final VoidCallback? onTap;

  const AssetTile({super.key, required this.token, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = token.change24hPercent >= 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.matchaMist,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                token.symbol.isNotEmpty ? token.symbol[0] : '?',
                style: const TextStyle(
                  color: AppColors.matchaDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${_qty.format(token.balance)} ${token.symbol}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  token.priceUsd > 0 ? _usd.format(token.valueUsd) : '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                if (token.priceUsd > 0)
                  Text(
                    '${isPositive ? '+' : ''}${token.change24hPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPositive ? AppColors.moss : AppColors.clay,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
