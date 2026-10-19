import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/thresholds.dart';
import '../l10n/translations.dart';

/// Color-coded badge displaying water risk level with accompanying icon and label.
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
          horizontal: AppTokens.space12,
          vertical: AppTokens.space4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTokens.space8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
