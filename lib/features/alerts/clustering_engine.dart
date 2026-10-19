import '../../models/outbreak_alert.dart';
import '../../models/symptom_report.dart';
import '../../config/config.dart';
import '../../services/location_service.dart';

class ClusteringEngine {
  /// Evaluates symptom reports and identifies outbreak clusters meeting criteria:
  /// - Time window: within [AppConfig.clusterTimeWindowHours] (48h)
  /// - Spatial radius: within [AppConfig.clusterRadiusKm] (3 km)
  /// - Minimum independent reporters: at least [AppConfig.minIndependentReporters] distinct farmers
  static List<OutbreakAlert> findClusters(
    List<SymptomReport> reports, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final cutoff =
        now.subtract(const Duration(hours: AppConfig.clusterTimeWindowHours));

    // 1. Drop reports older than the active time window
    final recentReports =
        reports.where((r) => r.createdAt.isAfter(cutoff)).toList();

    if (recentReports.length < AppConfig.minIndependentReporters) {
      return [];
    }

    final Map<String, OutbreakAlert> candidateAlerts = {};

    // 2. Test each report as a potential cluster anchor
    for (final anchor in recentReports) {
      final List<SymptomReport> neighbors = [];

      for (final other in recentReports) {
        final dist = LocationService.haversineDistanceKm(
          anchor.latitude,
          anchor.longitude,
          other.latitude,
          other.longitude,
        );

        if (dist <= AppConfig.clusterRadiusKm) {
          neighbors.add(other);
        }
      }

      // Must have reports from separate farmers (not multiple submissions from one person)
      final uniqueReporters =
          neighbors.map((r) => r.reporterHash).toSet().length;

      if (uniqueReporters >= AppConfig.minIndependentReporters) {
        // Centroid of all neighboring points
        double sumLat = 0.0;
        double sumLng = 0.0;
        final Set<String> symptomSet = {};
        bool anySimulated = false;

        for (final n in neighbors) {
          sumLat += n.latitude;
          sumLng += n.longitude;
          symptomSet.addAll(n.symptoms);
          if (n.isSimulated) anySimulated = true;
        }

        final double centerLat = sumLat / neighbors.length;
        final double centerLng = sumLng / neighbors.length;

        // Bucket by day and ~1km grid cell to deduplicate candidate alerts
        final alertId = OutbreakAlert.generateDeterministicId(
          centerLat,
          centerLng,
          now,
        );

        final dateStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Keep the largest cluster candidate for this grid cell
        if (!candidateAlerts.containsKey(alertId) ||
            candidateAlerts[alertId]!.reportCount < neighbors.length) {
          candidateAlerts[alertId] = OutbreakAlert(
            id: alertId,
            centerLat: double.parse(centerLat.toStringAsFixed(5)),
            centerLng: double.parse(centerLng.toStringAsFixed(5)),
            radiusKm: AppConfig.clusterRadiusKm,
            reportCount: neighbors.length,
            uniqueReporters: uniqueReporters,
            symptoms: symptomSet.toList(),
            detectedAt: now,
            dateString: dateStr,
            isSimulated: anySimulated,
          );
        }
      }
    }

    return candidateAlerts.values.toList();
  }
}
