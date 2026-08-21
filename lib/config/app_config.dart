import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to read build-time configuration.
///
/// Priority order:
///   1. `--dart-define=KEY=value` (what Codemagic/CI should inject —
///      compiled into the binary, nothing committed to the repo)
///   2. `.env` file (local dev convenience only — keep it out of
///      version control if it ever holds real secrets)
///   3. Hardcoded fallback (public mainnet RPC, rate-limited)
///
/// Nothing in this app is a true "secret" (RPC URLs are not private
/// keys), but keeping them out of the repo still matters: it lets you
/// point staging/prod builds at different RPC providers without
/// touching code, and keeps API keys embedded in RPC URLs (Helius,
/// QuickNode, etc.) out of git history.
class AppConfig {
  AppConfig._();

  static const _dartDefineRpcUrl = String.fromEnvironment('SOLANA_RPC_URL');
  static const _dartDefineWsUrl = String.fromEnvironment('SOLANA_WS_URL');
  static const _dartDefineCoingeckoUrl = String.fromEnvironment('COINGECKO_API_URL');
  static const _dartDefineCoingeckoApiKey = String.fromEnvironment('COINGECKO_API_KEY');

  static String get solanaRpcUrl => _resolve(
        _dartDefineRpcUrl,
        'SOLANA_RPC_URL',
        'https://api.mainnet-beta.solana.com',
      );

  static String get solanaWsUrl => _resolve(
        _dartDefineWsUrl,
        'SOLANA_WS_URL',
        'wss://api.mainnet-beta.solana.com',
      );

  static String get coingeckoApiUrl => _resolve(
        _dartDefineCoingeckoUrl,
        'COINGECKO_API_URL',
        'https://api.coingecko.com/api/v3',
      );

  /// Optional — only needed if you're on a paid CoinGecko plan.
  static String get coingeckoApiKey => _resolve(
        _dartDefineCoingeckoApiKey,
        'COINGECKO_API_KEY',
        '',
      );

  static String _resolve(String dartDefineValue, String dotenvKey, String fallback) {
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    final fromDotenv = dotenv.isInitialized ? dotenv.env[dotenvKey] : null;
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    return fallback;
  }
}
