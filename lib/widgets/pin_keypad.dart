import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Minimalist numeric keypad + dot indicator used for both PIN setup
/// and PIN unlock screens.
class PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool error;

  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: error
                ? AppColors.clay
                : (isFilled ? AppColors.espresso : Colors.transparent),
            border: Border.all(
              color: error ? AppColors.clay : AppColors.espresso,
              width: 1.4,
            ),
          ),
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool showBiometric;

  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    Widget buildKey(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            height: 68,
            child: Center(
              child: child ??
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in rows)
          Row(children: row.map((d) => buildKey(d, onTap: () => onDigit(d))).toList()),
        Row(
          children: [
            buildKey(
              '',
              onTap: showBiometric ? onBiometric : null,
              child: showBiometric
                  ? const Icon(Icons.fingerprint, color: AppColors.mocha, size: 26)
                  : const SizedBox.shrink(),
            ),
            buildKey('0', onTap: () => onDigit('0')),
            buildKey(
              '',
              onTap: onBackspace,
              child: const Icon(Icons.backspace_outlined, color: AppColors.mocha, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}
