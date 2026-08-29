import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  /// Checks whether GPS/Location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request and verify location permissions.
  /// Throws descriptive exceptions in case permissions are denied.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation (GPS) sont désactivés.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('L\'accès à la localisation a été refusé.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'L\'accès à la localisation est refusé de façon permanente. Veuillez l\'activer dans les réglages de l\'appareil.',
      );
    }

    return true;
  }

  /// Open device app settings if permission was permanently denied
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings to enable GPS
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Determine the current position of the device with timeout and fallback.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    await checkAndRequestPermission();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } catch (_) {
      // Fallback: try last known position or medium accuracy if high accuracy timed out
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    }
  }

  /// Real-time position update stream
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    int intervalDurationSeconds = 10,
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: Duration(seconds: intervalDurationSeconds),
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance in meters between two geographical coordinates
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Formats distance in meters to a human-readable string (m or km)
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}

