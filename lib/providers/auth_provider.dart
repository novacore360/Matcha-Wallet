import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { unknown, locked, unlocked, noPinSet }

/// Drives the PIN-lock / biometric-unlock flow, plus brute-force
/// lockout. The app re-locks whenever it goes to background and
/// requires PIN or biometric re-entry to resume — this is the
/// "re-login using PIN" requirement.
class AuthProvider extends ChangeNotifier {
  final _storage = SecureStorageService.instance;
  final _localAuth = LocalAuthentication();

  AuthStatus status = AuthStatus.unknown;
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  int failedAttempts = 0;
  DateTime? lockedUntil;

  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  Future<void> bootstrap() async {
    final hasPin = await _storage.hasPin();
    biometricEnabled = await _storage.isBiometricEnabled();
    try {
      biometricAvailable = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      biometricAvailable = false;
    }
    lockedUntil = await _storage.getLockoutUntil();
    status = hasPin ? AuthStatus.locked : AuthStatus.noPinSet;
    notifyListeners();
  }

  /// Call this whenever the app resumes from background/paused.
  void lock() {
    if (status == AuthStatus.unlocked) {
      status = AuthStatus.locked;
      notifyListeners();
    }
  }

  Future<void> setPin(String pin) async {
    await _storage.setPin(pin);
    status = AuthStatus.locked;
    notifyListeners();
  }

  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  Duration get remainingLockout =>
      isLockedOut ? lockedUntil!.difference(DateTime.now()) : Duration.zero;

  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    final ok = await _storage.verifyPin(pin);
    if (ok) {
      await _storage.resetFailedAttempts();
      failedAttempts = 0;
      status = AuthStatus.unlocked;
      notifyListeners();
      return true;
    }

    failedAttempts = await _storage.incrementFailedAttempts();
    if (failedAttempts >= _maxAttempts) {
      lockedUntil = DateTime.now().add(_lockoutDuration);
      await _storage.setLockoutUntil(lockedUntil!);
    }
    notifyListeners();
    return false;
  }

  Future<bool> tryBiometricUnlock() async {
    if (!biometricEnabled || !biometricAvailable) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock your wallet',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) {
        status = AuthStatus.unlocked;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    biometricEnabled = enabled;
    await _storage.setBiometricEnabled(enabled);
    notifyListeners();
  }

  /// Full wipe — used for "forgot PIN" / reset-wallet flows.
  Future<void> resetEverything() async {
    await _storage.wipeAll();
    status = AuthStatus.noPinSet;
    failedAttempts = 0;
    lockedUntil = null;
    notifyListeners();
  }
}
