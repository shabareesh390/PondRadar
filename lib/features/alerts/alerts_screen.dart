import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/translations.dart';
import '../../models/outbreak_alert.dart';
import '../../models/pond.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_banners.dart';

class AlertsScreen extends StatefulWidget {
  final List<Pond> ponds;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const AlertsScreen({
    super.key,
    required this.ponds,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final Set<String> _notifiedAlertIds = {};

  void _checkAndNotifyNewAlerts(List<OutbreakAlert> alerts) {
    if (widget.ponds.isEmpty) return;

    for (final alert in alerts) {
      if (_notifiedAlertIds.contains(alert.id)) continue;

      // Find nearest pond
      double minDistance = double.infinity;
      String nearestPondName = widget.ponds.first.name;

      for (final pond in widget.ponds) {
        final dist = LocationService.haversineDistanceKm(
          pond.latitude,
          pond.longitude,
          alert.centerLat,
          alert.centerLng,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestPondName = pond.name;
        }
      }

      // If cluster is within 15km of any pond, trigger notification
      if (minDistance <= 15.0) {
        _notifiedAlertIds.add(alert.id);
        NotificationService().showOutbreakAlert(
          id: alert.id.hashCode,
          title: 'Early Warning: Disease Cluster Near $nearestPondName',
          body:
              'Outbreak cluster detected ${minDistance.toStringAsFixed(1)} km away (${alert.uniqueReporters} farms reporting ${alert.symptoms.join(', ')}).',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('alertsTitle', lang)),
        actions: [
          LanguageActionButton(languageNotifier: widget.languageNotifier),
          const SizedBox(width: AppTokens.space8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<OutbreakAlert>>(
          stream: widget.firestoreService.getAlertsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            final allAlerts = snapshot.data ?? [];

            // Trigger local notification for any new alert near ponds
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndNotifyNewAlerts(allAlerts);
            });

            // Calculate distance relative to user ponds
            final alertItems = allAlerts.map((alert) {
              double minDistance = double.infinity;
              String nearestPondName = '';

              for (final pond in widget.ponds) {
                final dist = LocationService.haversineDistanceKm(
                  pond.latitude,
                  pond.longitude,
                  alert.centerLat,
                  alert.centerLng,
                );
                if (dist < minDistance) {
                  minDistance = dist;
                  nearestPondName = pond.name;
                }
              }

              return {
                'alert': alert,
                'minDistance': minDistance,
                'nearestPond': nearestPondName,
              };
            }).toList();

            if (alertItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppTokens.space24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppTokens.riskLow,
                      ),
                      const SizedBox(height: AppTokens.space16),
                      Text(
                        AppStrings.get('noAlerts', lang),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.space16),
                  itemCount: alertItems.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.space12),
                  itemBuilder: (context, index) {
                    final item = alertItems[index];
                    final alert = item['alert'] as OutbreakAlert;
                    final dist = item['minDistance'] as double;
                    final pondName = item['nearestPond'] as String;

                    final isVeryClose = dist <= 5.0;
                    final badgeColor =
                        isVeryClose ? AppTokens.riskHigh : AppTokens.riskMedium;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isVeryClose
                                      ? Icons.error_outline
                                      : Icons.warning_amber_outlined,
                                  color: badgeColor,
                                  size: 22,
                                ),
                                const SizedBox(width: AppTokens.space8),
                                Expanded(
                                  child: Text(
                                    AppStrings.get('nearbyAlert', lang),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.space12),
                            const Divider(),
                            const SizedBox(height: AppTokens.space12),
                            if (pondName.isNotEmpty) ...[
                              Text(
                                '${dist.toStringAsFixed(1)} km from $pondName',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTokens.space4),
                            ],
                            Text(
                              '${alert.uniqueReporters} independent farm reports within 3 km',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppTokens.space8),
                            Wrap(
                              spacing: AppTokens.space8,
                              runSpacing: AppTokens.space4,
                              children: alert.symptoms.map((symptomKey) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.space8,
                                    vertical: AppTokens.space4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTokens.background,
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.controlRadius,
                                    ),
                                    border: Border.all(color: AppTokens.border),
                                  ),
                                  child: Text(
                                    _translateSymptom(symptomKey, lang),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTokens.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppTokens.space8),
                            Text(
                              'Detected: ${alert.detectedAt.day}/${alert.detectedAt.month}/${alert.detectedAt.year} ${alert.detectedAt.hour}:${alert.detectedAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _translateSymptom(String key, AppLanguage lang) {
    switch (key) {
      case 'lethargy':
        return AppStrings.get('symptomLethargy', lang);
      case 'surface_gasping':
        return AppStrings.get('symptomSurfaceGasping', lang);
      case 'white_spots':
        return AppStrings.get('symptomWhiteSpots', lang);
      case 'discoloured_water':
        return AppStrings.get('symptomDiscolouredWater', lang);
      case 'sudden_deaths':
        return AppStrings.get('symptomSuddenDeaths', lang);
      case 'reduced_feeding':
        return AppStrings.get('symptomReducedFeeding', lang);
      default:
        return key;
    }
  }
}
