import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../config/thresholds.dart';
import '../features/alerts/clustering_engine.dart';
import '../models/outbreak_alert.dart';
import '../models/pond.dart';
import '../models/symptom_report.dart';
import 'location_service.dart';

class FirestoreService {
  final FirebaseFirestore? _customFirestore;

  FirestoreService([FirebaseFirestore? firestore]) : _customFirestore = firestore {
    _enableOfflinePersistence();
  }

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  void _enableOfflinePersistence() {
    try {
      _firestore?.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore persistence notice: $e');
    }
  }

  // ===================== PONDS =====================

  Stream<List<Pond>> getPondsStream(String userId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('ponds')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pond.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<String> addPond({
    required String userId,
    required String name,
    required String species,
    required double latitude,
    required double longitude,
  }) async {
    if (_firestore == null) return 'local_pond_id';
    final docRef = await _firestore!.collection('ponds').add({
      'userId': userId,
      'name': name,
      'species': species,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': DateTime.now().toIso8601String(),
      'lastRisk': null,
      'lastEvaluation': null,
    });
    return docRef.id;
  }

  Future<void> updatePondWaterEvaluation({
    required String pondId,
    required WaterRiskEvaluation evaluation,
  }) async {
    if (_firestore == null) return;
    // 1. Update latest evaluation summary on the pond
    await _firestore!.collection('ponds').doc(pondId).update({
      'lastRisk': evaluation.overallRisk.name,
      'lastEvaluation': evaluation.toMap(),
    });

    // 2. Save historical reading for trend analysis
    await _firestore!
        .collection('ponds')
        .doc(pondId)
        .collection('water_readings')
        .add(evaluation.toMap());
  }

  Stream<List<WaterRiskEvaluation>> getPondHistoryStream(String pondId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('ponds')
        .doc(pondId)
        .collection('water_readings')
        .orderBy('evaluatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WaterRiskEvaluation.fromMap(doc.data());
      }).toList();
    });
  }

  // ===================== SYMPTOM REPORTS =====================

  /// Submits a symptom report.
  /// Writes a fuzzed public copy for clustering and an exact private copy for officer verification.
  Future<void> submitSymptomReport({
    required String userId,
    String? pondId,
    required List<String> symptoms,
    String? photoBase64,
    required double exactLatitude,
    required double exactLongitude,
    bool isSimulated = false,
  }) async {
    final now = DateTime.now();
    final reporterHash = SymptomReport.hashUserId(userId);
    final blurredCoords = LocationService.blurCoordinatesTo500m(
      exactLatitude,
      exactLongitude,
    );

    if (_firestore == null) return;

    // 1. Write public report (500m snapped, salted reporter hash)
    final publicDocRef = _firestore!.collection('reports_public').doc();
    final publicData = {
      'reporterHash': reporterHash,
      'symptoms': symptoms,
      'latitude': blurredCoords['latitude'],
      'longitude': blurredCoords['longitude'],
      'createdAt': now.toIso8601String(),
      'isSimulated': isSimulated,
      'hasPhoto': photoBase64 != null && photoBase64.isNotEmpty,
    };
    await publicDocRef.set(publicData);

    // 2. Write private report (same doc ID for direct officer lookup)
    final privateData = {
      'userId': userId,
      'pondId': pondId,
      'reporterHash': reporterHash,
      'symptoms': symptoms,
      'photo': photoBase64,
      'exactLatitude': exactLatitude,
      'exactLongitude': exactLongitude,
      'createdAt': now.toIso8601String(),
      'isSimulated': isSimulated,
    };
    await _firestore!
        .collection('reports_private')
        .doc(publicDocRef.id)
        .set(privateData);

    // 3. Evaluate clustering client-side
    await _evaluateAndWriteAlerts();
  }

  /// Runs clustering over recent public reports and persists alerts.
  Future<void> _evaluateAndWriteAlerts() async {
    if (_firestore == null) return;
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: AppConfig.clusterTimeWindowHours));
      final snapshot = await _firestore!
          .collection('reports_public')
          .where('createdAt', isGreaterThan: cutoff.toIso8601String())
          .get();

      final publicReports = snapshot.docs.map((doc) {
        return SymptomReport.fromPublicDoc(doc.data(), doc.id);
      }).toList();

      final clusters = ClusteringEngine.findClusters(publicReports);

      for (final cluster in clusters) {
        // Use deterministic ID with set-merge to avoid duplicate cluster docs
        await _firestore!
            .collection('alerts')
            .doc(cluster.id)
            .set(cluster.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Clustering evaluation error: $e');
    }
  }

  // ===================== ALERTS =====================

  Stream<List<OutbreakAlert>> getAlertsStream() {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('alerts')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OutbreakAlert.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<SymptomReport>> getPublicReportsStream() {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('reports_public')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SymptomReport.fromPublicDoc(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<SymptomReport>> getPrivateReportsStream() {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('reports_private')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SymptomReport.fromPrivateDoc(doc.data(), doc.id);
      }).toList();
    });
  }

  // ===================== DEMO & SIMULATION =====================

  /// Checks whether simulated demo reports currently exist.
  Stream<bool> hasSimulatedDataStream() {
    if (_firestore == null) return Stream.value(false);
    return _firestore!
        .collection('reports_public')
        .where('isSimulated', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  /// Seeds ~40 realistic demo reports across coastal Karnataka aquaculture hubs.
  Future<void> loadDemoData(String currentUserId) async {
    final now = DateTime.now();

    // Coastal Karnataka hubs:
    // Cluster A: Kundapura (13.628, 74.691) - severe white spots & sudden deaths
    // Cluster B: Udupi Malpe (13.351, 74.704) - surface gasping & discoloured water
    // Cluster C: Kaup (13.220, 74.743) - lethargy & reduced feeding
    // Scattered isolated reports: Padubidri, Mangalore

    final demoClusters = [
      {
        'name': 'Kundapura',
        'lat': 13.628,
        'lng': 74.691,
        'count': 16,
        'symptoms': ['white_spots', 'sudden_deaths', 'lethargy'],
      },
      {
        'name': 'Udupi Malpe',
        'lat': 13.351,
        'lng': 74.704,
        'count': 14,
        'symptoms': ['surface_gasping', 'discoloured_water'],
      },
      {
        'name': 'Kaup',
        'lat': 13.220,
        'lng': 74.743,
        'count': 8,
        'symptoms': ['lethargy', 'reduced_feeding'],
      },
      {
        'name': 'Mangalore',
        'lat': 12.914,
        'lng': 74.856,
        'count': 2,
        'symptoms': ['reduced_feeding'],
      },
    ];

    if (_firestore == null) return;
    final batch = _firestore!.batch();

    int reporterIndex = 1;
    for (final cluster in demoClusters) {
      final baseLat = cluster['lat'] as double;
      final baseLng = cluster['lng'] as double;
      final count = cluster['count'] as int;
      final symptoms = cluster['symptoms'] as List<String>;

      for (int i = 0; i < count; i++) {
        final simUserId = 'demo_farmer_${reporterIndex++}';
        final offsetLat = ((i % 5) - 2) * 0.004; // within ~1-2km
        final offsetLng = (((i ~/ 5) % 5) - 2) * 0.004;
        final exactLat = baseLat + offsetLat;
        final exactLng = baseLng + offsetLng;
        final blurred = LocationService.blurCoordinatesTo500m(exactLat, exactLng);
        final reportTime = now.subtract(Duration(hours: (i * 2) % 40));

        final pubRef = _firestore!.collection('reports_public').doc();
        batch.set(pubRef, {
          'reporterHash': SymptomReport.hashUserId(simUserId),
          'symptoms': symptoms,
          'latitude': blurred['latitude'],
          'longitude': blurred['longitude'],
          'createdAt': reportTime.toIso8601String(),
          'isSimulated': true,
          'hasPhoto': false,
        });

        final privRef = _firestore!.collection('reports_private').doc(pubRef.id);
        batch.set(privRef, {
          'userId': simUserId,
          'pondId': 'demo_pond_$reporterIndex',
          'reporterHash': SymptomReport.hashUserId(simUserId),
          'symptoms': symptoms,
          'photo': null,
          'exactLatitude': exactLat,
          'exactLongitude': exactLng,
          'createdAt': reportTime.toIso8601String(),
          'isSimulated': true,
        });
      }
    }

    // Sample pond with borderline readings for testing UI alerts
    final samplePondRef = _firestore!.collection('ponds').doc('demo_pond_udupi');
    batch.set(samplePondRef, {
      'userId': currentUserId,
      'name': 'Pond 1 - Udupi Coastal',
      'species': 'Shrimp (Vannamei)',
      'latitude': 13.349,
      'longitude': 74.708,
      'createdAt': now.toIso8601String(),
      'lastRisk': WaterRiskLevel.medium.name,
      'lastEvaluation': {
        'overallRisk': WaterRiskLevel.medium.name,
        'evaluatedAt': now.toIso8601String(),
        'actionNoteEn':
            'Caution: Dissolved oxygen is borderline (3.8 mg/L). Monitor aerators and retest in 6 hours.',
        'actionNoteKn':
            'ಎಚ್ಚರಿಕೆ: ಕರಗಿದ ಆಮ್ಲಜನಕ ಕಡಿಮೆ ಮಟ್ಟದಲ್ಲಿದೆ (3.8 mg/L). ಏರೇಟರ್ ಗಮನಿಸಿ ಮತ್ತು 6 ಗಂಟೆಗಳಲ್ಲಿ ಮತ್ತೆ ಪರೀಕ್ಷಿಸಿ.',
        'parameters': [
          {
            'key': 'ph',
            'value': 7.9,
            'unit': '',
            'risk': 'low',
            'reasonEn': 'pH is optimal (7.5 - 8.5)',
            'reasonKn': 'ಪಿಹೆಚ್ ಸಮತೋಲನದಲ್ಲಿದೆ (7.5 - 8.5)',
          },
          {
            'key': 'dissolvedOxygen',
            'value': 3.8,
            'unit': 'mg/L',
            'risk': 'medium',
            'reasonEn': 'Dissolved oxygen is borderline (3.0 - 4.0 mg/L)',
            'reasonKn': 'ಕರಗಿದ ಆಮ್ಲಜನಕ ಕಡಿಮೆ ಮಟ್ಟದಲ್ಲಿದೆ (3.0 - 4.0 mg/L)',
          },
          {
            'key': 'ammonia',
            'value': 0.08,
            'unit': 'mg/L',
            'risk': 'low',
            'reasonEn': 'Ammonia is within safe range (<= 0.1 mg/L)',
            'reasonKn': 'ಅಮೋನಿಯಾ ಸುರಕ್ಷಿತ ಮಿತಿಯಲ್ಲಿದೆ (<= 0.1 mg/L)',
          },
          {
            'key': 'temperature',
            'value': 29.5,
            'unit': '°C',
            'risk': 'low',
            'reasonEn': 'Temperature is optimal (26 - 32 C)',
            'reasonKn': 'ತಾಪಮಾನ ಸೂಕ್ತವಾಗಿದೆ (26 - 32 C)',
          },
        ],
      },
    });

    await batch.commit();
    await _evaluateAndWriteAlerts();
  }

  /// Simulates an active outbreak by generating 3 reports close together.
  Future<void> simulateOutbreak({
    required double nearLat,
    required double nearLng,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now();
    final batch = _firestore!.batch();

    final distinctUsers = [
      'sim_user_karavali_1',
      'sim_user_karavali_2',
      'sim_user_karavali_3',
    ];

    for (int i = 0; i < distinctUsers.length; i++) {
      final simUserId = distinctUsers[i];
      final exactLat = nearLat + (i * 0.003); // within ~400m
      final exactLng = nearLng + (i * 0.003);
      final blurred = LocationService.blurCoordinatesTo500m(exactLat, exactLng);

      final pubRef = _firestore!.collection('reports_public').doc();
      batch.set(pubRef, {
        'reporterHash': SymptomReport.hashUserId(simUserId),
        'symptoms': ['white_spots', 'sudden_deaths'],
        'latitude': blurred['latitude'],
        'longitude': blurred['longitude'],
        'createdAt': now.toIso8601String(),
        'isSimulated': true,
        'hasPhoto': false,
      });

      final privRef = _firestore!.collection('reports_private').doc(pubRef.id);
      batch.set(privRef, {
        'userId': simUserId,
        'pondId': 'sim_pond_$i',
        'reporterHash': SymptomReport.hashUserId(simUserId),
        'symptoms': ['white_spots', 'sudden_deaths'],
        'photo': null,
        'exactLatitude': exactLat,
        'exactLongitude': exactLng,
        'createdAt': now.toIso8601String(),
        'isSimulated': true,
      });
    }

    await batch.commit();
    await _evaluateAndWriteAlerts();
  }

  /// Clears all simulated demo reports, alerts, and demo ponds in chunks.
  Future<void> clearDemoData() async {
    if (_firestore == null) return;

    final pubSnap = await _firestore!
        .collection('reports_public')
        .where('isSimulated', isEqualTo: true)
        .get();

    final alertsSnap = await _firestore!
        .collection('alerts')
        .where('isSimulated', isEqualTo: true)
        .get();

    // Delete in safe chunks of 400 to prevent exceeding Firestore 500 batch limit
    const int maxBatchOps = 400;
    WriteBatch batch = _firestore!.batch();
    int opCount = 0;

    Future<void> commitIfBatchFull() async {
      if (opCount >= maxBatchOps) {
        await batch.commit();
        batch = _firestore!.batch();
        opCount = 0;
      }
    }

    for (final doc in pubSnap.docs) {
      batch.delete(doc.reference);
      batch.delete(_firestore!.collection('reports_private').doc(doc.id));
      opCount += 2;
      await commitIfBatchFull();
    }

    for (final doc in alertsSnap.docs) {
      batch.delete(doc.reference);
      opCount += 1;
      await commitIfBatchFull();
    }

    // Clean up demo pond if present
    final demoPondRef = _firestore!.collection('ponds').doc('demo_pond_udupi');
    batch.delete(demoPondRef);
    opCount += 1;

    if (opCount > 0) {
      await batch.commit();
    }
  }
}
