import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pin_keypad.dart';
import '../dashboard/dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const int _pinLength = 6;
  String _firstPin = '';
  String _currentInput = '';
  bool _confirming = false;
  bool _error = false;

  void _onDigit(String d) {
    if (_currentInput.length >= _pinLength) return;
    setState(() {
      _currentInput += d;
      _error = false;
    });
    if (_currentInput.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _currentInput;
        _currentInput = '';
        _confirming = true;
      });
      return;
    }

    if (_currentInput == _firstPin) {
      await context.read<AuthProvider>().setPin(_firstPin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _error = true;
        _currentInput = '';
        _confirming = false;
        _firstPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(Icons.lock_outline, color: AppColors.matchaDeep, size: 32),
              const SizedBox(height: 20),
              Text(
                _confirming ? 'Confirm your PIN' : 'Set a PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _confirming
                    ? 'Enter it once more to confirm'
                    : 'You\'ll use this to unlock the app',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              PinDots(length: _pinLength, filled: _currentInput.length, error: _error),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text(
                  'PINs didn\'t match — try again',
                  style: TextStyle(color: AppColors.clay, fontSize: 13),
                ),
              ],
              const Spacer(flex: 3),
              PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
