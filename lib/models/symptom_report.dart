import 'dart:convert';
import 'package:crypto/crypto.dart';

class SymptomReport {
  final String id;
  final String? userId; // Present in private report, omitted from public cluster views
  final String reporterHash; // Salted pseudonym used for public cluster analysis
  final String? pondId;
  final List<String> symptoms;
  final String? photoBase64OrUrl;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isSimulated;

  const SymptomReport({
    required this.id,
    this.userId,
    required this.reporterHash,
    this.pondId,
    required this.symptoms,
    this.photoBase64OrUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isSimulated = false,
  });

  /// Generates a salted pseudonym so reports can be clustered without exposing farmer identity.
  static String hashUserId(String userId) {
    const salt = 'pondradar_salt_udupi_2026';
    final bytes = utf8.encode('$userId:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Sanitized payload for public cluster feeds (fuzzed location, anonymized reporter).
  Map<String, dynamic> toPublicMap() {
    return {
      'reporterHash': reporterHash,
      'symptoms': symptoms,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isSimulated': isSimulated,
      'hasPhoto': photoBase64OrUrl != null && photoBase64OrUrl!.isNotEmpty,
    };
  }

  /// Full payload for the farmer's private record (exact GPS and actual user ID).
  Map<String, dynamic> toPrivateMap({
    required double exactLat,
    required double exactLng,
    required String actualUserId,
  }) {
    return {
      'userId': actualUserId,
      'pondId': pondId,
      'reporterHash': reporterHash,
      'symptoms': symptoms,
      'photo': photoBase64OrUrl,
      'exactLatitude': exactLat,
      'exactLongitude': exactLng,
      'createdAt': createdAt.toIso8601String(),
      'isSimulated': isSimulated,
    };
  }

  factory SymptomReport.fromPublicDoc(
    Map<String, dynamic> map,
    String docId,
  ) {
    return SymptomReport(
      id: docId,
      reporterHash: map['reporterHash'] as String? ?? 'anon',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      photoBase64OrUrl: null,
      latitude: (map['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isSimulated: map['isSimulated'] as bool? ?? false,
    );
  }

  factory SymptomReport.fromPrivateDoc(
    Map<String, dynamic> map,
    String docId,
  ) {
    return SymptomReport(
      id: docId,
      userId: map['userId'] as String?,
      reporterHash: map['reporterHash'] as String? ?? 'anon',
      pondId: map['pondId'] as String?,
      symptoms: List<String>.from(map['symptoms'] ?? []),
      photoBase64OrUrl: map['photo'] as String?,
      latitude: (map['exactLatitude'] as num? ?? 0.0).toDouble(),
      longitude: (map['exactLongitude'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isSimulated: map['isSimulated'] as bool? ?? false,
    );
  }
}
