import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// All sensitive material (seed phrase, private key, PIN hash) lives only
/// in the OS-backed secure enclave (iOS Keychain / Android Keystore via
/// EncryptedSharedPreferences). Nothing sensitive ever touches plain
/// SharedPreferences, logs, or app state longer than necessary.
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _kMnemonic = 'wallet_mnemonic_v1';
  static const _kPrivateKey = 'wallet_private_key_v1';
  static const _kPublicKey = 'wallet_public_key_v1';
  static const _kPinHash = 'pin_hash_v1';
  static const _kPinSalt = 'pin_salt_v1';
  static const _kBiometricEnabled = 'biometric_enabled_v1';
  static const _kFailedAttempts = 'pin_failed_attempts_v1';
  static const _kLockoutUntil = 'pin_lockout_until_v1';

  // --- Wallet key material ---------------------------------------------

  Future<void> saveMnemonic(String mnemonic) =>
      _storage.write(key: _kMnemonic, value: mnemonic);

  Future<String?> readMnemonic() => _storage.read(key: _kMnemonic);

  Future<void> savePrivateKey(List<int> secretKeyBytes) =>
      _storage.write(key: _kPrivateKey, value: base64Encode(secretKeyBytes));

  Future<List<int>?> readPrivateKey() async {
    final raw = await _storage.read(key: _kPrivateKey);
    if (raw == null) return null;
    return base64Decode(raw);
  }

  Future<void> savePublicKey(String address) =>
      _storage.write(key: _kPublicKey, value: address);

  Future<String?> readPublicKey() => _storage.read(key: _kPublicKey);

  Future<bool> hasWallet() async => (await readPublicKey()) != null;

  Future<void> wipeWallet() async {
    await _storage.delete(key: _kMnemonic);
    await _storage.delete(key: _kPrivateKey);
    await _storage.delete(key: _kPublicKey);
  }

  // --- PIN (never stored in plaintext — salted SHA-256) -----------------

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    await _storage.delete(key: _kFailedAttempts);
    await _storage.delete(key: _kLockoutUntil);
  }

  Future<bool> hasPin() async => (await _storage.read(key: _kPinHash)) != null;

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final storedHash = await _storage.read(key: _kPinHash);
    if (salt == null || storedHash == null) return false;
    final candidate = _hashPin(pin, salt);
    // Constant-time compare to reduce timing side-channels.
    return _constantTimeEquals(candidate, storedHash);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // --- Brute-force lockout ------------------------------------------

  Future<int> incrementFailedAttempts() async {
    final current = int.tryParse(await _storage.read(key: _kFailedAttempts) ?? '0') ?? 0;
    final next = current + 1;
    await _storage.write(key: _kFailedAttempts, value: next.toString());
    return next;
  }

  Future<void> resetFailedAttempts() => _storage.write(key: _kFailedAttempts, value: '0');

  Future<void> setLockoutUntil(DateTime time) =>
      _storage.write(key: _kLockoutUntil, value: time.millisecondsSinceEpoch.toString());

  Future<DateTime?> getLockoutUntil() async {
    final raw = await _storage.read(key: _kLockoutUntil);
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
  }

  // --- Biometric preference -------------------------------------------

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBiometricEnabled, value: enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabled)) == 'true';

  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }
}
