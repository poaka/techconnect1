import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException([this.message = 'Les services de localisation (GPS) sont désactivés.']);
  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException([this.message = 'L\'accès à la localisation a été refusé.']);
  @override
  String toString() => message;
}

class LocationPermissionDeniedForeverException implements Exception {
  final String message;
  LocationPermissionDeniedForeverException([
    this.message = 'L\'accès à la localisation est refusé de façon permanente. Veuillez l\'activer dans les réglages.',
  ]);
  @override
  String toString() => message;
}

class LocationService {
  /// Checks whether GPS/Location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request and verify location permissions.
  /// Throws descriptive typed exceptions in case permissions are denied or disabled.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException();
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

  /// Determine the current position of the device with fast caching and multi-tier fallback.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 6),
  }) async {
    await checkAndRequestPermission();

    // 1. Fast check: Recent last known position (< 2 minutes old)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 2) {
          return lastKnown;
        }
      }
    } catch (_) {}

    // 2. Primary attempt with platform-optimized settings
    try {
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 1),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        );
      }

      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (_) {
      // 3. Fallback 1: Balanced accuracy (WiFi / Cell towers)
      try {
        LocationSettings fallbackSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          fallbackSettings = AndroidSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
            forceLocationManager: false,
          );
        } else {
          fallbackSettings = const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          );
        }
        return await Geolocator.getCurrentPosition(locationSettings: fallbackSettings);
      } catch (_) {
        // 4. Fallback 2: Any last known position
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) return lastKnown;
        } catch (_) {}

        // 5. Fallback 3: Native LocationManager (low accuracy)
        if (defaultTargetPlatform == TargetPlatform.android) {
          return await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 4),
              forceLocationManager: true,
            ),
          );
        }

        rethrow;
      }
    }
  }

  /// Real-time position update stream
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    int intervalDurationSeconds = 10,
  }) {
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: Duration(seconds: intervalDurationSeconds),
        forceLocationManager: false,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: Duration(seconds: intervalDurationSeconds),
      );
    }

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

