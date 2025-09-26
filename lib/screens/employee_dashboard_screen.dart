import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:cargo_flow/services/firestore_service.dart';
import 'package:cargo_flow/screens/auth/login_screen.dart';
import 'package:cargo_flow/widgets/custom_map_widget.dart';
import 'package:flutter_map/flutter_map.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  String? selectedDriverForChat;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employee Dashboard'),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Orders'),
              Tab(text: 'Live Tracking'),
              Tab(text: 'Reports'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewOrdersTab(),
            _buildLiveTrackingTab(),
            _buildReportsTab(),
            _buildChatTab(),
          ],
        ),
      ),
    );
  }

  // ----------------- New Orders -----------------
  Widget _buildNewOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data!.docs.where((doc) {
          final order = doc.data() as Map<String, dynamic>;
          return order['status'] == 'Pending';
        }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('No new orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('Order: ${order['orderId']}'),
                subtitle: Text(
                  'Container: ${order['containerNumber'] ?? 'N/A'}',
                ),
                trailing: ElevatedButton(
                  onPressed: () => _showAssignDriverDialog(order['orderId']),
                  child: const Text('Assign Driver'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------- Live Tracking -----------------
  Widget _buildLiveTrackingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('driver_locations')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final markers = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final lat = data['latitude'] as double?;
              final lng = data['longitude'] as double?;
              if (lat != null && lng != null) {
                return Marker(
                  point: LatLng(lat, lng), // builder is deprecated, use child
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 40,
                  ),
                );
              }
              return null;
            })
            .whereType<Marker>()
            .toList();

        return CustomMapWidget(
          isPicker: false,
          mapController: _mapController,
          markers: markers,
        );
      },
    );
  }

  // ----------------- Reports -----------------
  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data!.docs;
        final statusCounts = <String, int>{};
        for (final doc in orders) {
          final order = doc.data() as Map<String, dynamic>;
          final status = order['status'] as String? ?? 'Unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: statusCounts.entries
              .map(
                (entry) =>
                    ListTile(title: Text('${entry.key}: ${entry.value}')),
              )
              .toList(),
        );
      },
    );
  }

  // ----------------- Chat -----------------
  Widget _buildChatTab() {
    if (selectedDriverForChat == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _selectDriverForChat,
          child: const Text('Start Chat with Driver'),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getChatStream(selectedDriverForChat!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final isEmployee = msg['sender'] == 'employee';
                  return Align(
                    alignment: isEmployee
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEmployee
                            ? Colors.blueAccent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['message'] ?? '',
                        style: TextStyle(
                          color: isEmployee ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    final TextEditingController controller = TextEditingController();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty || selectedDriverForChat == null) return;
                _firestoreService.sendMessage(selectedDriverForChat!, text);
                controller.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Helper Functions -----------------
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _showAssignDriverDialog(String orderId) {
    String? selectedDriver;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Driver'),
        content: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getAllDrivers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error loading drivers: ${snapshot.error}');
            }
            final drivers = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              items: drivers.map((doc) {
                final driver = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(driver['name'] ?? doc.id),
                );
              }).toList(),
              onChanged: (value) => selectedDriver = value,
              decoration: const InputDecoration(labelText: 'Select Driver'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedDriver == null) return;
              try {
                await _firestoreService.updateOrder(orderId, {
                  'driverId': selectedDriver,
                  'status': 'Assigned',
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver assigned successfully'),
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
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _selectDriverForChat() async {
    String? driverId;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Driver to Chat'),
        content: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getAllDrivers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final drivers = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              items: drivers.map((doc) {
                final driver = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(driver['name'] ?? doc.id),
                );
              }).toList(),
              onChanged: (value) => driverId = value,
              decoration: const InputDecoration(labelText: 'Select Driver'),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (driverId != null) {
      setState(() {
        selectedDriverForChat = driverId;
      });
    }
  }
}
