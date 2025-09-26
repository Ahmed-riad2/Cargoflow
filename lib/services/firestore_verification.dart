// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service class for verifying Firestore operations and data integrity.
class FirestoreVerificationService {
  static final FirestoreVerificationService _instance =
      FirestoreVerificationService._internal();
  factory FirestoreVerificationService() => _instance;
  FirestoreVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifies the complete signup data storage for all roles
  Future<Map<String, dynamic>> verifySignupDataStorage() async {
    final results = <String, dynamic>{};

    try {
      // Test Customer data storage
      results['customerTest'] = await _testCustomerDataStorage();

      // Test Driver data storage
      results['driverTest'] = await _testDriverDataStorage();

      // Test Employee data storage
      results['employeeTest'] = await _testEmployeeDataStorage();

      // Test Admin notifications
      results['adminNotificationsTest'] = await _testAdminNotifications();

      // Test User activation
      results['userActivationTest'] = await _testUserActivation();

      // Test Data retrieval
      results['dataRetrievalTest'] = await _testDataRetrieval();

      return results;
    } catch (e) {
      results['error'] = 'Verification failed: $e';
      return results;
    }
  }

  /// Tests customer data storage with location data
  Future<Map<String, dynamic>> _testCustomerDataStorage() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test customer data
      final testData = {
        'name': 'Test Customer',
        'email': 'test.customer@example.com',
        'phone': '1234567890',
        'role': 'customer',
        'status': 'pending',
        'address': '123 Test Street, Test City, Test Country',
        'location': {
          'latitude': 40.7128,
          'longitude': -74.0060,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store test data
      final testDocRef = _firestore.collection('users').doc('test_customer_123');
      await testDocRef.set(testData);

      // Verify data was stored correctly
      final storedData = await testDocRef.get();
      final data = storedData.data();

      testResults['dataStored'] = data != null;
      testResults['nameCorrect'] = data?['name'] == 'Test Customer';
      testResults['emailCorrect'] = data?['email'] == 'test.customer@example.com';
      testResults['roleCorrect'] = data?['role'] == 'customer';
      testResults['statusCorrect'] = data?['status'] == 'pending';
      testResults['addressCorrect'] = data?['address'] == '123 Test Street, Test City, Test Country';
      testResults['locationCorrect'] = data?['location'] != null &&
          data?['location']['latitude'] == 40.7128 &&
          data?['location']['longitude'] == -74.0060;

      // Clean up test data
      await testDocRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'Customer test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Tests driver data storage with document paths
  Future<Map<String, dynamic>> _testDriverDataStorage() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test driver data
      final testData = {
        'name': 'Test Driver',
        'email': 'test.driver@example.com',
        'phone': '1234567890',
        'role': 'driver',
        'status': 'pending',
        'profileImagePath': '/path/to/profile.jpg',
        'vehicleLicensePath': '/path/to/vehicle_license.jpg',
        'driverLicensePath': '/path/to/driver_license.jpg',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store test data
      final testDocRef = _firestore.collection('users').doc('test_driver_123');
      await testDocRef.set(testData);

      // Verify data was stored correctly
      final storedData = await testDocRef.get();
      final data = storedData.data();

      testResults['dataStored'] = data != null;
      testResults['nameCorrect'] = data?['name'] == 'Test Driver';
      testResults['roleCorrect'] = data?['role'] == 'driver';
      testResults['profileImageCorrect'] = data?['profileImagePath'] == '/path/to/profile.jpg';
      testResults['vehicleLicenseCorrect'] = data?['vehicleLicensePath'] == '/path/to/vehicle_license.jpg';
      testResults['driverLicenseCorrect'] = data?['driverLicensePath'] == '/path/to/driver_license.jpg';

      // Clean up test data
      await testDocRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'Driver test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Tests employee data storage
  Future<Map<String, dynamic>> _testEmployeeDataStorage() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test employee data
      final testData = {
        'name': 'Test Employee',
        'email': 'test.employee@example.com',
        'phone': '1234567890',
        'role': 'employee',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store test data
      final testDocRef = _firestore.collection('users').doc('test_employee_123');
      await testDocRef.set(testData);

      // Verify data was stored correctly
      final storedData = await testDocRef.get();
      final data = storedData.data();

      testResults['dataStored'] = data != null;
      testResults['nameCorrect'] = data?['name'] == 'Test Employee';
      testResults['roleCorrect'] = data?['role'] == 'employee';
      testResults['noExtraFields'] = data?.length == 6; // uid, name, email, phone, role, status, createdAt

      // Clean up test data
      await testDocRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'Employee test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Tests admin notification creation
  Future<Map<String, dynamic>> _testAdminNotifications() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test notification
      final notificationRef = await _firestore.collection('admin_notifications').add({
        'message': 'Test notification for verification',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Verify notification was created
      final notification = await notificationRef.get();
      final data = notification.data();

      testResults['notificationCreated'] = notification.exists;
      testResults['messageCorrect'] = data?['message'] == 'Test notification for verification';
      testResults['statusCorrect'] = data?['status'] == 'pending';
      testResults['timestampExists'] = data?['createdAt'] != null;

      // Clean up test notification
      await notificationRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'Admin notification test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Tests user activation process
  Future<Map<String, dynamic>> _testUserActivation() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test user
      final testUserRef = _firestore.collection('users').doc('test_activation_123');
      await testUserRef.set({
        'name': 'Test Activation User',
        'email': 'test.activation@example.com',
        'role': 'customer',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Activate user
      await testUserRef.update({'status': 'active'});

      // Verify activation
      final updatedData = await testUserRef.get();
      final data = updatedData.data();

      testResults['activationSuccessful'] = data?['status'] == 'active';

      // Clean up test user
      await testUserRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'User activation test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Tests data retrieval functionality
  Future<Map<String, dynamic>> _testDataRetrieval() async {
    final testResults = <String, dynamic>{};

    try {
      // Create test user for retrieval
      final testUserRef = _firestore.collection('users').doc('test_retrieval_123');
      await testUserRef.set({
        'name': 'Test Retrieval User',
        'email': 'test.retrieval@example.com',
        'role': 'driver',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Test retrieval using FirestoreService methods
      final retrievedData = await testUserRef.get();
      final data = retrievedData.data();

      testResults['dataRetrieved'] = data != null;
      testResults['nameRetrieved'] = data?['name'] == 'Test Retrieval User';
      testResults['roleRetrieved'] = data?['role'] == 'driver';
      testResults['statusRetrieved'] = data?['status'] == 'active';

      // Clean up test user
      await testUserRef.delete();

      testResults['success'] = testResults.values.every((v) => v == true);
      return testResults;
    } catch (e) {
      testResults['error'] = 'Data retrieval test failed: $e';
      testResults['success'] = false;
      return testResults;
    }
  }

  /// Generates a comprehensive verification report
  String generateVerificationReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();

    buffer.writeln('🔍 FIRESTORE VERIFICATION REPORT');
    buffer.writeln('=' * 50);

    // Overall status
    final allTestsPassed = results.values.where((v) => v is Map && v['success'] == true).length == 6;
    buffer.writeln('Overall Status: ${allTestsPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}');
    buffer.writeln();

    // Customer Test Results
    buffer.writeln('👤 CUSTOMER DATA STORAGE TEST');
    buffer.writeln('-' * 30);
    final customerResults = results['customerTest'] as Map<String, dynamic>;
    buffer.writeln('Data Storage: ${customerResults['dataStored'] ? '✅' : '❌'}');
    buffer.writeln('Name Field: ${customerResults['nameCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Email Field: ${customerResults['emailCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Role Field: ${customerResults['roleCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Status Field: ${customerResults['statusCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Address Field: ${customerResults['addressCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Location Data: ${customerResults['locationCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${customerResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (customerResults['error'] != null) {
      buffer.writeln('Error: ${customerResults['error']}');
    }
    buffer.writeln();

    // Driver Test Results
    buffer.writeln('🚛 DRIVER DATA STORAGE TEST');
    buffer.writeln('-' * 30);
    final driverResults = results['driverTest'] as Map<String, dynamic>;
    buffer.writeln('Data Storage: ${driverResults['dataStored'] ? '✅' : '❌'}');
    buffer.writeln('Name Field: ${driverResults['nameCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Role Field: ${driverResults['roleCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Profile Image: ${driverResults['profileImageCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Vehicle License: ${driverResults['vehicleLicenseCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Driver License: ${driverResults['driverLicenseCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${driverResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (driverResults['error'] != null) {
      buffer.writeln('Error: ${driverResults['error']}');
    }
    buffer.writeln();

    // Employee Test Results
    buffer.writeln('👨‍💼 EMPLOYEE DATA STORAGE TEST');
    buffer.writeln('-' * 30);
    final employeeResults = results['employeeTest'] as Map<String, dynamic>;
    buffer.writeln('Data Storage: ${employeeResults['dataStored'] ? '✅' : '❌'}');
    buffer.writeln('Name Field: ${employeeResults['nameCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Role Field: ${employeeResults['roleCorrect'] ? '✅' : '❌'}');
    buffer.writeln('No Extra Fields: ${employeeResults['noExtraFields'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${employeeResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (employeeResults['error'] != null) {
      buffer.writeln('Error: ${employeeResults['error']}');
    }
    buffer.writeln();

    // Admin Notifications Test
    buffer.writeln('🔔 ADMIN NOTIFICATIONS TEST');
    buffer.writeln('-' * 30);
    final notificationResults = results['adminNotificationsTest'] as Map<String, dynamic>;
    buffer.writeln('Notification Created: ${notificationResults['notificationCreated'] ? '✅' : '❌'}');
    buffer.writeln('Message Correct: ${notificationResults['messageCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Status Correct: ${notificationResults['statusCorrect'] ? '✅' : '❌'}');
    buffer.writeln('Timestamp Exists: ${notificationResults['timestampExists'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${notificationResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (notificationResults['error'] != null) {
      buffer.writeln('Error: ${notificationResults['error']}');
    }
    buffer.writeln();

    // User Activation Test
    buffer.writeln('✅ USER ACTIVATION TEST');
    buffer.writeln('-' * 30);
    final activationResults = results['userActivationTest'] as Map<String, dynamic>;
    buffer.writeln('Activation Successful: ${activationResults['activationSuccessful'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${activationResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (activationResults['error'] != null) {
      buffer.writeln('Error: ${activationResults['error']}');
    }
    buffer.writeln();

    // Data Retrieval Test
    buffer.writeln('📊 DATA RETRIEVAL TEST');
    buffer.writeln('-' * 30);
    final retrievalResults = results['dataRetrievalTest'] as Map<String, dynamic>;
    buffer.writeln('Data Retrieved: ${retrievalResults['dataRetrieved'] ? '✅' : '❌'}');
    buffer.writeln('Name Retrieved: ${retrievalResults['nameRetrieved'] ? '✅' : '❌'}');
    buffer.writeln('Role Retrieved: ${retrievalResults['roleRetrieved'] ? '✅' : '❌'}');
    buffer.writeln('Status Retrieved: ${retrievalResults['statusRetrieved'] ? '✅' : '❌'}');
    buffer.writeln('Result: ${retrievalResults['success'] ? '✅ PASSED' : '❌ FAILED'}');
    if (retrievalResults['error'] != null) {
      buffer.writeln('Error: ${retrievalResults['error']}');
    }

    buffer.writeln();
    buffer.writeln('=' * 50);
    buffer.writeln('VERIFICATION COMPLETED: ${DateTime.now().toString()}');

    return buffer.toString();
  }
}
