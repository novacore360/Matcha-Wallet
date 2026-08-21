enum TxDirection { sent, received, swap, unknown }

class WalletTransaction {
  final String signature;
  final DateTime timestamp;
  final TxDirection direction;
  final double amount;
  final String tokenSymbol;
  final String counterparty; // sender or receiver address
  final double feeSol;
  final bool success;

  const WalletTransaction({
    required this.signature,
    required this.timestamp,
    required this.direction,
    required this.amount,
    required this.tokenSymbol,
    required this.counterparty,
    this.feeSol = 0,
    this.success = true,
  });

  String get shortSignature =>
      '${signature.substring(0, 6)}…${signature.substring(signature.length - 6)}';

  String get shortCounterparty => counterparty.length > 12
      ? '${counterparty.substring(0, 5)}…${counterparty.substring(counterparty.length - 5)}'
      : counterparty;
}
