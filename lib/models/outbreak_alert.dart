import 'dart:convert';
import 'package:crypto/crypto.dart';

class OutbreakAlert {
  final String id;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final int reportCount;
  final int uniqueReporters;
  final List<String> symptoms;
  final DateTime detectedAt;
  final String dateString;
  final bool isSimulated;

  const OutbreakAlert({
    required this.id,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.reportCount,
    required this.uniqueReporters,
    required this.symptoms,
    required this.detectedAt,
    required this.dateString,
    this.isSimulated = false,
  });

  /// Deterministic alert key based on ~2.2km regional grid and 48h active time window.
  /// Prevents slight centroid fluctuations and midnight boundaries from producing duplicate docs.
  static String generateDeterministicId(
    double lat,
    double lng,
    DateTime date,
  ) {
    // Snap to 0.02-degree (~2.2km) grid cell
    final gridLat = ((lat / 0.02).round() * 0.02);
    final gridLng = ((lng / 0.02).round() * 0.02);
    // Align with 48-hour active outbreak window instead of arbitrary midnight boundary
    final windowIndex = date.millisecondsSinceEpoch ~/ (48 * 3600 * 1000);
    final key =
        'alert_${gridLat.toStringAsFixed(2)}_${gridLng.toStringAsFixed(2)}_w$windowIndex';
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return 'alert_${digest.toString().substring(0, 16)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radiusKm': radiusKm,
      'reportCount': reportCount,
      'uniqueReporters': uniqueReporters,
      'symptoms': symptoms,
      'detectedAt': detectedAt.toIso8601String(),
      'dateString': dateString,
      'isSimulated': isSimulated,
    };
  }

  factory OutbreakAlert.fromMap(Map<String, dynamic> map, String docId) {
    return OutbreakAlert(
      id: docId,
      centerLat: (map['centerLat'] as num? ?? 0.0).toDouble(),
      centerLng: (map['centerLng'] as num? ?? 0.0).toDouble(),
      radiusKm: (map['radiusKm'] as num? ?? 3.0).toDouble(),
      reportCount: (map['reportCount'] as num? ?? 0).toInt(),
      uniqueReporters: (map['uniqueReporters'] as num? ?? 0).toInt(),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      detectedAt: DateTime.tryParse(map['detectedAt'] as String? ?? '') ??
          DateTime.now(),
      dateString: map['dateString'] as String? ?? '',
      isSimulated: map['isSimulated'] as bool? ?? false,
    );
  }
}
