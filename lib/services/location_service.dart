import 'package:geolocator/geolocator.dart';

/// Service for obtaining the device's GPS location.
///
/// Handles permission requests and provides a safe fallback to default
/// coordinates (Dhaka, Bangladesh) when location data is unavailable.
class LocationService {
  /// Default latitude for Dhaka, Bangladesh.
  static const double _defaultLatitude = 23.8103;

  /// Default longitude for Dhaka, Bangladesh.
  static const double _defaultLongitude = 90.4125;

  /// Retrieves the device's current GPS position.
  ///
  /// Automatically checks if location services are enabled and requests
  /// permissions when necessary. Throws a descriptive exception if
  /// services are disabled or permissions are permanently denied.
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are disabled. Please enable them in settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permission was denied. M Call needs location access '
          'to calculate accurate prayer times.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission is permanently denied. Please enable it '
        'from app settings to use prayer-time features.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Returns the last known position, or falls back to default Dhaka
  /// coordinates if no cached position is available.
  ///
  /// This method never throws — it is safe to call when you need a
  /// best-effort location quickly without user interaction.
  Future<Position> getLastKnownOrDefault() async {
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
    } catch (_) {
      // Silently fall through to default coordinates.
    }

    // Return a synthetic Position with default Dhaka coordinates.
    return Position(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

/// Exception thrown when location services or permissions are unavailable.
class LocationServiceException implements Exception {
  /// Human-readable description of the error.
  final String message;

  /// Creates a [LocationServiceException] with the given [message].
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
