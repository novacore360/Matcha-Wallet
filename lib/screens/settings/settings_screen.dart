import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/welcome_screen.dart';
import '../auth/pin_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (embedded) ...[
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
        ],
        _SectionLabel('Security'),
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.lock_outline,
              title: 'Change PIN',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PinSetupScreen()),
              ),
            ),
            const Divider(height: 1),
            _SwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric unlock',
              subtitle: auth.biometricAvailable ? null : 'Not available on this device',
              value: auth.biometricEnabled,
              enabled: auth.biometricAvailable,
              onChanged: (v) => auth.setBiometricEnabled(v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel('Wallet'),
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.key_outlined,
              title: 'Reveal recovery phrase',
              onTap: () => _revealMnemonic(context, wallet),
            ),
            const Divider(height: 1),
            _SettingsTile(
              icon: Icons.badge_outlined,
              title: 'Wallet address',
              trailing: Text(
                wallet.address != null && wallet.address!.length > 10
                    ? '${wallet.address!.substring(0, 4)}…${wallet.address!.substring(wallet.address!.length - 4)}'
                    : '',
                style: const TextStyle(color: AppColors.mocha, fontSize: 12.5),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: wallet.address ?? ''));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Address copied')));
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel('Danger zone'),
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.logout,
              title: 'Disconnect wallet',
              titleColor: AppColors.clay,
              onTap: () => _confirmDisconnect(context, wallet, auth),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('Matcha Wallet · v1.0.0', style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(child: body),
    );
  }

  Future<void> _revealMnemonic(BuildContext context, WalletProvider wallet) async {
    final mnemonic = await wallet.exportMnemonic();
    if (!context.mounted) return;
    if (mnemonic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This wallet was imported without a recovery phrase.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColors.clay, size: 18),
                  SizedBox(width: 8),
                  Text('Never share this phrase',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.espresso)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sand),
                ),
                child: Text(
                  mnemonic,
                  style: const TextStyle(color: AppColors.espresso, fontSize: 14.5, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    WalletProvider wallet,
    AuthProvider auth,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Disconnect wallet?'),
        content: const Text(
          'This removes the wallet and PIN from this device. Make sure you\'ve saved your recovery phrase.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: AppColors.clay)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await wallet.disconnectWallet();
      await auth.resetEverything();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: titleColor ?? AppColors.mocha),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.espresso, fontSize: 14.5)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.latte, size: 20),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.mocha),
      title: Text(title, style: const TextStyle(color: AppColors.espresso, fontSize: 14.5)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.matcha,
      ),
    );
  }
}
