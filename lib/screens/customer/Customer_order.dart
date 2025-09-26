import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cargo_flow/services/firestore_service.dart';
import 'package:cargo_flow/widgets/custom_map_widget.dart';



class CustomerOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const CustomerOrderDetailsPage({super.key, required this.orderId});

  @override
  State<CustomerOrderDetailsPage> createState() =>
      _CustomerOrderDetailsPageState();
}

class _CustomerOrderDetailsPageState extends State<CustomerOrderDetailsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? orderData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await _firestoreService.getOrderById(widget.orderId);
      setState(() {
        orderData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل بيانات الطلب: $e')),
      );
    }
  }

  Future<void> _editLocation(String key) async {
    // key = 'pickupLocation' أو 'dropLocation'
    LatLng? initialLocation;
    if (orderData != null &&
        orderData![key] != null &&
        orderData![key]['latitude'] != null &&
        orderData![key]['longitude'] != null) {
      initialLocation = LatLng(orderData![key]['latitude'],
          orderData![key]['longitude']);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomMapWidget(),
      ),
    );

    if (result != null && result is LatLng) {
      // تحديث الموقع في Firestore
      await _firestoreService.updateOrder(widget.orderId, {
        key: {'latitude': result.latitude, 'longitude': result.longitude}
      });
      // إعادة تحميل البيانات
      _loadOrder();
    }
  }

  Widget _buildInfoTile(String title, String? value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value ?? '-'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: const Color.fromARGB(255, 246, 246, 247),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderData == null
              ? const Center(child: Text('لا توجد بيانات لهذا الطلب'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------ Order Info ------------------
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'معلومات الطلب',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildInfoTile(
                                'Container Number', orderData!['containerNo']),
                            _buildInfoTile(
                                'Container Type', orderData!['containerType']),
                            _buildInfoTile(
                                'Gross Weight', orderData!['grossWeight']),
                            _buildInfoTile(
                                'Net Weight', orderData!['netWeight']),
                            _buildInfoTile(
                                'Number of Packages',
                                orderData!['numOfPackages']?.toString()),
                            _buildInfoTile(
                                'Cargo Description', orderData!['cargoDesc']),
                            _buildInfoTile(
                                'Special Marks', orderData!['specialMarks']),
                            _buildInfoTile(
                                'Bill of Lading', orderData!['blNo']),
                            _buildInfoTile(
                                'Vessel Voyage', orderData!['vesselVoyage']),
                            _buildInfoTile(
                                'Status', orderData!['status'] ?? 'Pending'),
                          ],
                        ),
                      ),

                      // ------------------ Consignee Info ------------------
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'بيانات المستلم',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildInfoTile('Name', orderData!['consigneeName']),
                            _buildInfoTile('Phone', orderData!['consigneePhone']),
                            _buildInfoTile('Address', orderData!['consigneeAddress']),
                          ],
                        ),
                      ),

                      // ------------------ Driver Info ------------------
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'بيانات السائق',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildInfoTile('Name', orderData!['driverName']),
                            _buildInfoTile('Phone', orderData!['driverPhone']),
                            ListTile(
                              title: const Text('Live Location'),
                              trailing: IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () {
                                  // افتح الخريطة لتتبع الموقع الحالي للسائق
                                  _editLocation('driverLocation');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ------------------ Locations ------------------
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'المواقع',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Pickup Location'),
                              subtitle: Text(orderData!['pickupLocation'] != null
                                  ? '${orderData!['pickupLocation']['latitude']}, ${orderData!['pickupLocation']['longitude']}'
                                  : '-'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_location),
                                onPressed: () {
                                  _editLocation('pickupLocation');
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Drop Location'),
                              subtitle: Text(orderData!['dropLocation'] != null
                                  ? '${orderData!['dropLocation']['latitude']}, ${orderData!['dropLocation']['longitude']}'
                                  : '-'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_location),
                                onPressed: () {
                                  _editLocation('dropLocation');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
