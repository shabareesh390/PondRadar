import 'package:flutter_test/flutter_test.dart';
import 'package:pondradar/features/alerts/clustering_engine.dart';
import 'package:pondradar/models/symptom_report.dart';

void main() {
  group('Deterministic Outbreak Clustering Engine Unit Tests', () {
    final now = DateTime(2026, 10, 17, 12, 0);

    // Coastal Karnataka test baseline (near Udupi, ~13.3400, 74.7400)
    const baseLat = 13.3400;
    const baseLng = 74.7400;

    test('Below threshold (only 2 distinct reporters) produces NO alert', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['white_spots'],
          latitude: baseLat,
          longitude: baseLng,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_beta',
          symptoms: ['white_spots'],
          latitude: baseLat + 0.005, // ~550m away
          longitude: baseLng + 0.005,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ];

      final clusters = ClusteringEngine.findClusters(reports, referenceTime: now);
      expect(clusters.isEmpty, true);
    });

    test('3 reports from SAME user produces NO alert (min 3 independent reporters required)', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['surface_gasping'],
          latitude: baseLat,
          longitude: baseLng,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_alpha',
          symptoms: ['surface_gasping'],
          latitude: baseLat + 0.002,
          longitude: baseLng + 0.002,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SymptomReport(
          id: 'r3',
          reporterHash: 'rep_alpha',
          symptoms: ['surface_gasping'],
          latitude: baseLat + 0.003,
          longitude: baseLng + 0.003,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];

      final clusters = ClusteringEngine.findClusters(reports, referenceTime: now);
      expect(clusters.isEmpty, true);
    });

    test('Meets threshold (3 independent reporters within 3 km and 48h) produces ONE alert', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['white_spots', 'lethargy'],
          latitude: baseLat,
          longitude: baseLng,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_beta',
          symptoms: ['white_spots'],
          latitude: baseLat + 0.008, // ~900m
          longitude: baseLng + 0.008,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        SymptomReport(
          id: 'r3',
          reporterHash: 'rep_gamma',
          symptoms: ['white_spots', 'sudden_deaths'],
          latitude: baseLat + 0.012, // ~1.3km
          longitude: baseLng + 0.010,
          createdAt: now.subtract(const Duration(hours: 10)),
        ),
      ];

      final clusters = ClusteringEngine.findClusters(reports, referenceTime: now);
      expect(clusters.length, 1);
      final alert = clusters.first;
      expect(alert.uniqueReporters, 3);
      expect(alert.reportCount, 3);
      expect(alert.symptoms.contains('white_spots'), true);
      expect(alert.symptoms.contains('lethargy'), true);
      expect(alert.symptoms.contains('sudden_deaths'), true);
      expect(alert.id.startsWith('alert_'), true);
    });

    test('Duplicates ignored: same reports evaluated twice produce identical deterministic ID', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['white_spots'],
          latitude: baseLat,
          longitude: baseLng,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_beta',
          symptoms: ['white_spots'],
          latitude: baseLat + 0.005,
          longitude: baseLng + 0.005,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SymptomReport(
          id: 'r3',
          reporterHash: 'rep_gamma',
          symptoms: ['white_spots'],
          latitude: baseLat + 0.008,
          longitude: baseLng + 0.008,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];

      final run1 = ClusteringEngine.findClusters(reports, referenceTime: now);
      final run2 = ClusteringEngine.findClusters(reports, referenceTime: now);

      expect(run1.length, 1);
      expect(run2.length, 1);
      expect(run1.first.id, run2.first.id);
    });

    test('Reports separated by > 3 km do NOT cluster together', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['discoloured_water'],
          latitude: 13.3400, // Udupi
          longitude: 74.7400,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_beta',
          symptoms: ['discoloured_water'],
          latitude: 13.6200, // Kundapura (~31 km away)
          longitude: 74.6900,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        SymptomReport(
          id: 'r3',
          reporterHash: 'rep_gamma',
          symptoms: ['discoloured_water'],
          latitude: 12.9100, // Mangalore (~48 km away)
          longitude: 74.8500,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ];

      final clusters = ClusteringEngine.findClusters(reports, referenceTime: now);
      expect(clusters.isEmpty, true);
    });

    test('Reports outside the 48-hour window are excluded', () {
      final reports = [
        SymptomReport(
          id: 'r1',
          reporterHash: 'rep_alpha',
          symptoms: ['lethargy'],
          latitude: baseLat,
          longitude: baseLng,
          createdAt: now.subtract(const Duration(hours: 50)), // Stale > 48h
        ),
        SymptomReport(
          id: 'r2',
          reporterHash: 'rep_beta',
          symptoms: ['lethargy'],
          latitude: baseLat + 0.002,
          longitude: baseLng + 0.002,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        SymptomReport(
          id: 'r3',
          reporterHash: 'rep_gamma',
          symptoms: ['lethargy'],
          latitude: baseLat + 0.003,
          longitude: baseLng + 0.003,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

      final clusters = ClusteringEngine.findClusters(reports, referenceTime: now);
      expect(clusters.isEmpty, true);
    });
  });
}
