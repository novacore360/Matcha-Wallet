import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.eco_outlined, color: AppColors.cream, size: 28),
              ),
              const SizedBox(height: 28),
              Text('Matcha', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 6),
              Text(
                'A calmer way to hold Solana.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mocha),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Create a new wallet',
                icon: Icons.add_circle_outline,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Import existing wallet',
                icon: Icons.download_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportWalletScreen()),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Your keys stay on this device. Always.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
