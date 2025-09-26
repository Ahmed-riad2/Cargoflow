import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

Map<String, LatLng> predefinedPorts = {
  'Port Said': LatLng(31.2653, 32.3019),
  'Alexandria': LatLng(31.2001, 29.9187),
  'Suez': LatLng(29.9668, 32.5498),
  'Damietta': LatLng(31.4165, 31.8133),
};

class CustomMapWidget extends StatefulWidget {
  final MapController? mapController;
  final List<Marker>? markers;
  final bool isPicker;

  const CustomMapWidget({
    super.key,
    this.mapController,
    this.markers,
    this.isPicker = true,
  });

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _pickedLocation;
  String _pickedAddress = "اختر موقعًا جديدًا";
  List<LatLng> _routePoints = [];
  final List<Marker> _markers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPicker) {
      _checkLocationPermissionAndGetLocation();
    }
  }

  /// 1️⃣ الموقع الحالي للمستخدم
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خدمة الموقع غير مفعلة.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('صلاحية الموقع مرفوضة.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'صلاحية الموقع مرفوضة بشكل دائم، يرجى تفعيلها من إعدادات الجهاز.',
          ),
        ),
      );
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _pickedLocation = _currentLocation;
        _isLoading = false;
        _mapController.move(_currentLocation!, 15.0);
      });
      _getAddressFromLatLng(_currentLocation!);
      _updateMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحصول على الموقع الحالي: $e')),
      );
    }
  }

  /// 2️⃣ و 3️⃣ اختيار الموقع والـ Reverse Geocoding
  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
    });
    _getAddressFromLatLng(latlng);
    _updateMarkers();
    if (_currentLocation != null) {
      _getRouteLine(_currentLocation!, _pickedLocation!);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      Placemark place = placemarks.first;
      setState(() {
        _pickedAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _pickedAddress = "تعذر الحصول على العنوان";
      });
    }
  }

  /// 4️⃣ رسم الـ Route Line (Polyline)
  Future<void> _getRouteLine(LatLng start, LatLng end) async {
    setState(() {
      _isLoading = true;
    });
    const url = 'http://router.project-osrm.org/route/v1/driving/';
    final response = await http.get(
      Uri.parse(
        '$url${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final geometry = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = geometry
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _routePoints = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر الحصول على مسار.')));
    }
  }

  /// تحديث الـ Markers على الخريطة
  void _updateMarkers() {
    _markers.clear();
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Colors.blueAccent,
            size: 40,
          ),
        ),
      );
    }
    if (_pickedLocation != null) {
      _markers.add(
        Marker(
          point: _pickedLocation!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 40,
          ),
        ),
      );
    }
    // Add predefined ports markers
    for (var entry in predefinedPorts.entries) {
      _markers.add(
        Marker(
          point: entry.value,
          width: 50,
          height: 50,
          child: Tooltip(
            message: entry.key,
            child: const Icon(
              Icons.location_on,
              color: Colors.greenAccent,
              size: 40,
            ),
          ),
        ),
      );
    }
  }

  /// 5️⃣ Search Bar
  void _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final firstResult = data[0];
        final lat = double.parse(firstResult['lat']);
        final lon = double.parse(firstResult['lon']);
        final searchLocation = LatLng(lat, lon);

        setState(() {
          _pickedLocation = searchLocation;
        });
        _mapController.move(searchLocation, 15.0);
        _getAddressFromLatLng(searchLocation);
        _updateMarkers();
        if (_currentLocation != null) {
          _getRouteLine(_currentLocation!, _pickedLocation!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على نتائج.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: widget.isPicker ? _mapController : widget.mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? LatLng(30.0444, 31.2357),
        initialZoom: 10.0,
        onTap: widget.isPicker ? _handleTap : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.green,
                strokeWidth: 5.0,
              ),
            ],
          ),
        MarkerLayer(markers: widget.markers ?? _markers),
      ],
    );

    if (!widget.isPicker) {
      return FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? LatLng(30.0444, 31.2357),
          initialZoom: 6.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: widget.markers ?? []),
        ],
      );
    }

    // This is the picker UI
    return Scaffold(
      appBar: AppBar(title: const Text('اختر موقعًا')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentLocation ??
                  LatLng(30.0444, 31.2357), // Default to Cairo
              initialZoom: 10.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.green,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Search Bar, Address Box, Buttons, etc.
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          // ... other UI elements for the picker ...
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentLocation == null
                        ? null
                        : () {
                            _mapController.move(_currentLocation!, 15.0);
                          },
                    icon: const Icon(Icons.my_location),
                    label: const Text('موقعي الحالي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickedLocation == null
                        ? null
                        : () {
                            Navigator.pop(context, _pickedLocation);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('تأكيد الموقع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
