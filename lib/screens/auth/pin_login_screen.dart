import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pin_keypad.dart';

class PinLoginScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLoginScreen({super.key, required this.onUnlocked});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  static const int _pinLength = 6;
  String _input = '';
  bool _error = false;
  Timer? _lockoutTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBiometric());
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    super.dispose();
  }

  Future<void> _maybeBiometric() async {
    final auth = context.read<AuthProvider>();
    if (auth.biometricEnabled && auth.biometricAvailable && !auth.isLockedOut) {
      final ok = await auth.tryBiometricUnlock();
      if (ok) widget.onUnlocked();
    }
  }

  void _onDigit(String d) {
    final auth = context.read<AuthProvider>();
    if (auth.isLockedOut || _input.length >= _pinLength) return;
    setState(() {
      _input += d;
      _error = false;
    });
    if (_input.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 100), _verify);
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyPin(_input);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = true;
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lockedOut = auth.isLockedOut;
    final remaining = auth.remainingLockout;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(Icons.eco_outlined, color: AppColors.matchaDeep, size: 34),
              const SizedBox(height: 20),
              Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                lockedOut
                    ? 'Too many attempts. Try again in ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                    : 'Enter your PIN to continue',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              PinDots(length: _pinLength, filled: _input.length, error: _error),
              const Spacer(flex: 3),
              Opacity(
                opacity: lockedOut ? 0.35 : 1,
                child: IgnorePointer(
                  ignoring: lockedOut,
                  child: PinKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    showBiometric: auth.biometricEnabled && auth.biometricAvailable,
                    onBiometric: _maybeBiometric,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
