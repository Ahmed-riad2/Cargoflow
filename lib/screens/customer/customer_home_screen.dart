import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:cargo_flow/services/firestore_service.dart';
import 'package:cargo_flow/screens/auth/login_screen.dart';
import 'package:cargo_flow/screens/customer/profile_screen.dart';
import 'package:cargo_flow/screens/customer/chat_screen.dart';
import 'package:cargo_flow/widgets/custom_map_widget.dart';
import 'package:cargo_flow/screens/customer/Customer_order.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  int _selectedTabIndex = 0; // 0: Orders List, 1: Create Order

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _containerNumberController = TextEditingController();
  String? _selectedContainerType;
  final _grossWeightController = TextEditingController();
  final _tareWeightController = TextEditingController();
  String? _selectedStatus;
  final _specialMarksController = TextEditingController();
  final _cargoDescriptionController = TextEditingController();
  final _numberOfPackagesController = TextEditingController();
  final _netWeightController = TextEditingController();
  final _billOfLadingController = TextEditingController();
  final _vesselVoyageController = TextEditingController();
  final _consigneeNameController = TextEditingController();
  final _consigneePhoneController = TextEditingController();
  final _consigneeAddressController = TextEditingController();
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  final _fileLinksController = TextEditingController();

  final List<String> _containerTypes = [
    '20ft Standard',
    '40ft Standard',
    '20ft High Cube',
    '40ft High Cube',
    '20ft Refrigerated',
    '40ft Refrigerated',
  ];

  final List<String> _statuses = ['Empty', 'Full'];

  @override
  void dispose() {
    _containerNumberController.dispose();
    _grossWeightController.dispose();
    _tareWeightController.dispose();
    _specialMarksController.dispose();
    _cargoDescriptionController.dispose();
    _numberOfPackagesController.dispose();
    _netWeightController.dispose();
    _billOfLadingController.dispose();
    _vesselVoyageController.dispose();
    _consigneeNameController.dispose();
    _consigneePhoneController.dispose();
    _consigneeAddressController.dispose();
    _fileLinksController.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ------------------- FORM HELPERS -------------------

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: inputType,
      ),
    );
  }

  Widget _buildDropDown(
    String label,
    List<String> items,
    String? selectedValue,
    void Function(String?)? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        hint: Text("Select $label"),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLocationRow(String label, LatLng? location, bool isPickup) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              location == null
                  ? '$label: Not selected'
                  : '$label: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            ),
          ),
          ElevatedButton(
            onPressed: () => _showMapDialog(isPickup),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showMapDialog(bool isPickup) async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomMapWidget(isPicker: true)),
    );
    if (selectedLocation != null) {
      setState(() {
        if (isPickup) {
          _pickupLocation = selectedLocation;
        } else {
          _dropLocation = selectedLocation;
        }
      });
    }
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupLocation == null || _dropLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop locations'),
        ),
      );
      return;
    }

    final orderData = {
      'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
      'customerId': currentUser!.uid,
      'containerNumber': _containerNumberController.text,
      'containerType': _selectedContainerType,
      'grossWeight': double.tryParse(_grossWeightController.text) ?? 0,
      'tareWeight': double.tryParse(_tareWeightController.text) ?? 0,
      'status': 'Pending',
      'containerStatus': _selectedStatus,
      'specialMarks': _specialMarksController.text,
      'cargoDescription': _cargoDescriptionController.text,
      'numberOfPackages': int.tryParse(_numberOfPackagesController.text) ?? 0,
      'netWeight': double.tryParse(_netWeightController.text) ?? 0,
      'billOfLadingNumber': _billOfLadingController.text,
      'vesselVoyageNumber': _vesselVoyageController.text,
      'consigneeName': _consigneeNameController.text,
      'consigneePhone': _consigneePhoneController.text,
      'consigneeAddress': _consigneeAddressController.text,
      'pickupLat': _pickupLocation!.latitude,
      'pickupLng': _pickupLocation!.longitude,
      'dropLat': _dropLocation!.latitude,
      'dropLng': _dropLocation!.longitude,
      'fileLinks': _fileLinksController.text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestoreService.createOrder(orderData);
      _clearForm();
      setState(() {
        _selectedTabIndex = 0; // ارجع للقائمة بعد الإضافة
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create order: $e')));
    }
  }

  void _clearForm() {
    _containerNumberController.clear();
    _selectedContainerType = null;
    _grossWeightController.clear();
    _tareWeightController.clear();
    _selectedStatus = null;
    _specialMarksController.clear();
    _cargoDescriptionController.clear();
    _numberOfPackagesController.clear();
    _netWeightController.clear();
    _billOfLadingController.clear();
    _vesselVoyageController.clear();
    _consigneeNameController.clear();
    _consigneePhoneController.clear();
    _consigneeAddressController.clear();
    _pickupLocation = null;
    _dropLocation = null;
    _fileLinksController.clear();
  }

  // ------------------- UI -------------------

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              final chatId = 'chat_${currentUser!.uid}';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(chatId: chatId, userId: currentUser!.uid),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: currentUser!.uid),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _logout),
        ],
      ),
      body: _selectedTabIndex == 0 ? _ordersListView() : _createOrderView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create Order'),
        ],
      ),
    );
  }

  Widget _ordersListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getOrdersForCustomer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final isPending = order['status'] == 'Pending';
            return Card(
              color: isPending ? Colors.orange[50] : Colors.white,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text('Container: ${order['containerNumber']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${order['status']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.orange : Colors.black,
                      ),
                    ),
                    Text(
                      'Pickup: ${order['pickupLat']?.toStringAsFixed(4) ?? 'N/A'}, ${order['pickupLng']?.toStringAsFixed(4) ?? 'N/A'}',
                    ),
                    Text(
                      'Drop: ${order['dropLat']?.toStringAsFixed(4) ?? 'N/A'}, ${order['dropLng']?.toStringAsFixed(4) ?? 'N/A'}',
                    ),
                  ],
                ),
                onTap: () {
                  // هنا ممكن تفتح تفاصيل الأوردر + Live Tracking للـ Driver
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _createOrderView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Container Info", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField('Container Number', _containerNumberController),
            _buildDropDown(
              'Container Type',
              _containerTypes,
              _selectedContainerType,
              (val) => setState(() => _selectedContainerType = val),
            ),
            const Divider(),

            const Text("Cargo Info", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField(
              'Gross Weight (kg)',
              _grossWeightController,
              inputType: TextInputType.number,
            ),
            _buildTextField(
              'Tare Weight (kg)',
              _tareWeightController,
              inputType: TextInputType.number,
            ),
            _buildDropDown(
              'Status',
              _statuses,
              _selectedStatus,
              (val) => setState(() => _selectedStatus = val),
            ),
            _buildTextField('Special Marks', _specialMarksController),
            _buildTextField('Cargo Description', _cargoDescriptionController),
            _buildTextField(
              'Number of Packages',
              _numberOfPackagesController,
              inputType: TextInputType.number,
            ),
            _buildTextField(
              'Net Weight (kg)',
              _netWeightController,
              inputType: TextInputType.number,
            ),
            _buildTextField('Bill of Lading Number', _billOfLadingController),
            _buildTextField('Vessel Voyage Number', _vesselVoyageController),
            const Divider(),

            const Text("Consignee Info", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField('Consignee Name', _consigneeNameController),
            _buildTextField('Consignee Phone', _consigneePhoneController),
            _buildTextField('Consignee Address', _consigneeAddressController),
            const Divider(),

            const Text("Locations", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildLocationRow('Pickup Location', _pickupLocation, true),
            _buildLocationRow('Drop Location', _dropLocation, false),
            const Divider(),

            _buildTextField('File Upload Links (Google Drive)', _fileLinksController),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Submit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
