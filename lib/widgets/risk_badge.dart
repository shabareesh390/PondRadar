import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/thresholds.dart';
import '../l10n/translations.dart';

class RiskBadge extends StatelessWidget {
  final WaterRiskLevel risk;
  final AppLanguage language;
  final bool isLarge;

  const RiskBadge({
    super.key,
    required this.risk,
    required this.language,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    switch (risk) {
      case WaterRiskLevel.low:
        color = AppTokens.riskLow;
        icon = Icons.check_circle_outline;
        label = language == AppLanguage.kn ? 'ಕಡಿಮೆ ಅಪಾಯ' : 'Low risk';
        break;
      case WaterRiskLevel.medium:
        color = AppTokens.riskMedium;
        icon = Icons.warning_amber_outlined;
        label = language == AppLanguage.kn ? 'ಮಧ್ಯಮ ಅಪಾಯ' : 'Medium risk';
        break;
      case WaterRiskLevel.high:
        color = AppTokens.riskHigh;
        icon = Icons.error_outline;
        label = language == AppLanguage.kn ? 'ಹೆಚ್ಚಿನ ಅಪಾಯ' : 'High risk';
        break;
    }

    if (isLarge) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppTokens.space8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.controlRadius),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppTokens.space4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
