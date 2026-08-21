import 'package:solana/solana.dart';
import 'package:solana/encoder.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../config/app_config.dart';
import '../models/token_model.dart';
import '../models/transaction_model.dart';

/// Thin wrapper around the `solana` package. Keeps all chain I/O in one
/// place so providers/UI never talk to RPC directly.
class SolanaService {
  SolanaService._internal() {
    _client = SolanaClient(
      rpcUrl: Uri.parse(AppConfig.solanaRpcUrl),
      websocketUrl: Uri.parse(AppConfig.solanaWsUrl),
    );
  }
  static final SolanaService instance = SolanaService._internal();

  late final SolanaClient _client;

  // --- Wallet creation / import -----------------------------------------

  /// Generates a fresh BIP-39 mnemonic (12 words / 128-bit entropy).
  String generateMnemonic() => bip39.generateMnemonic(strength: 128);

  bool isValidMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic.trim());

  Future<Ed25519HDKeyPair> keypairFromMnemonic(String mnemonic) {
    return Ed25519HDKeyPair.fromMnemonic(mnemonic.trim());
  }

  /// Imports a raw base58 private key (e.g. exported from Phantom/Solflare).
  Future<Ed25519HDKeyPair> keypairFromPrivateKeyBase58(String base58Key) async {
    final decoded = base58decode(base58Key.trim());
    return Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: decoded);
  }

  bool isValidPublicAddress(String address) {
    try {
      Ed25519HDPublicKey.fromBase58(address.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Balances -----------------------------------------------------

  Future<double> getSolBalance(String address) async {
    final lamports = await _client.rpcClient.getBalance(address.trim());
    return lamports.value / lamportsPerSol;
  }

  /// Returns all SPL token accounts owned by [address], mapped to
  /// [TokenAsset]s (prices/logos are filled in separately by a price feed).
  Future<List<TokenAsset>> getTokenAccounts(String address) async {
    final owner = Ed25519HDPublicKey.fromBase58(address.trim());
    final accounts = await _client.rpcClient.getTokenAccountsByOwner(
      owner.toBase58(),
      const TokenAccountsFilter.byProgramId(TokenProgram.programId),
      encoding: Encoding.jsonParsed,
    );

    final result = <TokenAsset>[];
    for (final acc in accounts.value) {
      final parsed = acc.account.data;
      // Defensive parsing — RPC shape varies slightly by node/version.
      try {
        final info = (parsed as dynamic).parsed['info'];
        final mint = info['mint'] as String;
        final tokenAmount = info['tokenAmount'];
        final decimals = tokenAmount['decimals'] as int;
        final uiAmount = (tokenAmount['uiAmount'] as num?)?.toDouble() ?? 0;
        if (uiAmount == 0) continue; // skip empty/closed accounts
        result.add(TokenAsset(
          mintAddress: mint,
          symbol: mint.substring(0, 4).toUpperCase(),
          name: 'SPL Token',
          balance: uiAmount,
          decimals: decimals,
        ));
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  // --- Transfers -----------------------------------------------------

  /// Sends native SOL. Returns the transaction signature.
  Future<String> sendSol({
    required Ed25519HDKeyPair sender,
    required String recipientAddress,
    required double amountSol,
  }) async {
    final recipient = Ed25519HDPublicKey.fromBase58(recipientAddress.trim());
    final lamports = (amountSol * lamportsPerSol).round();

    final signature = await _client.transferLamports(
      source: sender,
      destination: recipient,
      lamports: lamports,
      commitment: Commitment.confirmed,
    );
    return signature;
  }

  /// Sends an SPL token. Assumes recipient's associated token account
  /// exists or will be created as part of the instruction set.
  Future<String> sendSplToken({
    required Ed25519HDKeyPair sender,
    required String recipientAddress,
    required String mintAddress,
    required double amount,
    required int decimals,
  }) async {
    final recipient = Ed25519HDPublicKey.fromBase58(recipientAddress.trim());
    final mint = Ed25519HDPublicKey.fromBase58(mintAddress.trim());

    final signature = await _client.transferSplToken(
      mint: mint,
      destination: recipient,
      amount: BigInt.from(amount * BigInt.from(10).pow(decimals).toInt()),
      owner: sender,
      commitment: Commitment.confirmed,
    );
    return signature;
  }

  // --- Transaction history -----------------------------------------------

  Future<List<WalletTransaction>> getTransactionHistory(
    String address, {
    int limit = 25,
  }) async {
    final signatures = await _client.rpcClient.getSignaturesForAddress(
      address.trim(),
      limit: limit,
    );

    final results = <WalletTransaction>[];
    for (final sigInfo in signatures) {
      results.add(WalletTransaction(
        signature: sigInfo.signature,
        timestamp: sigInfo.blockTime != null
            ? DateTime.fromMillisecondsSinceEpoch(sigInfo.blockTime! * 1000)
            : DateTime.now(),
        direction: TxDirection.unknown, // resolved on-demand via getTransactionDetail
        amount: 0,
        tokenSymbol: 'SOL',
        counterparty: '',
        success: sigInfo.err == null,
      ));
    }
    return results;
  }

  /// Fetches full detail for a single signature to resolve direction,
  /// amount, and counterparty (called lazily, e.g. on row tap).
  Future<WalletTransaction?> getTransactionDetail(
    String signature,
    String ownerAddress,
  ) async {
    final tx = await _client.rpcClient.getTransaction(
      signature,
      encoding: Encoding.jsonParsed,
      commitment: Commitment.confirmed,
    );
    if (tx == null) return null;

    final meta = tx.meta;
    final preBalances = meta?.preBalances ?? [];
    final postBalances = meta?.postBalances ?? [];
    final accountKeys = tx.transaction.message.accountKeys
        .map((k) => k.pubkey)
        .toList();

    final ownerIndex = accountKeys.indexOf(ownerAddress);
    double delta = 0;
    if (ownerIndex >= 0 &&
        ownerIndex < preBalances.length &&
        ownerIndex < postBalances.length) {
      delta = (postBalances[ownerIndex] - preBalances[ownerIndex]) / lamportsPerSol;
    }

    final direction = delta > 0
        ? TxDirection.received
        : delta < 0
            ? TxDirection.sent
            : TxDirection.unknown;

    final counterpartyIndex = accountKeys.indexWhere((k) => k != ownerAddress);
    final counterparty = counterpartyIndex >= 0 ? accountKeys[counterpartyIndex] : '';

    return WalletTransaction(
      signature: signature,
      timestamp: tx.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(tx.blockTime! * 1000)
          : DateTime.now(),
      direction: direction,
      amount: delta.abs(),
      tokenSymbol: 'SOL',
      counterparty: counterparty,
      feeSol: (meta?.fee ?? 0) / lamportsPerSol,
      success: meta?.err == null,
    );
  }
}
