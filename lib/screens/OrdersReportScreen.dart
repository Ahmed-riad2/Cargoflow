import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo_flow/services/firestore_service.dart';

class OrdersReportScreen extends StatefulWidget {
  const OrdersReportScreen({super.key});

  @override
  State<OrdersReportScreen> createState() => _OrdersReportScreenState();
}

class _OrdersReportScreenState extends State<OrdersReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Report'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text('Order ID: ${order['orderId']}'),
                  subtitle: Text('Status: ${order['status']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
