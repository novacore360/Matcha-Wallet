import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import '../models/token_model.dart';
import '../models/transaction_model.dart';
import '../services/solana_service.dart';
import '../services/secure_storage_service.dart';
import '../services/price_service.dart';

enum WalletMode {
  none, // no wallet loaded yet
  watchOnly, // imported by public address only — cannot sign
  full, // full keypair available — can sign & send
}

class WalletProvider extends ChangeNotifier {
  final _chain = SolanaService.instance;
  final _storage = SecureStorageService.instance;
  final _prices = PriceService.instance;

  WalletMode mode = WalletMode.none;
  String? address;
  Ed25519HDKeyPair? _keypair; // held in memory only, never persisted as-is

  double solBalance = 0;
  double solPriceUsd = 0;
  double solChange24h = 0;
  List<TokenAsset> tokens = [];
  List<WalletTransaction> transactions = [];

  bool isLoading = false;
  String? lastError;

  double get totalPortfolioUsd {
    final solValue = solBalance * solPriceUsd;
    final tokensValue = tokens.fold<double>(0, (sum, t) => sum + t.valueUsd);
    return solValue + tokensValue;
  }

  /// Loads a wallet already persisted in secure storage (app restart).
  Future<void> restoreFromStorage() async {
    final storedAddress = await _storage.readPublicKey();
    if (storedAddress == null) return;

    final privKeyBytes = await _storage.readPrivateKey();
    if (privKeyBytes != null) {
      _keypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: privKeyBytes);
      mode = WalletMode.full;
    } else {
      mode = WalletMode.watchOnly;
    }
    address = storedAddress;
    notifyListeners();
    await refreshAll();
  }

  /// Same as [restoreFromStorage] but returns whether a wallet was found —
  /// used by the splash screen to decide where to route.
  Future<bool> restoreFromStorageAndCheck() async {
    final storedAddress = await _storage.readPublicKey();
    if (storedAddress == null) return false;
    await restoreFromStorage();
    return true;
  }

  /// Creates a brand-new wallet + mnemonic. Caller is responsible for
  /// showing the user their recovery phrase exactly once before this
  /// is considered "confirmed" (see CreateWalletScreen).
  Future<String> createNewWallet() async {
    final mnemonic = _chain.generateMnemonic();
    final keypair = await _chain.keypairFromMnemonic(mnemonic);
    await _persistFullWallet(mnemonic, keypair);
    return mnemonic;
  }

  Future<void> importFromMnemonic(String mnemonic) async {
    if (!_chain.isValidMnemonic(mnemonic)) {
      throw Exception('That recovery phrase doesn\'t look valid. Check the words and try again.');
    }
    final keypair = await _chain.keypairFromMnemonic(mnemonic);
    await _persistFullWallet(mnemonic, keypair);
  }

  Future<void> importFromPrivateKey(String base58Key) async {
    final keypair = await _chain.keypairFromPrivateKeyBase58(base58Key);
    await _storage.savePrivateKey(await keypair.extractPrivateKeyBytes());
    await _finishImport(keypair.address, keypair);
  }

  /// Watch-only import — user just pastes a public address, no signing key.
  Future<void> importWatchOnly(String publicAddress) async {
    if (!_chain.isValidPublicAddress(publicAddress)) {
      throw Exception('That doesn\'t look like a valid Solana address.');
    }
    await _storage.wipeWallet();
    await _storage.savePublicKey(publicAddress.trim());
    address = publicAddress.trim();
    _keypair = null;
    mode = WalletMode.watchOnly;
    notifyListeners();
    await refreshAll();
  }

  Future<void> _persistFullWallet(String mnemonic, Ed25519HDKeyPair keypair) async {
    await _storage.wipeWallet();
    await _storage.saveMnemonic(mnemonic);
    await _storage.savePrivateKey(await keypair.extractPrivateKeyBytes());
    await _finishImport(keypair.address, keypair);
  }

  Future<void> _finishImport(String addr, Ed25519HDKeyPair keypair) async {
    await _storage.savePublicKey(addr);
    address = addr;
    _keypair = keypair;
    mode = WalletMode.full;
    notifyListeners();
    await refreshAll();
  }

  Future<void> refreshAll() async {
    if (address == null) return;
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _chain.getSolBalance(address!),
        _chain.getTokenAccounts(address!),
        _prices.getSolPrice(),
        _chain.getTransactionHistory(address!),
      ]);
      solBalance = results[0] as double;
      tokens = results[1] as List<TokenAsset>;
      final (price, change) = results[2] as (double, double);
      solPriceUsd = price;
      solChange24h = change;
      transactions = results[3] as List<WalletTransaction>;

      // Best-effort token pricing; failures shouldn't block the dashboard.
      if (tokens.isNotEmpty) {
        try {
          final priceMap = await _prices.getTokenPricesByMint(
            tokens.map((t) => t.mintAddress).toList(),
          );
          tokens = tokens
              .map((t) => t.copyWith(priceUsd: priceMap[t.mintAddress] ?? 0))
              .toList();
        } catch (_) {
          // ignore, tokens simply show no USD value
        }
      }
    } catch (e) {
      lastError = 'Couldn\'t refresh wallet data. Check your connection.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> sendSol({required String toAddress, required double amount}) async {
    _requireSigner();
    final sig = await _chain.sendSol(
      sender: _keypair!,
      recipientAddress: toAddress,
      amountSol: amount,
    );
    await refreshAll();
    return sig;
  }

  Future<String> sendToken({
    required String toAddress,
    required TokenAsset token,
    required double amount,
  }) async {
    _requireSigner();
    final sig = await _chain.sendSplToken(
      sender: _keypair!,
      recipientAddress: toAddress,
      mintAddress: token.mintAddress,
      amount: amount,
      decimals: token.decimals,
    );
    await refreshAll();
    return sig;
  }

  void _requireSigner() {
    if (mode != WalletMode.full || _keypair == null) {
      throw Exception(
        'This wallet is watch-only — import your recovery phrase or private key to send.',
      );
    }
  }

  Future<String?> exportMnemonic() => _storage.readMnemonic();

  Future<void> disconnectWallet() async {
    await _storage.wipeWallet();
    address = null;
    _keypair = null;
    mode = WalletMode.none;
    solBalance = 0;
    tokens = [];
    transactions = [];
    notifyListeners();
  }
}
