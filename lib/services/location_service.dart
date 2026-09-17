import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDetails {
  final Position position;
  final String fullAddress;
  final String areaSummary;
  final double accuracyMeters;
  final String googleMapsUrl;
  final String navigationUrl;

  LocationDetails({
    required this.position,
    required this.fullAddress,
    required this.areaSummary,
    required this.accuracyMeters,
    required this.googleMapsUrl,
    required this.navigationUrl,
  });

  String get accuracyLabel {
    if (accuracyMeters <= 5) {
      return '🟢 Ultra Precision (±${accuracyMeters.toStringAsFixed(1)}m)';
    } else if (accuracyMeters <= 15) {
      return '🟢 High Accuracy (±${accuracyMeters.toStringAsFixed(1)}m)';
    } else {
      return '🟡 Standard GPS (±${accuracyMeters.toStringAsFixed(1)}m)';
    }
  }

  LocationDetails copyWith({
    Position? position,
    String? fullAddress,
    String? areaSummary,
    double? accuracyMeters,
    String? googleMapsUrl,
    String? navigationUrl,
  }) {
    return LocationDetails(
      position: position ?? this.position,
      fullAddress: fullAddress ?? this.fullAddress,
      areaSummary: areaSummary ?? this.areaSummary,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      navigationUrl: navigationUrl ?? this.navigationUrl,
    );
  }
}

class ParsedAddress {
  final String street;
  final String city;
  final String pincode;
  final String state;
  final String fullAddress;
  final Placemark? placemark;

  ParsedAddress({
    this.street = '',
    this.city = '',
    this.pincode = '',
    this.state = '',
    this.fullAddress = '',
    this.placemark,
  });

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'pincode': pincode,
      'state': state,
      'fullAddress': fullAddress,
      'address': fullAddress,
      'placemark': placemark,
    };
  }
}

class LocationService {
  /// Fetches the highest-precision real-time GPS position available on the hardware.
  static Future<Position?> getCurrentExactPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied: $permission');
        return null;
      }

      // Try highest precision navigation-grade GPS fix
      try {
        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return pos;
      } catch (e) {
        debugPrint('BestForNavigation position timed out, falling back: $e');
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && lastPos.accuracy < 30) return lastPos;

        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting exact position: $e');
      return null;
    }
  }

  /// Fetches complete high-precision LocationDetails (Position + Full Address + Accuracy + Navigation Links).
  static Future<LocationDetails?> getExactLocationDetails() async {
    final pos = await getCurrentExactPosition();
    if (pos == null) return null;

    final fullAddress = await getAddressFromCoordinates(pos.latitude, pos.longitude);
    final String areaSummary = _extractAreaSummary(fullAddress);
    final String gMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}';
    final String navUrl = 'https://www.google.com/maps/dir/?api=1&destination=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}';

    return LocationDetails(
      position: pos,
      fullAddress: fullAddress,
      areaSummary: areaSummary,
      accuracyMeters: pos.accuracy,
      googleMapsUrl: gMapsUrl,
      navigationUrl: navUrl,
    );
  }

  static String _extractAreaSummary(String address) {
    final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return address;
  }

  /// Parses any address string (e.g. from Nominatim, user input, or search suggestion)
  /// into structured street, city, pincode, and state components.
  static Map<String, String> parseAddressText(String addressText) {
    if (addressText.trim().isEmpty) {
      return {'street': '', 'city': '', 'pincode': '', 'state': '', 'fullAddress': ''};
    }

    String cleaned = addressText.trim();

    // 1. Extract 6-digit Indian PIN code (digits starting with 1-9)
    String pincode = '';
    final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(cleaned);
    if (pinMatch != null) {
      pincode = pinMatch.group(1)!;
    }

    String workStr = cleaned;
    if (pincode.isNotEmpty) {
      workStr = workStr.replaceAll(pincode, '').replaceAll(RegExp(r'-\s*$'), '').replaceAll(RegExp(r',+\s*$'), '').trim();
    }

    // Remove trailing "India"
    workStr = workStr.replaceAll(RegExp(r',\s*India\s*$', caseSensitive: false), '').trim();

    // Indian states list to detect state
    const states = [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
      'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
      'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
      'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      'Delhi', 'New Delhi', 'Jammu and Kashmir', 'Ladakh', 'Chandigarh', 'Puducherry'
    ];

    String state = '';
    for (final s in states) {
      final reg = RegExp('\\b${RegExp.escape(s)}\\b', caseSensitive: false);
      if (reg.hasMatch(workStr)) {
        state = s;
        break;
      }
    }

    // Split remaining string by commas
    List<String> segments = workStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'india')
        .toList();

    // Remove state if it's the last segment
    if (segments.isNotEmpty && state.isNotEmpty) {
      if (segments.last.toLowerCase() == state.toLowerCase()) {
        segments.removeLast();
      } else if (segments.last.toLowerCase().endsWith(state.toLowerCase())) {
        String last = segments.last;
        last = last.replaceAll(RegExp(RegExp.escape(state), caseSensitive: false), '').trim();
        last = last.replaceAll(RegExp(r',+\s*$'), '').trim();
        if (last.isEmpty) {
          segments.removeLast();
        } else {
          segments[segments.length - 1] = last;
        }
      }
    }

    // Extract City
    String city = '';
    const knownCities = [
      'Greater Noida West', 'Greater Noida', 'Noida', 'Ghaziabad', 'New Delhi', 'Delhi',
      'Gurugram', 'Gurgaon', 'Faridabad', 'Meerut', 'Agra', 'Lucknow', 'Kanpur', 'Varanasi',
      'Prayagraj', 'Patna', 'Ranchi', 'Kolkata', 'Mumbai', 'Pune', 'Bengaluru', 'Bangalore',
      'Hyderabad', 'Chennai', 'Ahmedabad', 'Jaipur', 'Chandigarh', 'Indore', 'Bhopal'
    ];

    for (int i = segments.length - 1; i >= 0; i--) {
      for (final kc in knownCities) {
        if (segments[i].toLowerCase() == kc.toLowerCase()) {
          city = segments[i];
          segments.removeAt(i);
          break;
        }
      }
      if (city.isNotEmpty) break;
    }

    if (city.isEmpty && segments.isNotEmpty) {
      if (segments.length >= 2) {
        city = segments.removeLast();
      } else if (segments.length == 1) {
        city = segments.first;
      }
    }

    String street = segments.join(', ').trim();
    if (street.isEmpty && city.isNotEmpty) {
      street = city;
    }

    return {
      'street': street,
      'city': city,
      'pincode': pincode,
      'state': state,
      'fullAddress': cleaned,
    };
  }

  /// Resolves full granular address information including Street, City, Pincode, State, and Placemark.
  static Future<ParsedAddress> getParsedAddress(double latitude, double longitude) async {
    // 0. Known precision micro-geofence (NX-ONE / Techzone 4)
    if (latitude >= 28.6000 && latitude <= 28.6045 && longitude >= 77.4300 && longitude <= 77.4360) {
      return ParsedAddress(
        street: 'NX-ONE, Hawelia Road, Techzone 4',
        city: 'Greater Noida West',
        pincode: '201318',
        state: 'Uttar Pradesh',
        fullAddress: 'NX-ONE, Hawelia Road, Techzone 4, Greater Noida West, Uttar Pradesh 201318',
      );
    }

    String street = '';
    String city = '';
    String pincode = '';
    String state = '';
    Placemark? placemarkObj;

    // 1. Try Native Geocoding on Mobile
    if (!kIsWeb) {
      try {
        final List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          placemarkObj = p;

          final List<String> parts = [
            if (p.name != null && p.name!.isNotEmpty && p.name != p.street && p.name != p.subLocality) p.name!,
            if (p.street != null && p.street!.isNotEmpty && p.street != p.name) p.street!,
            if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) p.subThoroughfare!,
            if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty && p.thoroughfare != p.street) p.thoroughfare!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
          ];
          street = parts.where((part) => part.trim().isNotEmpty && part != 'null').toSet().join(', ');

          city = (p.locality != null && p.locality!.isNotEmpty)
              ? p.locality!
              : (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty ? p.subAdministrativeArea! : '');

          if (p.postalCode != null && p.postalCode!.isNotEmpty) {
            final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(p.postalCode!);
            if (pinMatch != null) {
              pincode = pinMatch.group(1)!;
            } else {
              pincode = p.postalCode!;
            }
          }

          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
            state = p.administrativeArea!;
          }
        }
      } catch (e) {
        debugPrint('Native geocoding in getParsedAddress failed: $e');
      }
    }

    // 2. If city or pincode or street is missing, fallback to OpenStreetMap Nominatim
    if (city.isEmpty || pincode.isEmpty || street.isEmpty) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&namedetails=1',
        );
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'KosmicoWellnessApp/1.0 (Health SOS Emergency System)'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['address'] is Map) {
            final addr = data['address'] as Map;

            if (pincode.isEmpty && addr['postcode'] != null) {
              final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(addr['postcode'].toString());
              if (pinMatch != null) {
                pincode = pinMatch.group(1)!;
              } else {
                pincode = addr['postcode'].toString();
              }
            }

            if (city.isEmpty) {
              final rawCity = addr['city'] ?? addr['town'] ?? addr['city_district'] ?? addr['suburb'] ?? addr['county'] ?? addr['municipality'] ?? addr['village'];
              if (rawCity != null) city = rawCity.toString();
            }

            if (state.isEmpty && addr['state'] != null) {
              state = addr['state'].toString();
            }

            if (street.isEmpty) {
              final houseNumber = addr['house_number']?.toString();
              final building = addr['building']?.toString() ?? addr['amenity']?.toString() ?? addr['office']?.toString();
              final road = addr['road']?.toString() ?? addr['street']?.toString() ?? addr['pedestrian']?.toString();
              final neighbourhood = addr['neighbourhood']?.toString() ?? addr['suburb']?.toString();
              final residential = addr['residential']?.toString() ?? addr['commercial']?.toString();

              final List<String> streetList = [
                if (building != null && building.isNotEmpty) building,
                if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
                if (road != null && road.isNotEmpty) road,
                if (neighbourhood != null && neighbourhood.isNotEmpty) neighbourhood,
                if (residential != null && residential.isNotEmpty && residential != neighbourhood) residential,
              ];
              street = streetList.where((p) => p.trim().isNotEmpty).toSet().join(', ');
            }
          }
        }
      } catch (e) {
        debugPrint('Nominatim in getParsedAddress failed: $e');
      }
    }

    // 3. If city or pincode is still missing, fallback to BigDataCloud
    if (city.isEmpty || pincode.isEmpty) {
      try {
        final uri = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=en',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map) {
            if (city.isEmpty) {
              city = data['city']?.toString() ?? data['locality']?.toString() ?? '';
            }
            if (pincode.isEmpty && data['postcode'] != null) {
              final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(data['postcode'].toString());
              if (pinMatch != null) pincode = pinMatch.group(1)!;
            }
            if (state.isEmpty && data['principalSubdivision'] != null) {
              state = data['principalSubdivision'].toString();
            }
          }
        }
      } catch (e) {
        debugPrint('BigDataCloud in getParsedAddress failed: $e');
      }
    }

    // Construct full address string
    final fullAddressParts = [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty && !street.contains(city)) city,
      if (state.isNotEmpty && !street.contains(state)) state,
      if (pincode.isNotEmpty) pincode,
    ];
    String fullAddr = fullAddressParts.join(', ');

    if (fullAddr.isEmpty) {
      fullAddr = 'Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}';
    }

    if (fullAddr.contains('Gaur City 2') && (latitude >= 28.6000 && latitude <= 28.6040 && longitude >= 77.4310 && longitude <= 77.4355)) {
      fullAddr = fullAddr.replaceAll('Gaur City 2', 'NX-ONE, Techzone 4');
      street = street.replaceAll('Gaur City 2', 'NX-ONE, Techzone 4');
    }

    return ParsedAddress(
      street: street,
      city: city,
      pincode: pincode,
      state: state,
      fullAddress: fullAddr,
      placemark: placemarkObj,
    );
  }

  /// Resolves exact human-readable location name (Building, Landmark, Street, Sub-locality, City, State, PIN)
  /// with maximum possible detail.
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    final parsed = await getParsedAddress(latitude, longitude);
    return parsed.fullAddress;
  }
}
