import 'package:flutter/material.dart';
import 'package:cargo_flow/services/firestore_verification.dart';

/// Utility class to run Firestore verification tests
class FirestoreTestRunner {
  static Future<void> runVerificationTests(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Running Firestore Tests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while we verify Firestore operations...'),
            ],
          ),
        );
      },
    );

    try {
      final verificationService = FirestoreVerificationService();
      final results = await verificationService.verifySignupDataStorage();

      // Close loading dialog
      Navigator.of(context).pop();

      // Generate and show report
      final report = verificationService.generateVerificationReport(results);

      // Show results dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Firestore Verification Results'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Verification Failed'),
            content: Text('Error running Firestore tests: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Quick verification method for testing individual components
  static Future<bool> quickVerification() async {
    try {
      final verificationService = FirestoreVerificationService();
      final results = await verificationService.verifySignupDataStorage();

      // Check if all tests passed
      final customerPassed = results['customerTest']?['success'] == true;
      final driverPassed = results['driverTest']?['success'] == true;
      final employeePassed = results['employeeTest']?['success'] == true;
      final notificationsPassed = results['adminNotificationsTest']?['success'] == true;
      final activationPassed = results['userActivationTest']?['success'] == true;
      final retrievalPassed = results['dataRetrievalTest']?['success'] == true;

      return customerPassed && driverPassed && employeePassed &&
             notificationsPassed && activationPassed && retrievalPassed;
    } catch (e) {
      print('Quick verification failed: $e');
      return false;
    }
  }
}
