import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/pin_login_screen.dart';
import 'dashboard/dashboard_screen.dart';

/// Wraps the authenticated part of the app. Watches app lifecycle so that
/// backgrounding the app always re-locks it — satisfying "re-login using
/// PIN" as a persistent security behavior, not just a first-launch gate.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<AuthProvider>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.unlocked) {
      return const DashboardScreen();
    }
    return PinLoginScreen(onUnlocked: () => setState(() {}));
  }
}
