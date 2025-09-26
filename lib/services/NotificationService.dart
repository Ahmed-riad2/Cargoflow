import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initializes the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else {
        print('❌ User declined or has not granted notification permission');
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      throw Exception('Failed to initialize notifications: $e');
    }
  }

  /// Handles background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('🔥 [BACKGROUND] Handling background message: ${message.messageId}');
    print('🔥 [BACKGROUND] Title: ${message.notification?.title}');
    print('🔥 [BACKGROUND] Body: ${message.notification?.body}');
    print('🔥 [BACKGROUND] Data: ${message.data}');
  }

  /// Handles foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 [FOREGROUND] Received foreground message: ${message.messageId}');
    print('📱 [FOREGROUND] Title: ${message.notification?.title}');
    print('📱 [FOREGROUND] Body: ${message.notification?.body}');
    print('📱 [FOREGROUND] Data: ${message.data}');

    // Show local notification or handle in-app notification
    _showInAppNotification(message);
  }

  /// Shows in-app notification
  void _showInAppNotification(RemoteMessage message) {
    // This would typically integrate with a notification provider
    // For now, we'll just log it
    print('🔔 [IN-APP] Would show in-app notification: ${message.notification?.title}');
  }

  /// Handles when app is opened from notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('🚀 [OPENED] Message opened app: ${message.messageId}');
    print('🚀 [OPENED] Data: ${message.data}');
    // Navigate to appropriate screen based on message data
    _navigateBasedOnMessage(message.data);
  }

  /// Navigates based on message data
  void _navigateBasedOnMessage(Map<String, dynamic> data) {
    print('🧭 [NAVIGATION] Navigating based on message data: $data');

    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'new_order':
          print('🆕 Navigate to new orders screen');
          break;
        case 'driver_assigned':
          print('🚛 Navigate to driver assignment screen');
          break;
        default:
          print('❓ Unknown notification type: ${data['type']}');
      }
    }
  }

  /// Sends new order notification to employees
  Future<void> sendNewOrderNotification({
    required String orderId,
    required String containerNumber,
  }) async {
    try {
      final employeesSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();

      for (final employeeDoc in employeesSnapshot.docs) {
        final employeeId = employeeDoc.id;
        await _createNotificationDocument(
          userId: employeeId,
          title: '📦 New Order Received',
          body: 'New order #$orderId - Container: $containerNumber requires processing.',
          type: 'new_order',
          data: {
            'type': 'new_order',
            'orderId': orderId,
            'containerNumber': containerNumber,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      print('✅ [NOTIFICATION] New order notification sent to employee');
    } catch (e) {
      print('❌ [NOTIFICATION] Error sending new order notification: $e');
    }
  }

  /// Sends driver assignment notification
  Future<void> sendDriverAssignmentNotification({
    required String driverId,
    required String orderId,
  }) async {
    try {
      await _createNotificationDocument(
        userId: driverId,
        title: '🚚 New Delivery Assignment',
        body: 'You have been assigned to deliver order #$orderId.',
        type: 'driver_assigned',
        data: {
          'type': 'driver_assigned',
          'orderId': orderId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ [NOTIFICATION] Driver assignment notification sent');
    } catch (e) {
      print('❌ [NOTIFICATION] Error sending driver assignment notification: $e');
    }
  }

  /// Creates notification document in Firestore
  Future<void> _createNotificationDocument({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_$userId';

      await _firestore.collection('notifications').doc(notificationId).set({
        'notificationId': notificationId,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('💾 [DATABASE] Notification document created: $notificationId');
    } catch (e) {
      print('❌ [DATABASE] Error creating notification document: $e');
    }
  }
}
