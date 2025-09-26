import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cargo_flow/services/firestore_service.dart';
import 'package:cargo_flow/screens/auth/login_screen.dart';
import 'package:flutter_map/flutter_map.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  final List<String> _statusOptions = ['Assigned', 'On the Way', 'Delivered'];
  LatLng? _driverPosition;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
      }
      return;
    }

    // Get the initial position to center the map quickly
    try {
      Position initialPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _driverPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
        });
      }
    } catch (e) {
      print("Error getting initial position: $e");
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          // Move map to the new position
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
          _firestoreService.saveDriverLocation(
            uid,
            position.latitude,
            position.longitude,
          );
          setState(() {
            _driverPosition = LatLng(position.latitude, position.longitude);
          });
        });
  }

  void _showUpdateStatusDialog(String orderId, String currentStatus) {
    String selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: DropdownButtonFormField<String>(
          initialValue: _statusOptions.contains(selectedStatus)
              ? selectedStatus
              : 'Assigned',
          items: _statusOptions.map((status) {
            return DropdownMenuItem(value: status, child: Text(status));
          }).toList(),
          onChanged: (value) => selectedStatus = value!,
          decoration: const InputDecoration(labelText: 'Status'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestoreService.updateOrder(orderId, {
                  'status': selectedStatus,
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getOrdersForDriver(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text('No assigned orders'));
          }

          final markers = <Marker>[];
          for (final doc in orders) {
            final order = doc.data() as Map<String, dynamic>;
            final pickupLat = order['pickupLat'] as double?;
            final pickupLng = order['pickupLng'] as double?;
            final dropLat = order['dropLat'] as double?;
            final dropLng = order['dropLng'] as double?;
            if (pickupLat != null && pickupLng != null) {
              markers.add(
                Marker(
                  point: LatLng(pickupLat, pickupLng),
                  child: const Icon(
                    Icons.warehouse,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              );
            }
            if (dropLat != null && dropLng != null) {
              markers.add(
                Marker(
                  point: LatLng(
                    dropLat,
                    dropLng,
                  ), // Use child instead of builder
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
            }
          }

          // Add driver's current location marker
          if (_driverPosition != null) {
            markers.add(
              Marker(
                point: _driverPosition!,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                flex: 1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text('Order: ${order['orderId']}'),
                        subtitle: Text('Status: ${order['status']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showUpdateStatusDialog(
                            order['orderId'],
                            order['status'],
                          ),
                          child: const Text('Update Status'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _driverPosition ?? const LatLng(30.0444, 31.2357),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
