import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for managing Firestore operations across multiple collections.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------- USERS ----------------------

  /// Stream of all users.
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  /// Stream of all pending users.
  Stream<QuerySnapshot> getAllPendingUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Retrieve user by UID.
  Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user by ID $uid: $e');
      throw Exception('Failed to fetch user: $e');
    }
  }
// ---------------------- CHAT ----------------------
Stream<QuerySnapshot> getChatStream(String driverId) {
  return _firestore
      .collection('chats')
      .doc(driverId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
}

Future<void> sendMessage(String driverId, String message) async {
  try {
    await _firestore.collection('chats').doc(driverId)
      .collection('messages')
      .add({
        'sender': 'employee',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    print('Sent message to $driverId');
  } catch (e) {
    print('Error sending message: $e');
    throw Exception('Failed to send message: $e');
  }
}

  /// Update user by UID.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('Updated user $uid');
    } catch (e) {
      print('Error updating user $uid: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user by UID.
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('Deleted user $uid');
    } catch (e) {
      print('Error deleting user $uid: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Update user role.
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
      print('Updated role for user $uid to $role');
    } catch (e) {
      print('Error updating role for user $uid: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Activate user (approve account).
  Future<void> activateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': true,
        'status': 'approved',
      });
      print('User $uid has been activated');
    } catch (e) {
      print('Error activating user $uid: $e');
      throw Exception('Failed to activate user: $e');
    }
  }

  /// Reject user (set status to rejected).
  Future<void> rejectUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': false,
        'status': 'rejected',
      });
      print('User $uid has been rejected');
    } catch (e) {
      print('Error rejecting user $uid: $e');
      throw Exception('Failed to reject user: $e');
    }
  }

  // ---------------------- ORDERS ----------------------

  Stream<QuerySnapshot> getOrdersForCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots();
  }

  Stream<QuerySnapshot> getOrdersForDriver(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllOrders() {
    return _firestore.collection('orders').snapshots();
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      final orderId = orderData['orderId'] as String;
      await _firestore.collection('orders').doc(orderId).set(orderData);
      print('Created order $orderId');
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('orders').doc(orderId).update(updatedData);
      print('Updated order $orderId');
    } catch (e) {
      print('Error updating order $orderId: $e');
      throw Exception('Failed to update order: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching order by ID $orderId: $e');
      throw Exception('Failed to fetch order: $e');
    }
  }

  // ---------------------- INVOICES ----------------------

  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final invoiceId = invoiceData['invoiceId'] as String;
      await _firestore.collection('invoices').doc(invoiceId).set({
        ...invoiceData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created invoice $invoiceId');
    } catch (e) {
      print('Error creating invoice: $e');
      throw Exception('Failed to create invoice: $e');
    }
  }

  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching invoice $invoiceId: $e');
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update(data);
      print('Updated invoice $invoiceId');
    } catch (e) {
      print('Error updating invoice $invoiceId: $e');
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).delete();
      print('Deleted invoice $invoiceId');
    } catch (e) {
      print('Error deleting invoice $invoiceId: $e');
      throw Exception('Failed to delete invoice: $e');
    }
  }

  // ---------------------- NOTIFICATIONS ----------------------

  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    try {
      final notificationId = notificationData['notificationId'] as String;
      await _firestore.collection('notifications').doc(notificationId).set({
        ...notificationData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created notification $notificationId');
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  Stream<QuerySnapshot> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
      print('Marked notification $notificationId as read');
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('Deleted notification $notificationId');
    } catch (e) {
      print('Error deleting notification $notificationId: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // ---------------------- DRIVERS ----------------------

  Future<void> saveDriverLocation(
      String driverId, double latitude, double longitude) async {
    try {
      await _firestore.collection('driver_locations').doc(driverId).set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Saved location for driver $driverId');
    } catch (e) {
      print('Error saving driver location: $e');
      throw Exception('Failed to save driver location: $e');
    }
  }

  Stream<DocumentSnapshot> getDriverLocation(String driverId) {
    return _firestore.collection('driver_locations').doc(driverId).snapshots();
  }

  Stream<QuerySnapshot> getAllDrivers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots();
  }

  // ---------------------- UTILITIES ----------------------

  /// Validates a container number using ISO 6346 check digit algorithm.
  static bool validateContainerNumber(String value) {
    if (value.length != 11) return false;
    for (int i = 0; i < 4; i++) {
      if (!RegExp(r'[A-Z]').hasMatch(value[i])) return false;
    }
    for (int i = 4; i < 10; i++) {
      if (!RegExp(r'[0-9]').hasMatch(value[i])) return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(value[10])) return false;

    int sum = 0;
    for (int i = 0; i < 10; i++) {
      int val;
      if (i < 4) {
        val = value.codeUnitAt(i) - 'A'.codeUnitAt(0) + 10;
      } else {
        val = int.parse(value[i]);
      }
      sum += val * (1 << (9 - i));
    }
    int check = sum % 11;
    if (check == 10) check = 0;
    return check == int.parse(value[10]);
  }
}
