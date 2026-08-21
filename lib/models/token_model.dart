class TokenAsset {
  final String mintAddress;
  final String symbol;
  final String name;
  final String? logoUrl;
  final double balance;
  final int decimals;
  final double priceUsd;
  final double change24hPercent;
  final bool isNative; // true for SOL itself

  const TokenAsset({
    required this.mintAddress,
    required this.symbol,
    required this.name,
    this.logoUrl,
    required this.balance,
    required this.decimals,
    this.priceUsd = 0,
    this.change24hPercent = 0,
    this.isNative = false,
  });

  double get valueUsd => balance * priceUsd;

  TokenAsset copyWith({
    double? balance,
    double? priceUsd,
    double? change24hPercent,
  }) {
    return TokenAsset(
      mintAddress: mintAddress,
      symbol: symbol,
      name: name,
      logoUrl: logoUrl,
      balance: balance ?? this.balance,
      decimals: decimals,
      priceUsd: priceUsd ?? this.priceUsd,
      change24hPercent: change24hPercent ?? this.change24hPercent,
      isNative: isNative,
    );
  }
}
