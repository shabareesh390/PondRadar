import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/config.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isSimulatedOrFallback;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isSimulatedOrFallback,
  });
}

class LocationService {
  /// Requests current device GPS coordinates with fallback to coastal Karnataka center.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: AppConfig.defaultLat,
          longitude: AppConfig.defaultLng,
          isSimulatedOrFallback: true,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            latitude: AppConfig.defaultLat,
            longitude: AppConfig.defaultLng,
            isSimulatedOrFallback: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          latitude: AppConfig.defaultLat,
          longitude: AppConfig.defaultLng,
          isSimulatedOrFallback: true,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        isSimulatedOrFallback: false,
      );
    } catch (e) {
      debugPrint('Location lookup fallback: $e');
      return const LocationResult(
        latitude: AppConfig.defaultLat,
        longitude: AppConfig.defaultLng,
        isSimulatedOrFallback: true,
      );
    }
  }

  /// Snaps exact coordinates to a ~500m grid to protect farmer privacy in public cluster views.
  static Map<String, double> blurCoordinatesTo500m(
    double latitude,
    double longitude,
  ) {
    const double metersPerDegreeLat = 111320.0;
    final double latStep =
        AppConfig.publicLocationBlurGridMeters / metersPerDegreeLat;

    // Scale longitude step based on latitude
    final double radLat = latitude * (math.pi / 180.0);
    final double metersPerDegreeLng =
        metersPerDegreeLat * math.cos(radLat).abs();
    final double lngStep = AppConfig.publicLocationBlurGridMeters /
        (metersPerDegreeLng > 1000 ? metersPerDegreeLng : metersPerDegreeLat);

    final double blurredLat =
        (latitude / latStep).roundToDouble() * latStep;
    final double blurredLng =
        (longitude / lngStep).roundToDouble() * lngStep;

    return {
      'latitude': double.parse(blurredLat.toStringAsFixed(5)),
      'longitude': double.parse(blurredLng.toStringAsFixed(5)),
    };
  }

  /// Calculates Haversine distance between two coordinates in kilometers.
  static double haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
