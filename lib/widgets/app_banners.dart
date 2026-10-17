import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/translations.dart';

/// Thin neutral strip at the top indicating simulated demo data is present
class SimulatedDataBanner extends StatelessWidget {
  final AppLanguage language;

  const SimulatedDataBanner({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTokens.border,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space4,
      ),
      child: Center(
        child: Text(
          AppStrings.get('simulatedDataBanner', language),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTokens.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Offline indicator banner
class OfflineBanner extends StatelessWidget {
  final AppLanguage language;

  const OfflineBanner({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTokens.border,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: AppTokens.textSecondary,
          ),
          const SizedBox(width: AppTokens.space8),
          Flexible(
            child: Text(
              AppStrings.get('offlineBanner', language),
              style: const TextStyle(
                fontSize: 13,
                color: AppTokens.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decision-support disclaimer shown at the bottom of result and report screens
class DisclaimerText extends StatelessWidget {
  final AppLanguage language;

  const DisclaimerText({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
      child: Center(
        child: Text(
          AppStrings.get('disclaimer', language),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTokens.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Compact button to switch between English and Kannada
class LanguageActionButton extends StatelessWidget {
  final LanguageNotifier languageNotifier;

  const LanguageActionButton({
    super.key,
    required this.languageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final isKn = languageNotifier.isKannada;
    return TextButton(
      onPressed: () => languageNotifier.toggleLanguage(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space8,
          vertical: AppTokens.space4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
        ),
        child: Text(
          isKn ? 'English' : 'ಕನ್ನಡ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTokens.primary,
          ),
        ),
      ),
    );
  }
}
