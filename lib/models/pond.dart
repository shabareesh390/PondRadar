import '../config/thresholds.dart';

class Pond {
  final String id;
  final String userId;
  final String name;
  final String species;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final WaterRiskLevel? lastRisk;
  final WaterRiskEvaluation? lastEvaluation;

  const Pond({
    required this.id,
    required this.userId,
    required this.name,
    this.species = 'Shrimp (Vannamei)',
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.lastRisk,
    this.lastEvaluation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'lastRisk': lastRisk?.name,
      'lastEvaluation': lastEvaluation?.toMap(),
    };
  }

  factory Pond.fromMap(Map<String, dynamic> map, String docId) {
    WaterRiskLevel? risk;
    if (map['lastRisk'] != null) {
      risk = WaterRiskLevel.values.firstWhere(
        (e) => e.name == map['lastRisk'],
        orElse: () => WaterRiskLevel.low,
      );
    }

    WaterRiskEvaluation? evaluation;
    if (map['lastEvaluation'] != null) {
      evaluation = WaterRiskEvaluation.fromMap(
        map['lastEvaluation'] as Map<String, dynamic>,
      );
    }

    return Pond(
      id: docId,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Pond',
      species: map['species'] as String? ?? 'Shrimp (Vannamei)',
      latitude: (map['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastRisk: risk,
      lastEvaluation: evaluation,
    );
  }
}
