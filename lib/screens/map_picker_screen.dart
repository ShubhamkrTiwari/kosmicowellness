import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentCenter = const LatLng(28.6139, 77.2090); // Default to New Delhi
  bool _isLoading = false;
  String _currentAddress = "Drag to select location";
  
  List<dynamic> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _fetchSuggestions(query);
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final String encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1&countrycodes=in'),
        headers: {'User-Agent': 'KosmicoApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && mounted) {
          setState(() {
            _suggestions = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Suggestion error: $e");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty || query.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a more specific location name.')),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    // On Web, use Nominatim API as geocoding package doesn't support Web
    if (kIsWeb) {
      try {
        final String encodedQuery = Uri.encodeComponent(query);
        final response = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1&countrycodes=in'),
          headers: {'User-Agent': 'KosmicoApp/1.0'},
        );
        
        if (response.statusCode == 200) {
          final dynamic data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final lat = double.tryParse(data[0]['lat']?.toString() ?? '') ?? 0.0;
            final lon = double.tryParse(data[0]['lon']?.toString() ?? '') ?? 0.0;
            final target = LatLng(lat, lon);
            
            setState(() {
              _currentCenter = target;
              _currentAddress = data[0]['display_name'] ?? 'Location found';
            });
            _mapController.move(target, 15);
          } else {
            throw Exception('No results found');
          }
        } else {
          throw Exception('Failed to search location');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    try {
      String searchInput = query;
      if (!query.toLowerCase().contains("india")) {
        searchInput = "$query, India";
      }
      final locations = await Geocoding().locationFromAddress(searchInput);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final LatLng target = LatLng(loc.latitude, loc.longitude);
        
        setState(() {
          _currentCenter = target;
        });
        _mapController.move(target, 15);
        _getAddressFromLatLng(target);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found. Try adding city or state.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains("Unexpected null value")) {
        errorMsg = "The location service is currently unavailable. Please try again or search with a city name.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentCenter, 15);
      });
      _getAddressFromLatLng(_currentCenter);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentCenter = position.center;
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kosmico.wellness',
              ),
            ],
          ),

          // Search Bar & Suggestions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search area, building, or city...",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _searchLocation(value);
                      setState(() => _suggestions = []);
                    },
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final dynamic item = _suggestions[index];
                        if (item is! Map) return const SizedBox.shrink();
                        return ListTile(
                          leading: Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 20),
                          title: Text(
                            item['display_name']?.toString() ?? 'Unknown Location',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            final dynamic latVal = item['lat'];
                            final dynamic lonVal = item['lon'];
                            if (latVal != null && lonVal != null) {
                              final double lat = double.tryParse(latVal.toString()) ?? 0.0;
                              final double lon = double.tryParse(lonVal.toString()) ?? 0.0;
                              final target = LatLng(lat, lon);
                              
                              setState(() {
                                _currentCenter = target;
                                _suggestions = [];
                                _searchController.text = item['display_name']?.toString() ?? '';
                              });
                              _mapController.move(target, 15);
                              _getAddressFromLatLng(target);
                              FocusScope.of(context).unfocus();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Fixed Center Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25), // Half of icon size to align tip to center
              child: Icon(
                Icons.location_on,
                size: 50,
                color: colorScheme.primary,
              ),
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Floating Action Button for Current Location
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton(
                      onPressed: _determinePosition,
                      backgroundColor: colorScheme.surface,
                      child: Icon(Icons.my_location, color: colorScheme.primary),
                    ),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Confirm Delivery Location",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAddress,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            try {
                              final parsed = await LocationService.getParsedAddress(
                                _currentCenter.latitude,
                                _currentCenter.longitude,
                              );
                              if (context.mounted) {
                                Navigator.pop(context, {
                                  'lat': _currentCenter.latitude,
                                  'lng': _currentCenter.longitude,
                                  'street': parsed.street.isNotEmpty ? parsed.street : _currentAddress,
                                  'city': parsed.city,
                                  'pincode': parsed.pincode,
                                  'state': parsed.state,
                                  'address': parsed.fullAddress.isNotEmpty ? parsed.fullAddress : _currentAddress,
                                  'placemark': parsed.placemark,
                                });
                              }
                            } catch (e) {
                              debugPrint("Confirm location parsing error: $e");
                              if (context.mounted) {
                                final fallback = LocationService.parseAddressText(_currentAddress);
                                Navigator.pop(context, {
                                  'lat': _currentCenter.latitude,
                                  'lng': _currentCenter.longitude,
                                  'street': (fallback['street']?.isNotEmpty == true) ? fallback['street'] : _currentAddress,
                                  'city': fallback['city'] ?? '',
                                  'pincode': fallback['pincode'] ?? '',
                                  'state': fallback['state'] ?? '',
                                  'address': _currentAddress,
                                });
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Confirm Location", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
