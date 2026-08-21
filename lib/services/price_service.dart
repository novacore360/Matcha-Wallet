import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PriceService {
  PriceService._internal();
  static final PriceService instance = PriceService._internal();

  String get _base => AppConfig.coingeckoApiUrl;

  Map<String, String> get _headers => AppConfig.coingeckoApiKey.isNotEmpty
      ? {'x-cg-demo-api-key': AppConfig.coingeckoApiKey}
      : const {};

  /// Returns USD price + 24h change for SOL.
  Future<(double price, double change24h)> getSolPrice() async {
    final uri = Uri.parse(
      '$_base/simple/price?ids=solana&vs_currencies=usd&include_24hr_change=true',
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return (0.0, 0.0);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final sol = data['solana'] as Map<String, dynamic>?;
    if (sol == null) return (0.0, 0.0);
    return (
      (sol['usd'] as num?)?.toDouble() ?? 0.0,
      (sol['usd_24h_change'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Batched lookup for SPL tokens by mint address, via CoinGecko's
  /// Solana token-address endpoint. Mints CoinGecko doesn't track
  /// simply come back with a price of 0 (shown as "—" in the UI).
  Future<Map<String, double>> getTokenPricesByMint(List<String> mints) async {
    if (mints.isEmpty) return {};
    final uri = Uri.parse(
      '$_base/simple/token_price/solana?contract_addresses=${mints.join(",")}&vs_currencies=usd',
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return {};
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result = <String, double>{};
    data.forEach((mint, value) {
      final usd = (value as Map<String, dynamic>)['usd'];
      result[mint] = (usd as num?)?.toDouble() ?? 0.0;
    });
    return result;
  }
}
