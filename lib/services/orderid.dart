import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoicePage extends StatefulWidget {
  final String orderId;
  final double transportationCost;

  const InvoicePage({super.key, required this.orderId, required this.transportationCost});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _invoiceId = '';
  final String _invoiceStatus = 'unpaid';

  @override
  void initState() {
    super.initState();
    _generateInvoice();
  }

  Future<void> _generateInvoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final order = await _firestore.collection('orders').doc(widget.orderId).get();
      if (!order.exists) {
        throw Exception('Order not found');
      }

      final customerId = order.data()?['customerId'] as String?;

      if (customerId == null) {
        throw Exception('Customer ID not found in the order');
      }

      final invoiceId = 'inv_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';

      final invoiceData = {
        'invoiceId': invoiceId,
        'customerId': customerId,
        'orderId': widget.orderId,
        'transportationCost': widget.transportationCost,
        'status': _invoiceStatus,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('invoices').doc(invoiceId).set(invoiceData);

      setState(() {
        _invoiceId = invoiceId;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to generate invoice: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: ${widget.orderId}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transportation Cost: \$${widget.transportationCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _invoiceId.isEmpty
                      ? const Text('Generating Invoice...')
                      : Text(
                          'Invoice ID: $_invoiceId\nStatus: $_invoiceStatus',
                          style: const TextStyle(fontSize: 16),
                        ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Orders'),
                  ),
                ],
              ),
            ),
    );
  }
}
