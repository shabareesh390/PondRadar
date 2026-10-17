import '../../models/outbreak_alert.dart';
import '../../models/symptom_report.dart';
import '../../config/config.dart';
import '../../services/location_service.dart';

class ClusteringEngine {
  /// Evaluates reports and identifies outbreak clusters meeting criteria:
  /// - Within [AppConfig.clusterTimeWindowHours] (48h)
  /// - Within [AppConfig.clusterRadiusKm] (3 km)
  /// - At least [AppConfig.minIndependentReporters] distinct reporters
  static List<OutbreakAlert> findClusters(
    List<SymptomReport> reports, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final cutoff =
        now.subtract(const Duration(hours: AppConfig.clusterTimeWindowHours));

    // 1. Filter reports within the 48h time window
    final recentReports =
        reports.where((r) => r.createdAt.isAfter(cutoff)).toList();

    if (recentReports.length < AppConfig.minIndependentReporters) {
      return [];
    }

    final Map<String, OutbreakAlert> candidateAlerts = {};

    // 2. Cluster around each report as an anchor
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

      // Check distinct reporters
      final uniqueReporters =
          neighbors.map((r) => r.reporterHash).toSet().length;

      if (uniqueReporters >= AppConfig.minIndependentReporters) {
        // Calculate cluster center
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

        // Generate deterministic ID using center grid + date
        final alertId = OutbreakAlert.generateDeterministicId(
          centerLat,
          centerLng,
          now,
        );

        final dateStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Candidate alert (if existing, update with max counts)
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
